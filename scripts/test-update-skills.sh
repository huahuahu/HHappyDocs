#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
UPDATE_SCRIPT="$REPO_ROOT/scripts/update-skills.sh"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
OUTSIDE_DIR="$TMP_DIR/outside"
NPX_LOG="$TMP_DIR/npx.log"
GIT_LOG="$TMP_DIR/git.log"
REAL_GIT="$(command -v git)"
export REAL_GIT

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$FAKE_BIN" "$OUTSIDE_DIR"

cat > "$FAKE_BIN/npx" <<'FAKE_NPX'
#!/usr/bin/env bash
set -uo pipefail

: "${NPX_LOG:?NPX_LOG is required}"

{
    printf 'cwd=%s\n' "$PWD"
    printf 'argc=%s\n' "$#"
    printf 'AI_AGENT=%s\n' "${AI_AGENT:-<unset>}"

    index=1
    for argument in "$@"; do
        printf 'arg_%s=%s\n' "$index" "$argument"
        index=$((index + 1))
    done

    for variable in HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy; do
        if value="$(printenv "$variable" 2>/dev/null)"; then
            printf '%s=%s\n' "$variable" "$value"
        else
            printf '%s=<unset>\n' "$variable"
        fi
    done
} > "$NPX_LOG"

exit "${NPX_EXIT_CODE:-0}"
FAKE_NPX
chmod +x "$FAKE_BIN/npx"

cat > "$FAKE_BIN/git" <<'FAKE_GIT'
#!/usr/bin/env bash
set -euo pipefail

: "${REAL_GIT:?REAL_GIT is required}"

if [[ -n "${GIT_LOG:-}" ]]; then
    {
        printf 'argc=%s\n' "$#"

        index=1
        for argument in "$@"; do
            printf 'arg_%s=%s\n' "$index" "$argument"
            index=$((index + 1))
        done
    } > "$GIT_LOG"
fi

exec "$REAL_GIT" "$@"
FAKE_GIT
chmod +x "$FAKE_BIN/git"

assert_file_line() {
    file="$1"
    expected="$2"

    if ! grep -Fqx -- "$expected" "$file"; then
        printf '缺少日志行：%s\n' "$expected" >&2
        printf '%s\n' "--- $file ---" >&2
        sed -n '1,120p' "$file" >&2
        return 1
    fi
}

assert_log_line() {
    assert_file_line "$NPX_LOG" "$1"
}

test_repo_root_is_resolved_with_git() {
    : > "$NPX_LOG"
    : > "$GIT_LOG"

    (
        cd "$OUTSIDE_DIR" || exit 1
        PATH="$FAKE_BIN:$PATH" NPX_LOG="$NPX_LOG" GIT_LOG="$GIT_LOG" "$UPDATE_SCRIPT"
    ) || return 1

    assert_file_line "$GIT_LOG" 'argc=4' || return 1
    assert_file_line "$GIT_LOG" 'arg_1=-C' || return 1
    assert_file_line "$GIT_LOG" "arg_2=$REPO_ROOT/scripts" || return 1
    assert_file_line "$GIT_LOG" 'arg_3=rev-parse' || return 1
    assert_file_line "$GIT_LOG" 'arg_4=--show-toplevel' || return 1
}

test_direct_invocation_uses_repo_root_and_all_project_arguments() {
    : > "$NPX_LOG"

    (
        cd "$OUTSIDE_DIR" || exit 1
        PATH="$FAKE_BIN:$PATH" NPX_LOG="$NPX_LOG" "$UPDATE_SCRIPT"
    ) || return 1

    assert_log_line "cwd=$REPO_ROOT" || return 1
    assert_log_line 'argc=5' || return 1
    assert_log_line 'arg_1=--yes' || return 1
    assert_log_line 'arg_2=skills' || return 1
    assert_log_line 'arg_3=update' || return 1
    assert_log_line 'arg_4=--project' || return 1
    assert_log_line 'arg_5=--yes' || return 1
}

test_update_targets_github_copilot() {
    : > "$NPX_LOG"

    (
        cd "$OUTSIDE_DIR" || exit 1
        PATH="$FAKE_BIN:$PATH" NPX_LOG="$NPX_LOG" AI_AGENT=claude-code "$UPDATE_SCRIPT"
    ) || return 1

    assert_log_line 'AI_AGENT=github-copilot'
}

test_proxy_environment_is_inherited_unchanged() {
    : > "$NPX_LOG"

    (
        cd "$OUTSIDE_DIR" || exit 1
        export PATH="$FAKE_BIN:$PATH"
        export NPX_LOG
        export HTTP_PROXY='http://caller.example:1101'
        export HTTPS_PROXY='http://caller.example:1102'
        export ALL_PROXY='socks5://caller.example:1103'
        export http_proxy='http://caller.example:1201'
        export https_proxy='http://caller.example:1202'
        export all_proxy='socks5://caller.example:1203'
        export NO_PROXY='caller.internal'
        export no_proxy='caller.local'
        "$UPDATE_SCRIPT"
    ) || return 1

    assert_log_line 'HTTP_PROXY=http://caller.example:1101' || return 1
    assert_log_line 'HTTPS_PROXY=http://caller.example:1102' || return 1
    assert_log_line 'ALL_PROXY=socks5://caller.example:1103' || return 1
    assert_log_line 'http_proxy=http://caller.example:1201' || return 1
    assert_log_line 'https_proxy=http://caller.example:1202' || return 1
    assert_log_line 'all_proxy=socks5://caller.example:1203' || return 1
    assert_log_line 'NO_PROXY=caller.internal' || return 1
    assert_log_line 'no_proxy=caller.local' || return 1
}

test_unset_proxy_environment_stays_unset() {
    : > "$NPX_LOG"

    (
        cd "$OUTSIDE_DIR" || exit 1
        unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy
        PATH="$FAKE_BIN:$PATH" NPX_LOG="$NPX_LOG" "$UPDATE_SCRIPT"
    ) || return 1

    for variable in HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy; do
        assert_log_line "$variable=<unset>" || return 1
    done
}

test_npx_failure_status_is_preserved() {
    : > "$NPX_LOG"

    (
        cd "$OUTSIDE_DIR" || exit 1
        PATH="$FAKE_BIN:$PATH" NPX_LOG="$NPX_LOG" NPX_EXIT_CODE=23 "$UPDATE_SCRIPT"
    )
    status=$?

    if [[ "$status" -ne 23 ]]; then
        printf '期望退出状态 23，实际为 %s\n' "$status" >&2
        return 1
    fi
}

test_make_target_delegates_to_update_script() {
    : > "$NPX_LOG"

    PATH="$FAKE_BIN:$PATH" NPX_LOG="$NPX_LOG" \
        make --no-print-directory -s -C "$REPO_ROOT" skills-update || return 1

    assert_log_line "cwd=$REPO_ROOT" || return 1
    assert_log_line 'argc=5' || return 1
    assert_log_line 'arg_1=--yes' || return 1
    assert_log_line 'arg_2=skills' || return 1
    assert_log_line 'arg_3=update' || return 1
    assert_log_line 'arg_4=--project' || return 1
    assert_log_line 'arg_5=--yes' || return 1
}

failures=0

run_test() {
    name="$1"
    shift

    if "$@"; then
        printf 'PASS: %s\n' "$name"
    else
        printf 'FAIL: %s\n' "$name" >&2
        failures=$((failures + 1))
    fi
}

run_test '使用 Git 解析 repository 根目录' \
    test_repo_root_is_resolved_with_git
run_test '直接调用使用仓库根目录与全部 project 参数' \
    test_direct_invocation_uses_repo_root_and_all_project_arguments
run_test '更新目标固定为 GitHub Copilot' \
    test_update_targets_github_copilot
run_test '代理环境保持调用者提供的值' \
    test_proxy_environment_is_inherited_unchanged
run_test '未设置的代理环境保持未设置' \
    test_unset_proxy_environment_stays_unset
run_test 'npx 失败状态被保留' \
    test_npx_failure_status_is_preserved
run_test 'Makefile target 转发到升级脚本' \
    test_make_target_delegates_to_update_script

if [[ "$failures" -ne 0 ]]; then
    printf '%s 个测试失败\n' "$failures" >&2
    exit 1
fi

printf '全部 7 个测试通过\n'

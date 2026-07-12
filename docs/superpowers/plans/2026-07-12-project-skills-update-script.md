# 项目 Skills 升级脚本实施计划

> **供代理执行者使用：** REQUIRED SUB-SKILL：使用 `subagent-driven-development`（推荐）或 `executing-plans`，逐项执行本计划。所有步骤使用 checkbox（`- [ ]`）跟踪。

**目标：** 新增一个仅升级当前仓库全部 project skills 的 Bash 脚本，并通过 `make skills-update` 提供入口。

**架构：** `scripts/update-skills.sh` 根据自身位置调用 Git 解析当前 worktree 的 repository 根目录，再将控制权交给 `npx skills update`；根目录 `makefile` 只负责转发调用。`scripts/test-update-skills.sh` 通过临时 `PATH` 注入假的 `git` 与 `npx`，在不访问网络、不修改已安装 skills 的前提下验证边界行为。

**技术栈：** macOS Bash、Git、Make、`npx skills`。

## 全局约束

- 脚本固定执行 `npx --yes skills update --project --yes`，不接受单个 skill 名称。
- repository 根目录必须由 `git -C <脚本目录> rev-parse --show-toplevel` 解析。
- 脚本只继承调用者环境，不设置、删除或覆盖任何代理变量。
- 自动化验证不得访问网络，也不得真实升级 `.agents/skills/` 或 `skills-lock.json`。
- 测试初始化必须 fail closed，fake 命令未成功创建时不得回退到真实 `npx`。
- 不新增 Bats、Node package 或其他测试依赖。

---

### Task 1：实现升级脚本、Makefile 入口与无网络测试

**Files:**
- Create: `scripts/test-update-skills.sh`
- Create: `scripts/update-skills.sh`
- Modify: `makefile`

**Interfaces:**
- Consumes: 当前 Git worktree、仓库根目录的 `skills-lock.json`、调用者环境、可从 `PATH` 找到的 `git` 与 `npx`。
- Produces: 可直接执行的 `scripts/update-skills.sh`，以及可运行的 Make target `skills-update`。

- [x] **Step 1：先写失败测试**

创建 `scripts/test-update-skills.sh`：

```bash
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

printf '全部 6 个测试通过\n'
```

- [x] **Step 2：运行测试并确认 RED**

Run:

```bash
bash scripts/test-update-skills.sh
```

Expected: 命令退出 `1`；测试因 `scripts/update-skills.sh` 尚不存在、`makefile` 尚无 `skills-update` target，或尚未使用 Git 解析根目录而失败。测试初始化失败时也必须立即以非零状态退出。

- [x] **Step 3：写最小实现**

创建 `scripts/update-skills.sh`：

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

cd "$REPO_ROOT"
exec npx --yes skills update --project --yes
```

将以下内容追加到根目录 `makefile`：

```makefile
.PHONY: skills-update
skills-update:
	./scripts/update-skills.sh
```

赋予两个脚本可执行权限：

```bash
chmod +x scripts/update-skills.sh scripts/test-update-skills.sh
```

- [x] **Step 4：运行测试并确认 GREEN**

Run:

```bash
bash scripts/test-update-skills.sh
```

Expected:

```text
PASS: 使用 Git 解析 repository 根目录
PASS: 直接调用使用仓库根目录与全部 project 参数
PASS: 代理环境保持调用者提供的值
PASS: 未设置的代理环境保持未设置
PASS: npx 失败状态被保留
PASS: Makefile target 转发到升级脚本
全部 6 个测试通过
```

- [x] **Step 5：执行静态与差异验证**

Run:

```bash
bash -n scripts/update-skills.sh scripts/test-update-skills.sh
bash scripts/test-update-skills.sh
make --no-print-directory -n skills-update
git diff --check HEAD
git status --short
```

Expected: Bash 语法和六项测试均退出 `0`；Make dry-run 仅打印 `./scripts/update-skills.sh`；`git diff --check HEAD` 无输出；状态仅包含本任务的脚本、`makefile` 与计划文档变更。不要执行真实 `make skills-update`，避免验证过程修改项目已安装的 skills。

- [x] **Step 6：提交实现**

```bash
git add scripts/update-skills.sh scripts/test-update-skills.sh makefile docs/superpowers/plans/2026-07-12-project-skills-update-script.md
git commit -m "chore: add project skills update script"
```

#!/bin/bash

# Additional arguments support test plans, focused tests, and result bundles.
function testScheme() (
    set -euo pipefail
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        helper_path="${(%):-%x}"
    else
        helper_path="${BASH_SOURCE[0]}"
    fi
    repo_root="$(cd "$(dirname "$helper_path")/.." && pwd)"
    scheme="${1:-HDiary}"
    if (( $# > 0 )); then shift; fi
    "$repo_root/scripts/generate-project.sh"
    xcodebuild clean test -project "$repo_root/HDiary.xcodeproj" \
        -scheme "$scheme" -configuration "${CONFIGURATION:-Debug}" \
        -destination "${HDIARY_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}" \
        -onlyUsePackageVersionsFromResolvedFile CODE_SIGN_IDENTITY="-" "$@"
)

if [[ -n "${ZSH_VERSION:-}" ]]; then
    if [[ "$ZSH_EVAL_CONTEXT" == toplevel ]]; then testScheme "$@"; fi
elif [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    testScheme "$@"
fi

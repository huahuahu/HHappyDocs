#!/bin/bash

# Keep the sourced buildScheme API as well as supporting direct execution.
function buildScheme() (
    set -euo pipefail
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        helper_path="${(%):-%x}"
    else
        helper_path="${BASH_SOURCE[0]}"
    fi
    repo_root="$(cd "$(dirname "$helper_path")/.." && pwd)"
    "$repo_root/scripts/generate-project.sh"
    destinations=(-destination "${HDIARY_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}")
    if [[ "${2:-}" != "--only-ios" ]]; then
        destinations+=(-destination 'platform=macOS,arch=x86_64')
    fi
    xcodebuild -project "$repo_root/HDiary.xcodeproj" \
        -scheme "${1:-HDiary}" -configuration "${CONFIGURATION:-Debug}" \
        "${destinations[@]}" -onlyUsePackageVersionsFromResolvedFile \
        CODE_SIGN_IDENTITY="-" build
)

if [[ -n "${ZSH_VERSION:-}" ]]; then
    if [[ "$ZSH_EVAL_CONTEXT" == toplevel ]]; then buildScheme "$@"; fi
elif [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    buildScheme "$@"
fi

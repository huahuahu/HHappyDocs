#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required_version="$(cat "$repo_root/.xcodegen-version")"
actual_version="$(xcodegen version | awk '{print $NF}')"
if [[ "$actual_version" != "$required_version" ]]; then
    echo "XcodeGen $required_version is required (found $actual_version). Run scripts/install-xcodegen.sh." >&2
    exit 1
fi

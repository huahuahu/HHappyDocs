#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$repo_root/.tools/xcodegen/bin:$PATH"
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGen is missing. Run scripts/install-xcodegen.sh first." >&2
    exit 1
fi
cd "$repo_root"
./scripts/check-xcodegen-version.sh
xcodegen generate --spec project.yml

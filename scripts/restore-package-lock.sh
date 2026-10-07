#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lock_directory="$repo_root/HDiary.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
mkdir -p "$lock_directory"
cp "$repo_root/Package.resolved" "$lock_directory/Package.resolved"

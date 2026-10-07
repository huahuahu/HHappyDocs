#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(cat "$repo_root/.xcodegen-version")"
destination="$repo_root/.tools/xcodegen"
if [[ -x "$destination/bin/xcodegen" ]] && \
    [[ "$("$destination/bin/xcodegen" version)" == "Version: $version" ]]; then
    echo "XcodeGen $version is already installed in $destination"
    exit 0
fi

download_directory="$(mktemp -d)"
trap 'rm -rf "$download_directory"' EXIT
curl --fail --silent --show-error --location --retry 3 --connect-timeout 15 --max-time 600 \
    "https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip" \
    --output "$download_directory/xcodegen.zip"
# SHA-256 published for the 2.46.0 release asset. Update with .xcodegen-version.
echo "4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806  $download_directory/xcodegen.zip" | shasum -a 256 -c -
unzip -q "$download_directory/xcodegen.zip" -d "$download_directory"
mkdir -p "$destination"
cp -R "$download_directory/xcodegen/." "$destination/"
"$destination/bin/xcodegen" version

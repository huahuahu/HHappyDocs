#!/bin/bash

# HDoc TestFlight Build and Upload Script
# This script builds, archives, and uploads the HDoc app to App Store Connect with Distribution certificate

set -e

PROJECT_PATH="MonoRepos/HDoc/HDoc.xcodeproj"
SCHEME="HDoc"
CONFIGURATION="Release"
ARCHIVE_PATH="build/HDoc.xcarchive"
BUILD_CONFIG="build.xcconfig"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}HDoc TestFlight Build and Upload${NC}"
echo "=================================="

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed or not in PATH${NC}"
    exit 1
fi

# Check if build config exists
if [ ! -f "$BUILD_CONFIG" ]; then
    echo -e "${RED}Error: $BUILD_CONFIG not found${NC}"
    echo "This file is required for Distribution signing. Please ensure it exists."
    exit 1
fi

# Create build directory
mkdir -p build

# Step 1: Clean and prepare
echo -e "${YELLOW}Step 1: Cleaning build folder...${NC}"
rm -rf "$ARCHIVE_PATH"

# Step 2: Archive with Distribution Certificate
echo -e "${YELLOW}Step 2: Building and archiving HDoc with Distribution certificate...${NC}"
echo -e "${YELLOW}(Using build.xcconfig for Distribution signing)${NC}"

xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -xcconfig "$BUILD_CONFIG" \
    -allowProvisioningUpdates

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive failed. $ARCHIVE_PATH not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Archive created with Distribution certificate: $ARCHIVE_PATH${NC}"

# Step 3: Verify archive is signed correctly
echo -e "${YELLOW}Step 3: Verifying archive signature...${NC}"
APP_PATH="$ARCHIVE_PATH/Products/Applications/HDoc.app"

if codesign -v "$APP_PATH" 2>&1 | grep -q "valid on disk"; then
    echo -e "${GREEN}✓ Archive is properly signed${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Archive signature verification returned unexpected result${NC}"
fi

# Step 4: Upload to App Store Connect via Xcode (Manual) or Transporter (Auto)
echo -e "${YELLOW}Step 4: Uploading to App Store Connect...${NC}"

# Check for API credentials
if [ -z "$APP_STORE_CONNECT_KEY_ID" ] || [ -z "$APP_STORE_CONNECT_KEY_ISSUER_ID" ] || [ -z "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" ]; then
    echo -e "${YELLOW}⚠ API credentials not fully set${NC}"
    echo ""
    echo -e "${GREEN}Option 1: Use Xcode Organizer (Recommended)${NC}"
    echo "  Run: open '$ARCHIVE_PATH'"
    echo "  Then click 'Distribute App' and follow the prompts"
    echo ""
    echo -e "${GREEN}Option 2: Set API credentials and re-run${NC}"
    echo "  export APP_STORE_CONNECT_KEY_ID='your-key-id'"
    echo "  export APP_STORE_CONNECT_KEY_ISSUER_ID='your-issuer-id'"
    echo "  export APP_STORE_CONNECT_PRIVATE_KEY_PATH='/path/to/private_key.p8'"
    echo "  ./build_and_upload_testflight.sh"
    exit 0
fi

# Verify private key file exists
if [ ! -f "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" ]; then
    echo -e "${RED}Error: Private key file not found at $APP_STORE_CONNECT_PRIVATE_KEY_PATH${NC}"
    exit 1
fi

# Using Transporter for automated upload with API credentials
echo -e "${YELLOW}Using Transporter to upload with API credentials...${NC}"

# First, create IPA from archive for transporter
EXPORT_PLIST="build/ExportOptions.plist"
IPA_PATH="build/HDoc.ipa"

cat > "$EXPORT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>provisioningProfiles</key>
    <dict/>
</dict>
</plist>
EOF

echo -e "${YELLOW}Exporting IPA from archive...${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_PLIST" \
    -exportPath "build/" \
    -allowProvisioningUpdates 2>&1 | tail -5

if [ ! -f "$IPA_PATH" ]; then
    echo -e "${YELLOW}⚠ IPA export skipped or failed, using archive directly${NC}"
    echo -e "${GREEN}Open the archive in Xcode Organizer:${NC}"
    echo "  open '$ARCHIVE_PATH'"
    exit 0
fi

echo -e "${GREEN}✓ IPA created: $IPA_PATH${NC}"

# Upload with Transporter
xcrun transporter -m upload \
    -f "$IPA_PATH" \
    -k "$APP_STORE_CONNECT_PRIVATE_KEY_PATH" \
    -i "$APP_STORE_CONNECT_KEY_ISSUER_ID" \
    -j "$APP_STORE_CONNECT_KEY_ID" \
    --verbose

echo -e "${GREEN}✓ Upload completed!${NC}"
echo -e "${GREEN}Your build should appear in App Store Connect TestFlight within 5-15 minutes.${NC}"

# HDoc TestFlight Build and Upload Guide

This guide walks you through creating and uploading a TestFlight build for HDoc to App Store Connect.

## Prerequisites

1. **Xcode 13.0 or later** - Required for Transporter
2. **Apple Developer Account** with App Store Connect access
3. **Code signing certificates and provisioning profiles** configured in your Xcode project
4. **App Store Connect API credentials** (Key ID, Issuer ID, and Private Key)

## Step 1: Generate App Store Connect API Credentials

If you don't have API credentials yet, follow these steps:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Keys** → **App Store Connect API**
3. Click the **+** button to create a new key
4. Set the role to **Developer** (or **Admin** if you need broader permissions)
5. Click **Generate**
6. Download the private key file (this will be your `.p8` file) - **save this securely**
7. Note the **Key ID** and **Issuer ID** from the screen

## Step 2: Prepare Your Environment

Create a credentials file or set environment variables. The most secure method is to use a separate credentials file:

### Option A: Using Environment Variables (Recommended)

```bash
export APP_STORE_CONNECT_KEY_ID="your-key-id"
export APP_STORE_CONNECT_KEY_ISSUER_ID="your-issuer-id"
export APP_STORE_CONNECT_PRIVATE_KEY_PATH="/path/to/your/private_key.p8"
```

### Option B: Create a Credentials File

Create a `.env` file (add to `.gitignore` if not already):

```bash
APP_STORE_CONNECT_KEY_ID="your-key-id"
APP_STORE_CONNECT_KEY_ISSUER_ID="your-issuer-id"
APP_STORE_CONNECT_PRIVATE_KEY_PATH="/path/to/your/private_key.p8"
```

Then source it before running the script:

```bash
source .env
./build_and_upload_testflight.sh
```

## Step 3: Verify Xcode Setup

Before building, make sure your Xcode project is properly configured:

1. Open the project in Xcode:
   ```bash
   open MonoRepos/HDoc/HDoc.xcodeproj
   ```

2. Select the **HDoc** target
3. Go to **Signing & Capabilities**
4. Verify:
   - Team is set correctly
   - Bundle ID is correct (should be something like `com.yourcompany.hdoc`)
   - Provisioning profile is set to **App Store Connect**
   - Code signing certificate is valid

## Step 4: Run the Build Script

Once your credentials are set up and Xcode is configured:

```bash
cd /Users/tigerguo/git/ios-mono-repo-huahuahu
./build_and_upload_testflight.sh
```

The script will:
1. Clean the build folder
2. Archive the HDoc app
3. Create an IPA file
4. Upload to App Store Connect using Transporter

## Step 5: Monitor Upload Progress

The upload should start automatically. You can monitor its progress in the script output.

## Step 6: Verify in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select the HDoc app
3. Navigate to **TestFlight**
4. You should see your new build in the **Builds** section under **iOS**
5. Once processing completes, you can distribute it to testers

## Troubleshooting

### Error: "Archive failed"
- Check that you have the latest Xcode installed
- Verify all dependencies are resolved: `swift package resolve`
- Check the detailed Xcode build log for specific errors

### Error: "Private key file not found"
- Verify the path to your `.p8` file is correct
- The file should exist and be readable
- Use an absolute path, not a relative path

### Error: "Transporter not found"
- Update Xcode to the latest version
- Verify you're running on macOS with Xcode 13.0 or later

### Upload takes a long time
- Network speed may affect upload time
- The IPA file is usually 50-200 MB
- Wait for the script to complete - don't interrupt it

### Build appears in App Store Connect but won't process
- Common causes:
  1. Missing IDFA usage declaration (if app collects any data)
  2. Incomplete app review information
  3. Missing screenshots or metadata
- Check the specific error in App Store Connect

## Manual Upload Alternative

If the script fails, you can upload manually:

1. Export the archive manually from Xcode:
   - Open the archive in Xcode Organizer
   - Click "Distribute App"
   - Select "App Store Connect"
   - Follow the prompts

2. Or use Transporter directly:
   ```bash
   /Applications/Transporter.app/Contents/MacOS/Transporter \
     -m upload \
     -f build/HDoc.ipa \
     -k /path/to/private_key.p8 \
     -i your-issuer-id \
     -j your-key-id
   ```

## After Upload

1. Check App Store Connect to see build processing status
2. Once processing completes, go to TestFlight
3. Select the build and add internal or external testers
4. Testers will receive an invitation email

## Security Notes

- **Never commit your `.p8` private key** to git
- Store credentials securely (use environment variables or encrypted files)
- Rotate API keys regularly in App Store Connect
- Use `.gitignore` to prevent accidental commits of sensitive files

## Getting Help

For more information:
- [Apple App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Xcode Build Documentation](https://developer.apple.com/documentation/xcode)
- [Transporter Documentation](https://help.apple.com/itc/transporter/)

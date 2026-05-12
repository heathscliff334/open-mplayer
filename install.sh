#!/bin/bash

# Open MPlayer Installation Script
# Builds the app and installs it to /Applications

set -e  # Exit on error

echo "🎬 Open MPlayer Installation Script"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "OpenMPlayer.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: OpenMPlayer.xcodeproj not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found"
    echo "Please install Xcode and Command Line Tools"
    exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_VERSION" -lt 15 ]; then
    echo "⚠️  Warning: This app requires macOS 15.0 (Tahoe) or later"
    echo "Your version: $(sw_vers -productVersion)"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📦 Building Open MPlayer..."
echo ""

# Clean build folder
xcodebuild clean \
    -project OpenMPlayer.xcodeproj \
    -scheme OpenMPlayer \
    -configuration Release \
    > /dev/null 2>&1

# Build the app
xcodebuild build \
    -project OpenMPlayer.xcodeproj \
    -scheme OpenMPlayer \
    -configuration Release \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

# Find the built app
APP_PATH="./build/Build/Products/Release/OpenMPlayer.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Built app not found at $APP_PATH"
    exit 1
fi

# Show build location
FULL_APP_PATH="$(cd "$(dirname "$APP_PATH")" && pwd)/$(basename "$APP_PATH")"
echo "📍 Built app location:"
echo "   $FULL_APP_PATH"
echo ""

# Check if app already exists in Applications
if [ -d "/Applications/OpenMPlayer.app" ]; then
    echo "⚠️  OpenMPlayer.app already exists in /Applications"
    read -p "Replace it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing old version..."
        rm -rf "/Applications/OpenMPlayer.app"
    else
        echo "Installation cancelled"
        exit 0
    fi
fi

# Copy to Applications
echo "📥 Installing to /Applications..."
cp -R "$APP_PATH" /Applications/

if [ $? -ne 0 ]; then
    echo "❌ Installation failed"
    echo "You may need to run with sudo: sudo ./install.sh"
    exit 1
fi

echo "✅ Installation complete!"
echo ""
echo "🎉 Open MPlayer has been installed to /Applications"
echo ""
echo "To launch:"
echo "  • Open from Applications folder"
echo "  • Or run: open /Applications/OpenMPlayer.app"
echo ""
echo "Manual installation (if needed):"
echo "  cp -r \"$FULL_APP_PATH\" /Applications/"
echo "  xattr -dr com.apple.quarantine /Applications/OpenMPlayer.app"
echo ""
echo "To uninstall:"
echo "  rm -rf /Applications/OpenMPlayer.app"
echo ""
echo "Enjoy your new media player! 🎬"

# Remove quarantine attribute to prevent Gatekeeper issues
echo "🔓 Removing quarantine attribute..."
xattr -dr com.apple.quarantine /Applications/OpenMPlayer.app 2>/dev/null || true

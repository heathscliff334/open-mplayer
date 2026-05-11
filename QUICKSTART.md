# Quick Start Guide

## Building Open MPlayer

### Prerequisites
- macOS Tahoe (15.0) or later
- Xcode 15.0 or later
- Command Line Tools installed

### Build Steps

1. **Open the project**
   ```bash
   cd /Users/167560.KEVIN/Development/Builder.io/open-mplayer
   open OpenMPlayer.xcodeproj
   ```

2. **In Xcode:**
   - Wait for indexing to complete
   - Select "My Mac" as the target device
   - Press `Cmd + B` to build
   - Press `Cmd + R` to run

3. **Command line build (optional):**
   ```bash
   xcodebuild -project OpenMPlayer.xcodeproj \
              -scheme OpenMPlayer \
              -configuration Debug \
              build
   ```

### First Run

1. The app will open with a drop zone
2. Drag a video file (MP4, MOV, MKV, etc.) onto the window
3. Or press `Cmd + O` to open a file picker
4. Video will start playing automatically

### Keyboard Shortcuts
- `Space` - Play/Pause
- `←` / `→` - Seek backward/forward 5 seconds
- `↑` / `↓` - Volume up/down
- `F` - Toggle fullscreen
- `Cmd + O` - Open file
- `Cmd + W` - Close window

### Troubleshooting

**Build fails with "No such module 'AVFoundation'"**
- Ensure you're building for macOS (not iOS)
- Clean build folder: `Cmd + Shift + K`

**App crashes on launch**
- Check you're running macOS 15.0+
- Verify code signing settings in Xcode

**Video won't play**
- Check file format is supported
- Try a different video file
- Check Console.app for error messages

### Next Steps

See [README.md](README.md) for full documentation and [AGENTS.md](AGENTS.md) for architecture details.

# Open MPlayer

A modern, native macOS media player built with Swift and SwiftUI. Designed for macOS Tahoe (15.0) and later.

## Features

### Current
- 🎬 Native AVFoundation playback engine
- 🎨 Modern SwiftUI interface
- 📁 Drag-and-drop file support
- ⌨️ Keyboard shortcuts
- 🌓 Dark mode support
- 📋 Playlist management

### Planned
- 📝 Subtitle support (SRT, VTT)
- 🎵 Multiple audio track selection
- 🖼️ Picture-in-picture mode
- 🌐 Streaming support (HTTP/HTTPS)
- 🎛️ Video filters and adjustments

## Supported Formats

- **Video**: MP4, MOV, M4V (native AVFoundation support)
- **Audio**: MP3, AAC, FLAC, WAV, M4A
- **Limited Support**: AVI, WebM (depends on codecs)
- **Not Supported**: MKV (requires external codec libraries like FFmpeg)
- **Subtitles**: SRT, VTT (planned)

## Requirements

- macOS Tahoe (15.0) or later
- Xcode 15.0+ (for building from source)

## Installation

### Option 1: Quick Install Script (Recommended)
```bash
cd open-mplayer
./install.sh
```
This will build the app and install it to `/Applications/OpenMPlayer.app`.

### Option 2: Download Pre-built App (Coming Soon)
Download the latest release from the [Releases](https://github.com/yourusername/open-mplayer/releases) page.

### Option 3: Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/open-mplayer.git
   cd open-mplayer
   ```

2. **Open in Xcode**
   ```bash
   open OpenMPlayer.xcodeproj
   ```

3. **Build and Run**
   - Select your Mac as the target device
   - Press `Cmd + R` to build and run
   - Or use `Cmd + B` to build only

4. **Create Release Build**
   ```bash
   xcodebuild -project OpenMPlayer.xcodeproj \
              -scheme OpenMPlayer \
              -configuration Release \
              -derivedDataPath ./build
   ```
   
   The app will be located at:
   ```
   ./build/Build/Products/Release/OpenMPlayer.app
   ```

5. **Install to Applications**
   ```bash
   cp -r ./build/Build/Products/Release/OpenMPlayer.app /Applications/
   ```

## Usage

### Opening Files
- **Drag and drop** a video file onto the app window
- **File menu**: `File > Open...` (Cmd + O)
- **Right-click** a video file and select "Open With > OpenMPlayer"

### Keyboard Shortcuts
- `Space` - Play/Pause
- `←` / `→` - Seek backward/forward 5 seconds
- `↑` / `↓` - Volume up/down
- `F` - Toggle fullscreen
- `Cmd + O` - Open file
- `Cmd + W` - Close window
- `Cmd + Q` - Quit app

### Playback Controls
- Click the play/pause button or press `Space`
- Drag the timeline scrubber to seek
- Adjust volume with the slider or arrow keys
- Double-click video for fullscreen

## Development

### Project Structure
```
OpenMPlayer/
├── Sources/
│   ├── App/
│   │   ├── OpenMPlayerApp.swift      # App entry point
│   │   └── KeyboardShortcuts.swift   # Keyboard handling
│   ├── UI/
│   │   ├── PlayerView.swift          # Main player interface
│   │   ├── ControlsView.swift        # Playback controls
│   │   └── PlaylistView.swift        # Playlist sidebar
│   ├── PlaybackEngine/
│   │   ├── PlayerController.swift    # AVFoundation wrapper
│   │   ├── MediaLoader.swift         # File loading
│   │   └── SubtitleRenderer.swift    # Subtitle support
│   └── FileManagement/
│       └── FileHandler.swift         # File operations
├── Resources/
│   └── Assets.xcassets/              # App icons and images
├── Tests/
│   └── OpenMPlayerTests/             # Unit tests
└── AGENTS.md                         # Agent collaboration guide
```

### Building for Development
```bash
# Run tests
xcodebuild test -project OpenMPlayer.xcodeproj -scheme OpenMPlayer

# Build debug version
xcodebuild -project OpenMPlayer.xcodeproj \
           -scheme OpenMPlayer \
           -configuration Debug
```

### Code Style
- Swift 5.9+
- SwiftUI for all UI components
- Async/await for asynchronous operations
- Follow [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

## Troubleshooting

### App crashes on launch
- Ensure you're running macOS Tahoe (15.0) or later
- Check Console.app for crash logs
- Try rebuilding with `xcodebuild clean build`

### Video won't play
- Verify the file format is supported
- Check file permissions
- Try converting the file with HandBrake or FFmpeg

### Performance issues
- Close other applications
- Check Activity Monitor for CPU/memory usage
- Try reducing video quality or resolution

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [AGENTS.md](AGENTS.md) for architecture and collaboration guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Apple's AVFoundation and SwiftUI frameworks
- Inspired by VLC Media Player and IINA
- Created as a native macOS Tahoe-compatible alternative

## Support

- 🐛 [Report bugs](https://github.com/yourusername/open-mplayer/issues)
- 💡 [Request features](https://github.com/yourusername/open-mplayer/issues)
- 📧 Contact: your.email@example.com

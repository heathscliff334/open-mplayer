# Open MPlayer - Agent Collaboration Guide

## Project Overview
Open MPlayer is a modern, native macOS media player built with Swift and SwiftUI, designed to work seamlessly with macOS Tahoe and later versions.

## Architecture

### Core Components
1. **Playback Engine** (`Sources/PlaybackEngine/`)
   - AVFoundation-based media playback
   - Format support: MP4, MOV, MKV, AVI, WebM
   - Audio/video synchronization
   - Subtitle rendering

2. **UI Layer** (`Sources/UI/`)
   - SwiftUI-based modern interface
   - Custom video player controls
   - Playlist management
   - Settings and preferences

3. **File Management** (`Sources/FileManagement/`)
   - File browser integration
   - Recent files tracking
   - Drag-and-drop support

## Development Agents

### UI/UX Agent
**Responsibilities:**
- Design modern, intuitive interface components
- Implement SwiftUI views and animations
- Ensure macOS Human Interface Guidelines compliance
- Handle dark mode and accessibility

**Key Files:**
- `Sources/UI/PlayerView.swift`
- `Sources/UI/ControlsView.swift`
- `Sources/UI/PlaylistView.swift`

### Playback Agent
**Responsibilities:**
- Implement AVFoundation playback logic
- Handle media format detection and loading
- Manage playback state (play, pause, seek, volume)
- Implement subtitle support

**Key Files:**
- `Sources/PlaybackEngine/PlayerController.swift`
- `Sources/PlaybackEngine/MediaLoader.swift`
- `Sources/PlaybackEngine/SubtitleRenderer.swift`

### Integration Agent
**Responsibilities:**
- File system integration
- Keyboard shortcuts
- Menu bar and dock integration
- App lifecycle management

**Key Files:**
- `Sources/App/OpenMPlayerApp.swift`
- `Sources/FileManagement/FileHandler.swift`
- `Sources/App/KeyboardShortcuts.swift`

## Collaboration Workflow

### Phase 1: Foundation (Current)
- Set up Xcode project structure
- Implement basic AVFoundation playback
- Create minimal UI shell

### Phase 2: Core Features
- Full playback controls (play, pause, seek, volume)
- File opening and drag-drop
- Basic playlist support

### Phase 3: Polish
- Keyboard shortcuts
- Recent files menu
- Subtitle support
- Settings panel

### Phase 4: Advanced Features
- Audio track selection
- Video filters
- Streaming support
- Picture-in-picture

## Communication Protocol

### When Adding Features
1. Check existing implementations in related components
2. Follow SwiftUI best practices
3. Maintain separation between UI and business logic
4. Add unit tests for playback logic

### When Fixing Bugs
1. Identify affected component (UI, Playback, Integration)
2. Check for related issues in other components
3. Test on macOS Tahoe specifically

## Code Style
- Swift 5.9+
- SwiftUI for all UI components
- Async/await for asynchronous operations
- Combine for reactive state management
- Follow Apple's Swift API Design Guidelines

## Testing Strategy
- Unit tests for playback engine
- UI tests for critical user flows
- Manual testing on macOS Tahoe
- Performance testing with large files

## Dependencies
- AVFoundation (system framework)
- AVKit (system framework)
- SwiftUI (system framework)
- No external dependencies initially (keep it lightweight)

## Build Requirements
- Xcode 15.0+
- macOS Tahoe (15.0) or later
- Swift 5.9+

## Agent Handoff Checklist
When passing work between agents:
- [ ] Document current state in commit message
- [ ] Update relevant documentation
- [ ] Note any blockers or dependencies
- [ ] Highlight areas needing review
- [ ] Run tests before handoff

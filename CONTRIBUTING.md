# Contributing to Open MPlayer

Thank you for your interest in contributing to Open MPlayer!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/open-mplayer.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test thoroughly on macOS Tahoe
6. Commit with clear messages
7. Push and create a Pull Request

## Development Setup

### Requirements
- macOS Tahoe (15.0) or later
- Xcode 15.0+
- Swift 5.9+

### Building
```bash
open OpenMPlayer.xcodeproj
# Press Cmd+R to build and run
```

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI for all UI components
- Prefer async/await over completion handlers
- Add comments only for non-obvious logic
- Keep functions focused and small

## Architecture

See [AGENTS.md](AGENTS.md) for detailed architecture documentation.

### Key Principles
- Separation of concerns (UI, business logic, playback)
- Reactive state management with Combine
- Thread-safe with @MainActor
- Memory-safe with weak references

## Testing

Before submitting a PR:
- [ ] Build succeeds without warnings
- [ ] App launches and plays video files
- [ ] All keyboard shortcuts work
- [ ] Controls auto-hide properly
- [ ] No memory leaks (check Instruments)
- [ ] Works on macOS Tahoe

## Pull Request Guidelines

### PR Title Format
- `feat: Add subtitle support`
- `fix: Timeline scrubbing accuracy`
- `docs: Update README with new features`
- `refactor: Simplify PlayerController`

### PR Description
Include:
- What changed and why
- Screenshots/videos for UI changes
- Testing performed
- Any breaking changes

## Feature Requests

Open an issue with:
- Clear description of the feature
- Use case / motivation
- Proposed implementation (optional)

## Bug Reports

Include:
- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Console logs if applicable
- Video file format that caused the issue

## Areas for Contribution

### High Priority
- Subtitle support (SRT, VTT)
- Playlist sidebar
- Recent files menu
- App icon design

### Medium Priority
- Audio track selection
- Video filters
- Streaming support
- Picture-in-picture

### Low Priority
- Preferences window
- Custom keyboard shortcuts
- Advanced playback features
- Gesture support

## Questions?

Open an issue or discussion on GitHub.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.




![icon_256x256_transparent](https://github.com/user-attachments/assets/d33edfbf-ba4d-49e3-b8b2-cd2ce1770929)

# Cat Mode 🐱

A macOS utility that prevents accidental keyboard and mouse input by blocking all system events. Perfect for when your cat decides to help you code!

## Features

- 🚫 Blocks all keyboard input, including media keys and function keys
- 🖱️ Blocks all mouse events
- ⌨️ Customizable keyboard shortcut to toggle Cat Mode
- 🎨 Visual indicators when Cat Mode is active:
  - Status bar menu icon
  - Black overlay bar at the top of the screen
  - Subtle screen tint
- 🔒 Safe deactivation options:
  - Keyboard shortcut
  - Clickable area for deactiviation (coming soon ❗) 

## Requirements

- macOS 11.0 or later
- Xcode 13.0 or later (for building)

## Installation

### From Release

1. Download the latest release from the [Releases](https://github.com/christianolander/cat-mode/releases) page
2. Move catmode.app to your Applications folder
3. Launch catmode
4. Grant necessary permissions when prompted:
   - Accessibility
   - Input Monitoring

### Building from Source

1. Clone the repository

```bash
git clone https://github.com/yourusername/cat-mode.git
cd cat-mode
```

2. Open the project in Xcode

```bash
open catmode/CatMode.xcodeproj
```

3. Build and run the project (⌘R)

## Usage

1. **First Launch**:

   - Configure your preferred keyboard shortcut in the preferences
   - Grant required permissions when prompted

2. **Activating Cat Mode**:

   - Use your configured keyboard shortcut
   - The screen will slightly dim and show a black bar at the top
   - The menu bar icon will change to indicate Cat Mode is active

3. **Deactivating Cat Mode**:
   - Use the same keyboard shortcut

## Permissions

Cat Mode requires the following permissions to function:

- **Accessibility**: Required to monitor and block keyboard events
- **Input Monitoring**: Required to monitor and block mouse events

These permissions can be granted in System Settings → Privacy & Security → Accessibility/Input Monitoring

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Dependencies

- [MASShortcut](https://github.com/shpakovski/MASShortcut): For handling global keyboard shortcuts

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Acknowledgments
- Special thanks to the feline friends for inspiring this project 😺

## Support

If you encounter any issues or have questions, please:

1. Check the [Issues](https://github.com/yourusername/cat-mode/issues) page
2. Create a new issue if your problem isn't already reported

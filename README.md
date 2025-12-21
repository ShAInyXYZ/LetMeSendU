# LetMeSendU

Share files and messages with nearby devices over your local network - no internet required.

## Features

- Cross-platform file sharing (currently Linux desktop, more coming)
- Compatible with [LocalSend](https://github.com/localsend/localsend) Android/iOS apps
- No internet connection needed - works over local WiFi
- Secure transfers using the LocalSend Protocol v2.1
- Simple, clean Material Design 3 interface
- **Quick Send (F11)** - Global hotkey to open a floating drop zone for instant file transfers
- **Device Linking** - Link a device for one-click sending without confirmation

## Quick Send

Press **F11** anywhere to toggle the Quick Send floating window. Drag and drop files to instantly send them to your linked device.

1. Open LetMeSendU and link a device (click the link icon)
2. Press **F11** to open the Quick Send overlay
3. Drag and drop files - they're sent immediately!
4. Press **F11** again to close

## Building

### Prerequisites

- Flutter SDK 3.10+
- Linux development tools: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`
- Additional libraries: `libkeybinder-3.0-dev`, `libayatana-appindicator3-dev`

### Build & Run

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d linux

# Build release
flutter build linux --release
```

## Author

**ShAInyXYZ** - [GitHub](https://github.com/ShAInyXYZ)

## Attribution

This project is a derivative work based on [LocalSend](https://github.com/localsend/localsend) by Tien Do Nam, implementing the [LocalSend Protocol](https://github.com/localsend/protocol) for cross-device file sharing compatibility.

## License

Licensed under the Apache License 2.0 - see [LICENSE](LICENSE) and [NOTICE](NOTICE) files for details.

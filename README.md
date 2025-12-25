<p align="center">
  <img src="Logo.png" alt="LetMeSendU Logo" width="120" height="120">
</p>

<h1 align="center">LetMeSendU</h1>

<p align="center">
  <strong>A LocalSend-compatible file sharing app built with Flutter</strong>
</p>

<p align="center">
  Share files seamlessly between devices on your local network — no internet required, no cloud, no limits.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Android-lightgrey?style=for-the-badge" alt="Platform">
</p>

---

## Author

<p>
  <strong>ShAInyXYZ</strong> — <a href="https://github.com/ShAInyXYZ">GitHub Profile</a>
</p>

---

## Screenshots

<p align="center">
  <em>Coming soon</em>
</p>

---

## Features

<table>
<tr>
<td width="50%">

### File Sharing
- **LocalSend Protocol v2.1** — Compatible with LocalSend apps
- **UDP Multicast Discovery** — Auto-detect nearby devices
- **Direct Transfer** — Device-to-device, no cloud
- **Any File Type** — Photos, videos, documents, APKs, etc.

</td>
<td width="50%">

### Device Management
- **Custom Device Names** — Easy identification
- **Device Linking** — Quick send to favorite device
- **Auto-Discovery** — Finds devices on same network
- **Duplicate Prevention** — Smart device detection

</td>
</tr>
<tr>
<td width="50%">

### Desktop Features (Linux)
- **Quick Send (F11)** — Global hotkey overlay
- **System Tray** — Quick access
- **Window Management** — Clean, minimal UI
- **Drag & Drop** — Easy file selection

</td>
<td width="50%">

### Mobile Features (Android)
- **Gallery Browser** — View received files by category
- **Date Grouping** — Today, Yesterday, This Week, etc.
- **File Categories** — Photos, Videos, Documents, Data
- **Pull to Refresh** — Update file list easily

</td>
</tr>
<tr>
<td width="50%">

### Transfer Experience
- **Progress Tracking** — Real-time transfer status
- **Batch Transfers** — Send multiple files at once
- **Auto Accept** — Seamless receiving
- **Notification Overlay** — See received files instantly

</td>
<td width="50%">

### User Experience
- **Dark Theme** — Eye-friendly design
- **Clean UI** — Minimal, intuitive interface
- **Cross-Platform** — Same experience everywhere
- **Offline First** — No internet required

</td>
</tr>
</table>

---

## How It Works

```
┌─────────────┐         UDP Multicast          ┌─────────────┐
│   Desktop   │ ◄──────────────────────────► │   Android   │
│   (Linux)   │         224.0.0.167:53317      │   (Phone)   │
└──────┬──────┘                                └──────┬──────┘
       │                                              │
       │            HTTP File Transfer                │
       └──────────────────────────────────────────────┘
                     Port 53317
```

1. **Discovery** — Devices announce themselves via UDP multicast
2. **Registration** — Devices exchange info (name, IP, port)
3. **Transfer** — Files sent directly over HTTP on local network

---

## Color Palette

LetMeSendU uses a sleek dark theme:

<table>
<tr>
<th colspan="3" align="center">Primary Colors</th>
</tr>
<tr>
<td align="center">
  <img src="https://via.placeholder.com/60x30/7C3AED/7C3AED" alt="Primary Purple"><br>
  <code>#7C3AED</code><br>
  <sub>Primary Purple</sub>
</td>
<td align="center">
  <img src="https://via.placeholder.com/60x30/A855F7/A855F7" alt="Light Purple"><br>
  <code>#A855F7</code><br>
  <sub>Accent Purple</sub>
</td>
<td align="center">
  <img src="https://via.placeholder.com/60x30/22C55E/22C55E" alt="Success Green"><br>
  <code>#22C55E</code><br>
  <sub>Success Green</sub>
</td>
</tr>
</table>

<table>
<tr>
<th colspan="4" align="center">Background Colors</th>
</tr>
<tr>
<td align="center">
  <img src="https://via.placeholder.com/60x30/0D0D0F/0D0D0F" alt="Dark Background"><br>
  <code>#0D0D0F</code><br>
  <sub>Background</sub>
</td>
<td align="center">
  <img src="https://via.placeholder.com/60x30/1A1A1D/1A1A1D" alt="Surface"><br>
  <code>#1A1A1D</code><br>
  <sub>Surface</sub>
</td>
<td align="center">
  <img src="https://via.placeholder.com/60x30/232328/232328" alt="Card"><br>
  <code>#232328</code><br>
  <sub>Card</sub>
</td>
<td align="center">
  <img src="https://via.placeholder.com/60x30/2A2A2F/2A2A2F" alt="Border"><br>
  <code>#2A2A2F</code><br>
  <sub>Border</sub>
</td>
</tr>
</table>

---

## Tech Stack

<table>
<tr>
<td align="center" width="96">
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" width="48" height="48" alt="Flutter">
  <br><strong>Flutter</strong>
</td>
<td align="center" width="96">
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" width="48" height="48" alt="Dart">
  <br><strong>Dart</strong>
</td>
<td align="center" width="96">
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/linux/linux-original.svg" width="48" height="48" alt="Linux">
  <br><strong>Linux</strong>
</td>
<td align="center" width="96">
  <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/android/android-original.svg" width="48" height="48" alt="Android">
  <br><strong>Android</strong>
</td>
</tr>
</table>

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.10+ |
| Language | Dart |
| Protocol | LocalSend v2.1 |
| Discovery | UDP Multicast (224.0.0.167:53317) |
| Transfer | HTTP REST API |
| State Management | Provider |
| HTTP Server | shelf, shelf_router |
| Desktop | window_manager, hotkey_manager, tray_manager |
| Networking | http, network_info_plus |

---

## Requirements

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.10.4+ |
| Dart SDK | 3.10.4+ |
| Android | 5.0 (API 21)+ |
| Linux | Any modern distro |

### Required Permissions

**Android:**
| Permission | Usage |
|------------|-------|
| Storage | Read/write transferred files |
| Manage External Storage | Access Downloads folder |

**Linux:**
| Permission | Usage |
|------------|-------|
| Network | UDP multicast & HTTP server |

---

## Installation

### Prerequisites

```bash
# 1. Install Flutter SDK
# Download from: https://flutter.dev/docs/get-started/install

# 2. Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# 3. Verify installation
flutter doctor
```

### Clone and Run

```bash
# Clone the repository
git clone https://github.com/ShAInyXYZ/LetMeSendU.git
cd LetMeSendU

# Install dependencies
flutter pub get

# Run on Linux desktop
flutter run -d linux

# Run on Android device
flutter run -d <device_id>
```

### Development Commands

```bash
# List available devices
flutter devices

# Run in debug mode (with hot reload)
flutter run

# Run on specific device
flutter run -d <device_id>

# Analyze code
flutter analyze

# Format code
dart format lib/
```

---

## Building for Release

### Linux Desktop

```bash
# Build release binary
flutter build linux --release
```

> Output: `build/linux/x64/release/bundle/`

### Android APK

```bash
# Build release APK
flutter build apk --release

# Build split APKs (smaller files)
flutter build apk --split-per-abi
```

> Output: `build/app/outputs/flutter-apk/app-release.apk`

### Update App Icon

```bash
# Replace Logo.png in project root, then run:
dart run flutter_launcher_icons
```

---

## Project Structure

```
LetMeSendU/
├── android/                    # Android platform files
├── linux/                      # Linux platform files
├── lib/
│   ├── main.dart              # Unified entry point (desktop + mobile)
│   ├── models/
│   │   ├── device_info.dart   # Device model
│   │   └── transfer_session.dart
│   ├── providers/
│   │   └── app_provider.dart  # State management
│   ├── screens/
│   │   ├── home_screen.dart   # Desktop home
│   │   ├── quick_send_window.dart
│   │   └── android/
│   │       ├── android_home_screen.dart
│   │       └── gallery_screen.dart
│   ├── services/
│   │   ├── device_service.dart
│   │   ├── discovery_service.dart
│   │   ├── api_server.dart
│   │   ├── file_sender.dart
│   │   └── settings_service.dart
│   └── theme/
│       └── app_theme.dart
├── assets/
│   └── logo.png
├── Logo.png                    # App icon source
└── pubspec.yaml
```

---

## Privacy & Security

<table>
<tr>
<td>

**LetMeSendU respects your privacy:**

- **Local Network Only** — Files never leave your network
- **No Cloud** — Direct device-to-device transfer
- **No Analytics** — Zero tracking or data collection
- **No Internet Required** — Works completely offline
- **Open Protocol** — Compatible with LocalSend

</td>
</tr>
</table>

---

## Troubleshooting

<details>
<summary><strong>Devices not discovering each other</strong></summary>

- Ensure both devices are on the same WiFi network
- Check if firewall is blocking port 53317
- Try restarting the app on both devices
- Verify multicast is not blocked on your router
</details>

<details>
<summary><strong>Transfer fails or times out</strong></summary>

- Check network connection stability
- Ensure target device has enough storage
- Try sending smaller files first
</details>

<details>
<summary><strong>Permission denied on Android</strong></summary>

- Grant storage permissions in device settings
- For Android 11+, grant "Manage External Storage" permission
</details>

<details>
<summary><strong>Quick Send (F11) not working on Linux</strong></summary>

- Ensure no other app is using the F11 hotkey
- Try restarting the app
</details>

<details>
<summary><strong>Build fails with "SDK version" error</strong></summary>

```bash
flutter upgrade
flutter pub get
```
</details>

---

## Part of the LetMe Series

LetMeSendU is part of the **LetMe** software series — utility apps that do one thing exceptionally well.

| App | Description | Status |
|-----|-------------|--------|
| **LetMeSendU** | LocalSend-compatible file sharing | Released |
| **LetMeNoteU** | Privacy-focused note-taking | Released |
| **LetMeBrowseU** | Minimal file manager | Planned |

---

## Attribution

This project implements the [LocalSend Protocol](https://github.com/localsend/protocol) for cross-device file sharing compatibility with [LocalSend](https://github.com/localsend/localsend) by Tien Do Nam.

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

```bash
# 1. Fork the repository
# 2. Create your feature branch
git checkout -b feature/AmazingFeature

# 3. Commit your changes
git commit -m 'Add some AmazingFeature'

# 4. Push to the branch
git push origin feature/AmazingFeature

# 5. Open a Pull Request
```

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format lib/` before committing
- Run `flutter analyze` to check for issues

---

## License

This project is licensed under the **Apache License 2.0** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <img src="Logo.png" alt="LetMeSendU" width="40" height="40">
</p>

<p align="center">
  Made with Flutter by <a href="https://github.com/ShAInyXYZ">ShAInyXYZ</a>
</p>

<p align="center">
  <sub>If you found this project helpful, consider giving it a star!</sub>
</p>

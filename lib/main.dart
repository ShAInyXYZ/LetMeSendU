import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/android/android_home_screen.dart';
import 'services/device_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

late SettingsService settingsService;
late DeviceService deviceService;

// Global key for accessing HomeScreen state
final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  settingsService = SettingsService();
  await settingsService.init();

  // Get saved device name or use default
  final savedDeviceName = settingsService.getDeviceName();
  deviceService = DeviceService(customAlias: savedDeviceName);

  // Platform-specific initialization
  if (Platform.isAndroid || Platform.isIOS) {
    await _launchMobileApp();
  } else {
    // Desktop platforms (Linux, Windows, macOS)
    await windowManager.ensureInitialized();
    await _launchMainWindow();
  }
}

Future<void> _launchMobileApp() async {
  // Request storage permissions (Android only)
  if (Platform.isAndroid) {
    final storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
    final manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  runApp(const LetMeSendUMobileApp());
}

class LetMeSendUMobileApp extends StatelessWidget {
  const LetMeSendUMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final savedName = settingsService.getDeviceName();
    return ChangeNotifierProvider(
      create: (_) => AppProvider(deviceName: savedName),
      child: MaterialApp(
        title: 'LetMeSendU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AndroidHomeScreen(),
      ),
    );
  }
}

Future<void> _launchMainWindow() async {
  const windowOptions = WindowOptions(
    size: Size(450, 800),
    minimumSize: Size(400, 600),
    center: true,
    title: 'LetMeSendU',
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setIcon('assets/logo.png');
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const LetMeSendUApp());
}

// Main application with full UI
class LetMeSendUApp extends StatefulWidget {
  const LetMeSendUApp({super.key});

  @override
  State<LetMeSendUApp> createState() => _LetMeSendUAppState();
}

class _LetMeSendUAppState extends State<LetMeSendUApp> with TrayListener, WindowListener {
  final _hotkey = HotKey(
    key: PhysicalKeyboardKey.f11,
    modifiers: [],
  );

  @override
  void initState() {
    super.initState();
    _initHotkey();
    _initTray();
    windowManager.addListener(this);
  }

  Future<void> _initHotkey() async {
    await hotKeyManager.register(
      _hotkey,
      keyDownHandler: (_) => _toggleQuickSend(),
    );
  }

  Future<void> _initTray() async {
    trayManager.addListener(this);
  }

  void _toggleQuickSend() {
    // Toggle QuickSend overlay in HomeScreen
    homeScreenKey.currentState?.toggleQuickSendOverlay();
  }

  @override
  void dispose() {
    hotKeyManager.unregister(_hotkey);
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    _toggleQuickSend();
  }

  @override
  Widget build(BuildContext context) {
    final savedName = settingsService.getDeviceName();
    return ChangeNotifierProvider(
      create: (_) => AppProvider(deviceName: savedName),
      child: MaterialApp(
        title: 'LetMeSendU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: HomeScreen(key: homeScreenKey),
      ),
    );
  }
}

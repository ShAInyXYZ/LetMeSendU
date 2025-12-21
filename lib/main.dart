import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/quick_send_window.dart';
import 'services/device_service.dart';
import 'services/settings_service.dart';

late SettingsService settingsService;
late DeviceService deviceService;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  settingsService = SettingsService();
  await settingsService.init();
  deviceService = DeviceService();

  // Check if launching as quick send window
  final isQuickSendWindow = args.contains('--quick-send');

  await windowManager.ensureInitialized();

  if (isQuickSendWindow) {
    await _launchQuickSendWindow();
  } else {
    await _launchMainWindow();
  }
}

Future<void> _launchMainWindow() async {
  const windowOptions = WindowOptions(
    size: Size(450, 600),
    minimumSize: Size(400, 500),
    center: true,
    title: 'LetMeSendU',
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const LetMeSendUApp());
}

Future<void> _launchQuickSendWindow() async {
  // Get screen size to position in bottom-right
  final screenSize = await windowManager.getSize();

  const windowWidth = 300.0;
  const windowHeight = 220.0;

  const windowOptions = WindowOptions(
    size: Size(windowWidth, windowHeight),
    minimumSize: Size(windowWidth, windowHeight),
    maximumSize: Size(windowWidth, windowHeight),
    center: false,
    title: 'Quick Send',
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    alwaysOnTop: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Position in bottom-right corner
    // We need to get the screen bounds
    await windowManager.setPosition(const Offset(1600, 800)); // Will be adjusted
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const QuickSendApp());
}

// Main application with full UI
class LetMeSendUApp extends StatefulWidget {
  const LetMeSendUApp({super.key});

  @override
  State<LetMeSendUApp> createState() => _LetMeSendUAppState();
}

class _LetMeSendUAppState extends State<LetMeSendUApp> with TrayListener, WindowListener {
  int? _quickSendPid;
  bool _quickSendOpen = false;
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

  Future<void> _toggleQuickSend() async {
    if (_quickSendOpen && _quickSendPid != null) {
      // Kill existing quick send window
      try {
        Process.killPid(_quickSendPid!, ProcessSignal.sigterm);
      } catch (e) {
        // Process might already be dead
      }
      _quickSendPid = null;
      _quickSendOpen = false;
    } else {
      // Launch quick send window as separate process
      final executable = Platform.resolvedExecutable;
      final process = await Process.start(
        executable,
        ['--quick-send'],
        mode: ProcessStartMode.inheritStdio,
      );

      _quickSendPid = process.pid;
      _quickSendOpen = true;

      // Monitor when the process exits (user closes window via X)
      process.exitCode.then((_) {
        _quickSendPid = null;
        _quickSendOpen = false;
      });
    }
  }

  @override
  void dispose() {
    hotKeyManager.unregister(_hotkey);
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    if (_quickSendPid != null) {
      Process.killPid(_quickSendPid!);
    }
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    _toggleQuickSend();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'LetMeSendU',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}

// Standalone Quick Send window app
class QuickSendApp extends StatelessWidget {
  const QuickSendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Send',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: QuickSendWindow(
        settingsService: settingsService,
        deviceService: deviceService,
      ),
    );
  }
}

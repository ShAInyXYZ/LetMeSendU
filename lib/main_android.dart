import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/android/android_home_screen.dart';
import 'services/device_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

late SettingsService settingsService;
late DeviceService deviceService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permissions (Android only)
  if (Platform.isAndroid) {
    await _requestStoragePermissions();
  }

  // Initialize services
  settingsService = SettingsService();
  await settingsService.init();

  // Get saved device name or use default
  final savedDeviceName = settingsService.getDeviceName();
  print('[Main] Saved device name from settings: $savedDeviceName');
  deviceService = DeviceService(customAlias: savedDeviceName);

  runApp(const LetMeSendUAndroidApp());
}

Future<void> _requestStoragePermissions() async {
  // For Android 13+ (API 33+), request media permissions
  // For older Android, request storage permission
  final storageStatus = await Permission.storage.status;
  if (!storageStatus.isGranted) {
    await Permission.storage.request();
  }

  // Request manage external storage for Android 11+ to write to Downloads
  final manageStatus = await Permission.manageExternalStorage.status;
  if (!manageStatus.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}

class LetMeSendUAndroidApp extends StatelessWidget {
  const LetMeSendUAndroidApp({super.key});

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

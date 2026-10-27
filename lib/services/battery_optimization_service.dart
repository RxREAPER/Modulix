import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Structured OEM brand advice for background execution reliability.
class BrandReliabilityAdvice {
  final String brandName;
  final String title;
  final List<String> steps;
  final String? lockInRecentsTip;
  final bool isAggressiveOem;

  const BrandReliabilityAdvice({
    required this.brandName,
    required this.title,
    required this.steps,
    this.lockInRecentsTip,
    this.isAggressiveOem = false,
  });
}

/// Device hardware & OS profile summary for diagnostic purposes.
class DeviceHardwareProfile {
  final String manufacturer;
  final String model;
  final int sdkVersion;

  const DeviceHardwareProfile({
    required this.manufacturer,
    required this.model,
    required this.sdkVersion,
  });

  bool get isAndroid14OrHigher => sdkVersion >= 34;
  bool get isAndroid15OrHigher => sdkVersion >= 35;
}

/// Native bridge for Android Battery Optimization exemptions (Doze Mode Piercing)
/// and OEM brand-specific guidance.
class BatteryOptimizationService {
  BatteryOptimizationService._();
  static final BatteryOptimizationService instance = BatteryOptimizationService._();

  static const _channel = MethodChannel('com.modulix.app/battery_optimization');

  DeviceHardwareProfile? _cachedProfile;

  /// Check whether Modulix is exempt from Android battery optimization / Doze mode.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[BatteryOptimizationService] isIgnoringBatteryOptimizations error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Request the user to grant "Unrestricted / Not Optimized" battery status via
  /// the official Android system dialog (Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[BatteryOptimizationService] requestIgnoreBatteryOptimizations error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Open system battery optimization list fallback.
  Future<bool> openBatteryOptimizationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>('openBatteryOptimizationSettings');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[BatteryOptimizationService] openBatteryOptimizationSettings error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Query device manufacturer and OS profile.
  Future<DeviceHardwareProfile> getHardwareProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    if (kIsWeb || !Platform.isAndroid) {
      _cachedProfile = const DeviceHardwareProfile(
        manufacturer: 'generic',
        model: 'generic',
        sdkVersion: 0,
      );
      return _cachedProfile!;
    }

    try {
      final manufacturer = await _channel.invokeMethod<String>('getDeviceManufacturer') ?? 'generic';
      final model = await _channel.invokeMethod<String>('getDeviceModel') ?? 'generic';
      final sdkVersion = await _channel.invokeMethod<int>('getAndroidVersion') ?? 0;

      _cachedProfile = DeviceHardwareProfile(
        manufacturer: manufacturer.toLowerCase().trim(),
        model: model,
        sdkVersion: sdkVersion,
      );
      return _cachedProfile!;
    } catch (_) {
      _cachedProfile = const DeviceHardwareProfile(
        manufacturer: 'generic',
        model: 'generic',
        sdkVersion: 0,
      );
      return _cachedProfile!;
    }
  }

  /// Retrieve curated OEM brand advice tailored to the active device hardware.
  Future<BrandReliabilityAdvice> getBrandAdvice() async {
    final profile = await getHardwareProfile();
    final m = profile.manufacturer;

    if (m.contains('oneplus') || m.contains('oppo') || m.contains('realme')) {
      return const BrandReliabilityAdvice(
        brandName: 'OnePlus / Oppo (OxygenOS / ColorOS)',
        title: 'OxygenOS Background Optimization Guide',
        isAggressiveOem: true,
        steps: [
          'Set Battery Usage to "Unrestricted" or "Don\'t optimize".',
          'Enable "Allow background activity" in App info > Battery.',
          'Enable "Auto-launch" if available on your OxygenOS version.',
        ],
        lockInRecentsTip:
          'Open your Recent Apps screen, tap the three dots above Modulix, and select "Lock" to prevent OxygenOS from clearing the session when you tap Clear All.',
      );
    }

    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return const BrandReliabilityAdvice(
        brandName: 'Xiaomi / Poco (MIUI / HyperOS)',
        title: 'HyperOS / MIUI Background Saver Guide',
        isAggressiveOem: true,
        steps: [
          'Set Battery Saver to "No restrictions" in App info > Battery saver.',
          'Enable "Autostart" in App info > Permissions to ensure session alarms fire.',
        ],
        lockInRecentsTip:
          'In Recent Apps, pull down on Modulix and tap the padlock icon to prevent memory cleaner daemons from stopping active focus audio.',
      );
    }

    if (m.contains('samsung')) {
      return const BrandReliabilityAdvice(
        brandName: 'Samsung (One UI)',
        title: 'One UI Background Usage Limits Guide',
        isAggressiveOem: true,
        steps: [
          'Open Settings > Battery > Background usage limits.',
          'Verify Modulix is not listed in "Sleeping apps" or "Deep sleeping apps".',
          'Add Modulix to "Never sleeping apps".',
          'In App info > Battery, select "Unrestricted".',
        ],
        lockInRecentsTip:
          'In the Recent Apps screen, tap the Modulix icon and choose "Keep open" to lock it in RAM.',
      );
    }

    if (m.contains('vivo') || m.contains('iqoo')) {
      return const BrandReliabilityAdvice(
        brandName: 'Vivo / iQOO (Funtouch OS)',
        title: 'Funtouch OS High Background Consumption Guide',
        isAggressiveOem: true,
        steps: [
          'Open Settings > Battery > High background power consumption.',
          'Toggle Modulix ON to allow continuous deep work sessions.',
          'In App info > Permissions, allow Autostart.',
        ],
        lockInRecentsTip:
          'Slide down on the Modulix card in the multitasking tray to activate the lock icon.',
      );
    }

    // Google Pixel / Motorola / Stock Android fallback
    return const BrandReliabilityAdvice(
      brandName: 'Stock Android / Google Pixel',
      title: 'Standard Android Battery Optimization',
      isAggressiveOem: false,
      steps: [
        'Open App info > App battery usage.',
        'Change setting from "Optimized" to "Unrestricted".',
      ],
      lockInRecentsTip: null,
    );
  }
}

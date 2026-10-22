import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Function signature for custom socket/DNS ping probing (allows unit test injection)
typedef ConnectivityProbe = Future<bool> Function();

/// Service providing network health probing and exponential jitter backoff
/// designed specifically for hospital Wi-Fi, captive portals, and flaky mobile connections.
class NetworkResilienceService {
  static NetworkResilienceService? _instance;
  static NetworkResilienceService get instance =>
      _instance ??= NetworkResilienceService._();

  NetworkResilienceService._();

  @visibleForTesting
  static set testInstance(NetworkResilienceService? service) =>
      _instance = service;

  ConnectivityProbe? customProbe;
  final Random _random = Random();

  /// Probes whether the device has actual outbound internet connectivity to cloud endpoints.
  /// Standard OS connectivity checks often return true on captive portals or basement Wi-Fi
  /// even when packets are silently dropped.
  Future<bool> checkConnectivity({
    Duration timeout = const Duration(seconds: 3),
    String host = 'supabase.co',
  }) async {
    if (customProbe != null) {
      try {
        return await customProbe!();
      } catch (_) {
        return false;
      }
    }

    try {
      final results = await InternetAddress.lookup(host).timeout(timeout);
      if (results.isNotEmpty && results.first.rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      debugPrint('[NetworkResilienceService] Connectivity probe failed: $e');
      return false;
    }
  }

  /// Calculates exponential backoff duration with randomized jitter
  /// to prevent thundering herd when returning to Wi-Fi range.
  Duration calculateBackoff(
    int attempt, {
    int baseSeconds = 2,
    int maxSeconds = 60,
  }) {
    if (attempt <= 0) return Duration.zero;
    final exp = min(attempt - 1, 6);
    final calculatedSecs = min(baseSeconds * pow(2, exp).toInt(), maxSeconds);
    // Add randomized jitter up to 500ms
    final jitterMs = _random.nextInt(500);
    return Duration(seconds: calculatedSecs, milliseconds: jitterMs);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

import '../models/punch_capture.dart';

class PunchContextException implements Exception {
  final String message;
  PunchContextException(this.message);

  @override
  String toString() => message;
}

/// Collects GPS, Wi-Fi identity, and public IP for a verified punch.
class PunchContextService {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<PunchCapture> collect({required String facePhotoUrl}) async {
    if (facePhotoUrl.trim().isEmpty) {
      throw PunchContextException('A live face photo is required to punch.');
    }

    final results = await Future.wait([
      _readPosition(),
      _readWifi(),
      _readPublicIp(),
    ]);

    final position = results[0] as Position;
    final wifi = results[1] as _WifiSnapshot;
    final publicIp = results[2] as String;

    return PunchCapture(
      facePhotoUrl: facePhotoUrl,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      wifiSsid: wifi.ssid,
      wifiBssid: wifi.bssid,
      ipAddress: publicIp,
      localIp: wifi.localIp,
      platform: _platformLabel(),
      capturedAt: DateTime.now(),
    );
  }

  Future<Position> _readPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw PunchContextException(
        'Turn on GPS/location services, then try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw PunchContextException(
        'Location permission is required for an accurate punch.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw PunchContextException(
        'Location is blocked for this app. Enable it in system settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw PunchContextException(
        'Could not lock GPS in time. Move near a window and try again.',
      );
    } catch (e) {
      throw PunchContextException('Could not read GPS: $e');
    }
  }

  Future<_WifiSnapshot> _readWifi() async {
    try {
      final ssid = _cleanWifi(await _networkInfo.getWifiName());
      final bssid = _cleanWifi(await _networkInfo.getWifiBSSID());
      final localIp = (await _networkInfo.getWifiIP())?.trim() ?? '';
      return _WifiSnapshot(ssid: ssid, bssid: bssid, localIp: localIp);
    } catch (e) {
      debugPrint('[PunchContext] Wi-Fi read skipped: $e');
      return const _WifiSnapshot();
    }
  }

  Future<String> _readPublicIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      debugPrint('[PunchContext] Public IP skipped: $e');
    }
    return '';
  }

  String _cleanWifi(String? value) {
    if (value == null) return '';
    return value.replaceAll('"', '').trim();
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}

class _WifiSnapshot {
  final String ssid;
  final String bssid;
  final String localIp;

  const _WifiSnapshot({
    this.ssid = '',
    this.bssid = '',
    this.localIp = '',
  });
}

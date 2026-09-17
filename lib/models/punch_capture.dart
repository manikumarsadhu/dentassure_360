import 'package:cloud_firestore/cloud_firestore.dart';

/// Proof captured at clock-in or clock-out: face, GPS, and network identity.
class PunchCapture {
  final String facePhotoUrl;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String wifiSsid;
  final String wifiBssid;
  final String ipAddress;
  final String localIp;
  final String platform;
  final DateTime capturedAt;

  const PunchCapture({
    required this.facePhotoUrl,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.wifiSsid = '',
    this.wifiBssid = '',
    this.ipAddress = '',
    this.localIp = '',
    this.platform = '',
    required this.capturedAt,
  });

  bool get hasFace => facePhotoUrl.trim().isNotEmpty;
  bool get hasGps => latitude != null && longitude != null;
  bool get hasWifi => wifiSsid.isNotEmpty || wifiBssid.isNotEmpty;
  bool get isComplete => hasFace && hasGps;

  String get gpsLabel {
    if (!hasGps) return 'Location unavailable';
    final acc = accuracyMeters != null
        ? ' · ±${accuracyMeters!.round()} m'
        : '';
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}$acc';
  }

  String get wifiLabel {
    if (wifiSsid.isNotEmpty) return wifiSsid;
    if (wifiBssid.isNotEmpty) return wifiBssid;
    return 'Wi-Fi not detected';
  }

  String get networkLabel {
    final parts = <String>[];
    if (hasWifi) parts.add(wifiLabel);
    if (ipAddress.isNotEmpty) parts.add('IP $ipAddress');
    if (localIp.isNotEmpty && localIp != ipAddress) {
      parts.add('LAN $localIp');
    }
    return parts.isEmpty ? 'Network not detected' : parts.join(' · ');
  }

  String get mapsQuery {
    if (!hasGps) return '';
    return '${latitude!},${longitude!}';
  }

  Map<String, dynamic> toMap() {
    return {
      'facePhotoUrl': facePhotoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'wifiSsid': wifiSsid,
      'wifiBssid': wifiBssid,
      'ipAddress': ipAddress,
      'localIp': localIp,
      'platform': platform,
      'capturedAt': Timestamp.fromDate(capturedAt),
    };
  }

  factory PunchCapture.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return PunchCapture(facePhotoUrl: '', capturedAt: DateTime.fromMillisecondsSinceEpoch(0));
    }

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PunchCapture(
      facePhotoUrl: (map['facePhotoUrl'] ?? '').toString(),
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      accuracyMeters: parseDouble(map['accuracyMeters']),
      wifiSsid: (map['wifiSsid'] ?? '').toString(),
      wifiBssid: (map['wifiBssid'] ?? '').toString(),
      ipAddress: (map['ipAddress'] ?? '').toString(),
      localIp: (map['localIp'] ?? '').toString(),
      platform: (map['platform'] ?? '').toString(),
      capturedAt: parseDate(map['capturedAt']),
    );
  }

  static PunchCapture? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is PunchCapture) return value;
    if (value is Map<String, dynamic>) return PunchCapture.fromMap(value);
    if (value is Map) {
      return PunchCapture.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }
}

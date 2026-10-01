import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'rider_api_service.dart';
import 'storage_service.dart';

class LocationTrackerService {
  static StreamSubscription<Position>? _positionStream;
  static String? _activeOrderId;
  static const String _sharingPrefKey = 'rider_location_sharing_enabled';

  static Future<bool> getLocationSharingEnabled() async {
    final val = StorageService.getBool(_sharingPrefKey);
    return val ?? true;
  }

  static Future<bool> setLocationSharingEnabled(bool enabled) async {
    await StorageService.setBool(_sharingPrefKey, enabled);
    if (!enabled) {
      stopTracking(true);
    }
    return true;
  }

  static bool shouldTrackStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == 'accepted' ||
        s == 'processing' ||
        s == 'bill_approved' ||
        s == 'picked' ||
        s == 'out_for_delivery';
  }

  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  static void startTracking(String orderDocId) async {
    _activeOrderId = orderDocId;
    if (_positionStream != null) return;

    final hasPerm = await requestPermission();
    if (!hasPerm) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, 
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_activeOrderId != null) {
        RiderApiService.updateOrderLocation(
          _activeOrderId!,
          position.latitude,
          position.longitude,
        ).catchError((_) {});
      }
    });
  }

  static void stopTracking([bool force = false]) {
    if (force || _activeOrderId == null) {
      _positionStream?.cancel();
      _positionStream = null;
      _activeOrderId = null;
    }
  }
}

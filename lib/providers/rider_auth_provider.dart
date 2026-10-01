import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rider_user_model.dart';
import '../models/notification_model.dart';
import '../services/storage_service.dart';
import '../services/rider_api_service.dart';
import '../constants/app_constants.dart';

class RiderAuthProvider extends ChangeNotifier {
  RiderUserModel? _rider;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  bool _isShiftActive = false;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _lastUpdatedAt;
  StreamSubscription? _banListener;

  RiderUserModel? get rider => _rider;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isShiftActive => _isShiftActive;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get lastUpdatedAt => _lastUpdatedAt;

  RiderAuthProvider() {
    _initAuth();
  }

  void setLastUpdatedAt(String val) {
    _lastUpdatedAt = val;
    notifyListeners();
  }

  Future<void> _initAuth() async {
    await StorageService.init();
    final savedUser = StorageService.getObject(AppConstants.keyUserInfo);
    final isAuth = StorageService.getBool(AppConstants.keyIsAuthenticated) ?? false;
    final savedShift = StorageService.getObject(AppConstants.keyShiftStatus);

    if (savedUser is Map<String, dynamic>) {
      _rider = RiderUserModel.fromMap(savedUser);
    }
    _isAuthenticated = isAuth;
    if (savedShift is Map && savedShift['active'] is bool) {
      _isShiftActive = savedShift['active'];
    }

    _isLoading = false;
    notifyListeners();

  
    if (_isAuthenticated) {
      _verifyProfileAndShift();
    }
  }

  Future<void> _verifyProfileAndShift() async {
    try {
      final me = await RiderApiService.getMe();
      if (me['data'] is Map<String, dynamic>) {
        _rider = RiderUserModel.fromMap(me['data']);
        await StorageService.setObject(AppConstants.keyUserInfo, me['data']);
      }
      await refreshShiftStatus();
      await refreshNotifications();
      _listenForBan();
    } catch (_) {}
    notifyListeners();
  }

  void _listenForBan() {
    _banListener?.cancel();
    final uid = _rider?.id ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _banListener = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data();
        final isBanned = data?['isBanned'] == true || data?['is_banned'] == true || data?['status'] == 'banned';
        if (isBanned) {
          logout();
        }
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await RiderApiService.login(email, password);
      if (res['success'] == true && res['user'] is Map<String, dynamic>) {
        _rider = RiderUserModel.fromMap(res['user']);
        _isAuthenticated = true;
        _isLoading = false;
        await refreshShiftStatus();
        await refreshNotifications();
        _listenForBan();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _banListener?.cancel();
    _isAuthenticated = false;
    _rider = null;
    _isShiftActive = false;
    _notifications = [];
    _unreadCount = 0;
    await RiderApiService.logout();
    notifyListeners();
  }

  Future<void> setRider(RiderUserModel updated) async {
    _rider = updated;
    await StorageService.setObject(AppConstants.keyUserInfo, updated.toMap());
    notifyListeners();
  }

  Future<void> refreshShiftStatus() async {
    try {
      final shift = await RiderApiService.getCurrentShift();
      _isShiftActive = shift != null && shift.active;
      await StorageService.setObject(AppConstants.keyShiftStatus, {'active': _isShiftActive});
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleShift() async {
    final next = !_isShiftActive;
    try {
      await RiderApiService.toggleShift(next);
      _isShiftActive = next;
      await StorageService.setObject(AppConstants.keyShiftStatus, {'active': next});
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshNotifications() async {
    try {
      _notifications = await RiderApiService.getNotifications();
      _unreadCount = _notifications.where((n) => !n.read).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadNotifications() => refreshNotifications();

  Future<void> markAllNotificationsRead() async {
    await RiderApiService.markAllNotificationsRead();
    await loadNotifications();
  }

  @override
  void dispose() {
    _banListener?.cancel();
    super.dispose();
  }
}

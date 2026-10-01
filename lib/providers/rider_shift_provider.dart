import 'dart:async';
import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../services/rider_api_service.dart';

class RiderShiftProvider extends ChangeNotifier {
  ShiftModel? _currentShift;
  List<ShiftModel> _shiftHistory = [];
  Timer? _tickerTimer;
  String _activeDurationFormatted = '0m';
  bool _isLoading = false;

  ShiftModel? get currentShift => _currentShift;
  List<ShiftModel> get shiftHistory => _shiftHistory;
  String get activeDurationFormatted => _activeDurationFormatted;
  bool get isLoading => _isLoading;

  RiderShiftProvider() {
    _startTimer();
  }

  void _startTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDurationDisplay();
    });
  }

  void _updateDurationDisplay() {
    if (_currentShift == null || !_currentShift!.active || _currentShift!.startTime.isEmpty) {
      if (_activeDurationFormatted != '0m') {
        _activeDurationFormatted = '0m';
        notifyListeners();
      }
      return;
    }

    try {
      final start = DateTime.parse(_currentShift!.startTime);
      final diff = DateTime.now().difference(start);
      final minutes = diff.inMinutes;
      final hours = minutes ~/ 60;
      final remMin = minutes % 60;

      final formatted = hours > 0 ? '${hours}h ${remMin}m' : '${remMin}m';
      if (_activeDurationFormatted != formatted) {
        _activeDurationFormatted = formatted;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadCurrentShift() async {
    try {
      _currentShift = await RiderApiService.getCurrentShift();
      _updateDurationDisplay();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadShiftHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _shiftHistory = await RiderApiService.getMyShifts();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/rider_api_service.dart';
import '../constants/order_status.dart';

class RiderOrdersProvider extends ChangeNotifier {
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _myOrders = [];
  bool _isLoading = false;
  String _selectedTab = 'available'; 

  List<OrderModel> get availableOrders => _availableOrders;
  List<OrderModel> get myOrders => _myOrders;
  bool get isLoading => _isLoading;
  String get selectedTab => _selectedTab;

  List<OrderModel> get activeOrders =>
      _myOrders.where((o) => OrderStatusConstants.isActive(o.status)).toList();

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final futures = await Future.wait([
        RiderApiService.getAvailableOrders(),
        RiderApiService.getMyOrders(),
      ]);
      _availableOrders = futures[0];
      _myOrders = futures[1];
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<OrderModel> acceptOrder(String orderDocId) async {
    final updated = await RiderApiService.acceptOrder(orderDocId);
    await fetchOrders();
    return updated;
  }

  Future<OrderModel> updateStatus(
    String orderDocId,
    String nextStatus, {
    String? notes,
    int? estimatedDuration,
  }) async {
    final updated = await RiderApiService.updateOrderStatus(
      orderDocId,
      nextStatus,
      notes: notes,
      estimatedDuration: estimatedDuration,
    );
    await fetchOrders();
    return updated;
  }

  Future<void> declineOrder(String orderDocId, String reason) async {
    await RiderApiService.declineOrCancelOrder(orderDocId, reason);
    await fetchOrders();
  }
}


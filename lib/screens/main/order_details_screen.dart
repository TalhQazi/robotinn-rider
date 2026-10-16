import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/themed_alert.dart';
import '../../components/order/eta_modal.dart';
import '../../components/order/bill_image_preview_modal.dart';
import '../../constants/order_status.dart';
import '../../models/order_model.dart';
import '../../services/rider_api_service.dart';
import '../../services/location_tracker_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _setupOrderListener();
    _checkLocationTracking();
  }

  void _setupOrderListener() {
    _orderSubscription?.cancel();
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(_currentOrder.id)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        setState(() {
          _currentOrder = OrderModel.fromFirestore(snap);
        });
        _checkLocationTracking();
      }
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _checkLocationTracking() {
    if (LocationTrackerService.shouldTrackStatus(_currentOrder.status)) {
      LocationTrackerService.startTracking(_currentOrder.id);
    } else if (_currentOrder.status == OrderStatusConstants.delivered ||
        _currentOrder.status == OrderStatusConstants.cancelled) {
      LocationTrackerService.stopTracking(true);
    }
  }

  Future<void> _refreshOrder() async {
    try {
      final updated = await RiderApiService.getOrderById(_currentOrder.id);
      if (mounted) {
        setState(() => _currentOrder = updated);
        _checkLocationTracking();
      }
    } catch (_) {}
  }

  void _handleAcceptPress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EtaModal(
        onCancel: () => Navigator.pop(ctx),
        onSubmit: (mins) async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          try {
            await RiderApiService.acceptOrder(_currentOrder.id);
            final updated = await RiderApiService.updateOrderStatus(
              _currentOrder.id,
              OrderStatusConstants.shopping,
              estimatedDuration: mins,
            );
            LocationTrackerService.startTracking(_currentOrder.id);
            setState(() => _currentOrder = updated);

            if (mounted) {
              ThemedAlert.show(
                context,
                title: 'Order Started',
                message: 'Customer can now track your live location. Estimated arrival: $mins minutes.',
                buttons: [
                  AlertActionItem(
                    text: 'Open Chat',
                    onPress: () => _openChat(),
                  ),
                  AlertActionItem(text: 'OK', isCancel: true),
                ],
              );
            }
          } catch (e) {
            if (mounted) {
              ThemedAlert.show(context, title: 'Error', message: 'Could not accept order: $e');
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _handleStatusUpdate(String nextStatus, String prompt) {
    ThemedAlert.show(
      context,
      title: 'Confirm',
      message: prompt,
      buttons: [
        AlertActionItem(text: 'No', isCancel: true),
        AlertActionItem(
          text: 'Yes',
          onPress: () async {
            setState(() => _isLoading = true);
            try {
              final updated = await RiderApiService.updateOrderStatus(_currentOrder.id, nextStatus);
              setState(() => _currentOrder = updated);
              _checkLocationTracking();
            } catch (e) {
              if (mounted) {
                ThemedAlert.show(context, title: 'Error', message: e.toString());
              }
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
        ),
      ],
    );
  }

  void _handleCancelPress() {
    ThemedAlert.show(
      context,
      title: 'Decline / Unassign Order',
      message: 'Select a reason for declining this order. The order will be returned to the available queue for another rider to claim.',
      buttons: [
        AlertActionItem(
          text: 'Item not available at store',
          onPress: () => _cancelWithReason('Item not available at store'),
        ),
        AlertActionItem(
          text: 'Customer unreachable',
          onPress: () => _cancelWithReason('Customer not responding'),
        ),
        AlertActionItem(
          text: 'Wrong address / Store closed',
          onPress: () => _cancelWithReason('Wrong address or store closed'),
        ),
        AlertActionItem(
          text: 'Decline / Unable to deliver',
          isDestructive: true,
          onPress: () => _cancelWithReason('Rider unable to deliver'),
        ),
        AlertActionItem(text: 'Keep Order', isCancel: true),
      ],
    );
  }

  void _cancelWithReason(String reason) async {
    setState(() => _isLoading = true);
    try {
      await RiderApiService.declineOrCancelOrder(
        _currentOrder.id,
        reason,
      );
      LocationTrackerService.stopTracking(true);
      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Order Unassigned',
          message: 'You have declined this order. It has been returned to the available queue for another rider.',
          buttons: [
            AlertActionItem(
              text: 'OK',
              onPress: () {
                Navigator.of(context).pop(); // close alert
                Navigator.of(context).pop(); // pop order details screen
              },
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Error', message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat() async {
    if (_currentOrder.customerId.isEmpty) {
      ThemedAlert.show(context, title: 'Chat', message: 'Customer information not available.');
      return;
    }
    try {
      final convId = await RiderApiService.startConversation(
        _currentOrder.customerId,
        _currentOrder.orderId,
        _currentOrder.customerName,
      );
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/chat',
          arguments: {
            'conversationId': convId,
            'title': _currentOrder.customerName,
            'participantId': _currentOrder.customerId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Chat Error', message: e.toString());
      }
    }
  }

  void _callCustomer() async {
    if (_currentOrder.customerPhone.isNotEmpty) {
      final uri = Uri.parse('tel:${_currentOrder.customerPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      Navigator.of(context).pushNamed(
        '/calling',
        arguments: {'name': _currentOrder.customerName, 'phone': _currentOrder.customerPhone},
      );
    }
  }

  void _openMap() async {
    final query = Uri.encodeComponent(_currentOrder.dropoff);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;
    final status = OrderStatusConstants.normalize(order.status);
    final statusColor = OrderStatusConstants.getColor(order.status);
    final statusLabel = OrderStatusConstants.getLabel(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${order.orderId.isNotEmpty ? order.orderId : order.id.substring(0, 6)}'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(OrderStatusConstants.getIcon(order.status), color: statusColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: $statusLabel',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: statusColor),
                        ),
                        Text(
                          order.createdAt.isNotEmpty ? 'Placed on ${order.createdAt.split('T').first}' : '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            
            _cardContainer(
              title: 'Customer Information',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if (order.customerPhone.isNotEmpty)
                            Text(order.customerPhone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                            onPressed: _openChat,
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                            onPressed: _callCustomer,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.secondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.dropoff.isNotEmpty ? order.dropoff : 'Address not provided',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.directions, color: AppColors.primary),
                        onPressed: _openMap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            
            _cardContainer(
              title: 'Store & Items (${order.items.length})',
              icon: Icons.storefront_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Store: ${order.pickup}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ...order.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('• ${it.name} (x${it.quantity})', style: const TextStyle(fontSize: 13)),
                          ),
                          if (it.store != null)
                            Text(it.store!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

           
            if (order.bill != null || order.billAttachments.isNotEmpty)
              _cardContainer(
                title: 'Store Bill & Receipts',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Product Price:'),
                        Text('Rs. ${order.bill?.productPrice.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Rider Fee:'),
                        Text('Rs. ${order.bill?.shippingFee.toStringAsFixed(0) ?? '0'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bill Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Rs. ${order.bill?.total.toStringAsFixed(0) ?? order.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primary)),
                      ],
                    ),
                    if (order.billAttachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Receipt Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.billAttachments.length,
                          itemBuilder: (ctx, i) {
                            final att = order.billAttachments[i];
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => BillImagePreviewModal(imageUrl: att.fileUrl),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.lightGray),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BillImagePreviewModal.buildThumbnail(
                                    att.fileUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),

            
            _buildActionButtons(status),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _cardContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (status == OrderStatusConstants.pending) {
      return Column(
        children: [
          CustomButton(
            text: 'Accept Order',
            icon: Icons.check,
            onPressed: _handleAcceptPress,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Cancel / Decline',
            isOutlined: true,
            textColor: AppColors.error,
            backgroundColor: AppColors.error,
            onPressed: _handleCancelPress,
          ),
        ],
      );
    }

    if (status == OrderStatusConstants.accepted) {
      return Column(
        children: [
          CustomButton(
            text: 'Start Shopping at Store',
            icon: Icons.store,
            onPressed: () => _handleStatusUpdate(OrderStatusConstants.shopping, 'Start shopping at the store now?'),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Contact Customer',
            isOutlined: true,
            icon: Icons.chat_bubble_outline,
            onPressed: _openChat,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Cancel Order',
            isOutlined: true,
            textColor: AppColors.error,
            backgroundColor: AppColors.error,
            onPressed: _handleCancelPress,
          ),
        ],
      );
    }

    if (status == OrderStatusConstants.shopping) {
      return Column(
        children: [
          CustomButton(
            text: 'Upload Store Bill & Receipts',
            icon: Icons.camera_alt,
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                '/active_order',
                arguments: {'order': _currentOrder},
              );
              _refreshOrder();
            },
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Contact Customer',
            isOutlined: true,
            icon: Icons.chat_bubble_outline,
            onPressed: _openChat,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Cancel Order',
            isOutlined: true,
            textColor: AppColors.error,
            backgroundColor: AppColors.error,
            onPressed: _handleCancelPress,
          ),
        ],
      );
    }

    if (status == OrderStatusConstants.billSubmitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_top, color: AppColors.warning, size: 36),
            SizedBox(height: 8),
            Text(
              'Awaiting Admin Approval',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Admin will verify your bill receipt. Once approved, you can proceed to delivery.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (status == OrderStatusConstants.billRejected) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentOrder.bill?.notes.isNotEmpty == true
                        ? _currentOrder.bill!.notes
                        : 'Admin rejected this bill. Please re-capture a clear receipt.',
                    style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Resubmit Store Bill',
            icon: Icons.refresh,
            backgroundColor: AppColors.primary,
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                '/active_order',
                arguments: {'order': _currentOrder},
              );
              _refreshOrder();
            },
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Contact Customer',
            isOutlined: true,
            icon: Icons.chat_bubble_outline,
            onPressed: _openChat,
          ),
        ],
      );
    }

    if (status == OrderStatusConstants.adjustmentPending) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Column(
          children: [
            const Icon(Icons.hourglass_bottom_rounded, color: Color(0xFFEA580C), size: 36),
            const SizedBox(height: 8),
            const Text(
              'Awaiting Customer Bill Approval',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF9A3412)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Admin sent the verified bill to the customer. Waiting for customer approval before you head out for delivery.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Contact Customer',
              isOutlined: true,
              icon: Icons.chat_bubble_outline,
              onPressed: _openChat,
            ),
          ],
        ),
      );
    }

    if (status == OrderStatusConstants.billApproved) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.success.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '✅ Bill Approved by Customer! Proceed to deliver.',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          CustomButton(
            text: 'Out for Delivery',
            icon: Icons.delivery_dining,
            backgroundColor: AppColors.primary,
            onPressed: () => _handleStatusUpdate(OrderStatusConstants.outForDelivery, 'Leaving store for customer now?'),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Open Maps Navigation',
            isOutlined: true,
            icon: Icons.navigation,
            onPressed: _openMap,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Contact Customer',
            isOutlined: true,
            icon: Icons.phone,
            onPressed: _callCustomer,
          ),
        ],
      );
    }

    if (status == OrderStatusConstants.outForDelivery) {
      return Column(
        children: [
          CustomButton(
            text: 'Mark as Delivered',
            icon: Icons.check_circle,
            backgroundColor: AppColors.success,
            onPressed: () => _handleStatusUpdate(OrderStatusConstants.delivered, 'Mark this order as successfully delivered?'),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Open Maps Navigation',
            isOutlined: true,
            icon: Icons.navigation,
            onPressed: _openMap,
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Contact Customer',
            isOutlined: true,
            icon: Icons.phone,
            onPressed: _callCustomer,
          ),
        ],
      );
    }

    if (status == OrderStatusConstants.delivered) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text(
              'Order Delivered Successfully',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

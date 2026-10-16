import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/rider_header.dart';
import '../../constants/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/rider_auth_provider.dart';
import '../../providers/rider_orders_provider.dart';
import '../../components/order/eta_modal.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedSubFilter = 'all'; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderOrdersProvider>().fetchOrders();
    });
  }

  void _showEtaModal(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EtaModal(
        onCancel: () => Navigator.pop(ctx),
        onSubmit: (mins) async {
          Navigator.pop(ctx);
          try {
            final updated = await context.read<RiderOrdersProvider>().acceptOrder(order.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Order #${order.orderId} accepted! Estimated: $mins mins')),
              );
              Navigator.of(context).pushNamed(
                '/order_details',
                arguments: {'order': updated},
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to accept: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RiderOrdersProvider>();
    final auth = context.watch<RiderAuthProvider>();
    final isShiftActive = auth.isShiftActive;
    final isAvailableTab = prov.selectedTab == 'available';

    List<OrderModel> displayList = isAvailableTab ? prov.availableOrders : prov.myOrders;

    if (!isAvailableTab) {
      if (_selectedSubFilter == 'active') {
        displayList = displayList.where((o) => OrderStatusConstants.isActive(o.status)).toList();
      } else if (_selectedSubFilter == 'delivered') {
        displayList = displayList.where((o) => o.status == OrderStatusConstants.delivered).toList();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RiderHeader(
        title: 'Orders',
        showAvatar: true,
      ),
      body: Column(
        children: [
          // Shift offline alert banner (1:1 with React Native)
          if (!isShiftActive && isAvailableTab)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Turn on your shift from the Dashboard to see new orders in your assigned area.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown[800],
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Tabs matching React Native: "New in area" & "My deliveries"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: _segmentButton(
                    title: 'New in area',
                    isSelected: isAvailableTab,
                    onTap: () => prov.setSelectedTab('available'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _segmentButton(
                    title: 'My deliveries',
                    isSelected: !isAvailableTab,
                    onTap: () => prov.setSelectedTab('my'),
                  ),
                ),
              ],
            ),
          ),

          if (!isAvailableTab)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Active (${prov.activeOrders.length})', 'active'),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Delivered (${prov.myOrders.where((o) => o.status == OrderStatusConstants.delivered).length})',
                      'delivered',
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => prov.fetchOrders(),
              color: AppColors.primary,
              child: prov.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : displayList.isEmpty
                      ? _emptyState(isAvailableTab, isShiftActive)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            return _orderCard(displayList[index], isAvailableTab);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedSubFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isAvailable, bool isShiftActive) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.inbox_outlined, size: 64, color: AppColors.gray.withOpacity(0.5)),
        const SizedBox(height: 16),
        const Text(
          'No orders found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          isAvailable
              ? (isShiftActive
                  ? 'No open orders in your area right now.'
                  : 'Start your shift on the Dashboard.')
              : 'You have no assigned orders yet.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _orderCard(OrderModel order, bool isAvailable) {
    final statusColor = OrderStatusConstants.getColor(order.status);
    final statusLabel = OrderStatusConstants.getLabel(order.status);
    final statusIcon = OrderStatusConstants.getIcon(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        onTap: () {
          Navigator.of(context).pushNamed(
            '/order_details',
            arguments: {'order': order},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      'Order #${order.orderId.isNotEmpty ? order.orderId : order.id.substring(0, 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup: ${order.pickup}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deliver to: ${order.dropoff.isNotEmpty ? order.dropoff : 'Customer Address'}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} item(s)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Rs. ${(order.bill?.total ?? order.total).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (isAvailable)
                    ElevatedButton.icon(
                      onPressed: () => _showEtaModal(order),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Claim Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),

              // Active Delivery Buttons
              if (!isAvailable) ...[
                const SizedBox(height: 12),
                _buildActiveOrderActionButton(order),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/order_details',
                        arguments: {'order': order},
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.primary),
                    label: const Text(
                      'View Details & Instructions',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderActionButton(OrderModel order) {
    final normStatus = OrderStatusConstants.normalize(order.status);

    // 1. Bill Submitted -> Awaiting Admin Approval
    if (normStatus == OrderStatusConstants.billSubmitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text(
              'Awaiting Admin Approval',
              style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // 2. Sent to Customer / Waiting for Customer Approval
    if (normStatus == OrderStatusConstants.adjustmentPending ||
        normStatus == 'sent_to_customer' ||
        normStatus == 'customer_approval') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Awaiting Customer Approval',
              style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // 3. Bill Approved -> Ready to Deliver
    if (normStatus == OrderStatusConstants.billApproved || normStatus == 'customer_approved') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed(
              '/order_details',
              arguments: {'order': order},
            );
          },
          icon: const Icon(Icons.delivery_dining, size: 18),
          label: const Text(
            'Bill Approved — Start Delivery',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // 4. Out for Delivery / Picked
    if (normStatus == OrderStatusConstants.outForDelivery) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed(
              '/order_details',
              arguments: {'order': order},
            );
          },
          icon: const Icon(Icons.navigation_outlined, size: 16),
          label: const Text(
            'Out for Delivery — View Order',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // 5. Bill Rejected -> Re-submit
    if (normStatus == OrderStatusConstants.billRejected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final res = await Navigator.of(context).pushNamed(
              '/active_order',
              arguments: {'order': order},
            );
            if (res == true && mounted) {
              context.read<RiderOrdersProvider>().fetchOrders();
            }
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text(
            'Bill Rejected — Re-submit Store Bill',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }

    // 6. Default (Accepted / Shopping) -> Submit Store Bill to Admin
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final res = await Navigator.of(context).pushNamed(
            '/active_order',
            arguments: {'order': order},
          );
          if (res == true && mounted) {
            context.read<RiderOrdersProvider>().fetchOrders();
          }
        },
        icon: const Icon(Icons.camera_alt, size: 16),
        label: const Text(
          'Submit Store Bill to Admin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}


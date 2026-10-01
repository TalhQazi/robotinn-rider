import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/rider_header.dart';
import '../../constants/order_status.dart';
import '../../models/order_model.dart';
import '../../providers/rider_auth_provider.dart';
import '../../providers/rider_orders_provider.dart';
import '../../providers/rider_shift_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _shiftEarnings = 0.0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  void _loadData() async {
    final shiftProv = context.read<RiderShiftProvider>();
    final ordersProv = context.read<RiderOrdersProvider>();
    final authProv = context.read<RiderAuthProvider>();

    await Future.wait([
      shiftProv.loadCurrentShift(),
      ordersProv.fetchOrders(),
      authProv.refreshShiftStatus(),
    ]);

    if (shiftProv.currentShift != null) {
      if (mounted) {
        setState(() {
          _shiftEarnings = shiftProv.currentShift!.earnings;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    _loadData();
    final now = TimeOfDay.now().format(context);
    context.read<RiderAuthProvider>().setLastUpdatedAt(now);
    setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();
    final ordersProv = context.watch<RiderOrdersProvider>();
    final shiftProv = context.watch<RiderShiftProvider>();
    final isOnline = auth.isShiftActive;

    final allMyOrders = ordersProv.myOrders;
    final activeCount = ordersProv.activeOrders.length;
    final deliveredCount = shiftProv.currentShift?.ordersCompleted ??
        allMyOrders.where((o) => o.status == OrderStatusConstants.delivered).length;

    final recentOrders = allMyOrders.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const RiderHeader(
        showLogo: true,
        showAvatar: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? const LinearGradient(colors: [Color(0xFF1A2E35), Color(0xFF2EC4B6)])
                      : const LinearGradient(colors: [AppColors.error, Color(0xFFB71C1C)]),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppColors.primary : AppColors.error).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF4CD964) : const Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isOnline ? const Color(0xFF4CD964) : const Color(0xFFFF3B30)).withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shift Status',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOnline ? 'Online • Accepting Orders' : 'Offline • Not Accepting Orders',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                 
                    GestureDetector(
                      onTap: () async {
                        try {
                          await auth.toggleShift();
                          _loadData();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Shift error: $e')),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.white.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.power_settings_new,
                              size: 16,
                              color: isOnline ? const Color(0xFF4CD964) : AppColors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? 'Shift On' : 'Shift Off',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

             
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Performance Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (auth.lastUpdatedAt != null)
                    Text(
                      'Updated ${auth.lastUpdatedAt}',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray),
                    ),
                ],
              ),
              const SizedBox(height: 12),

            
              Row(
                children: [
                  _statCard(
                    title: 'Total (mine)',
                    value: allMyOrders.length.toString(),
                    icon: Icons.inventory_2_outlined,
                    gradient: AppGradients.primary,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    title: 'Active',
                    value: activeCount.toString(),
                    icon: Icons.local_shipping_outlined,
                    gradient: AppGradients.statYellow,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    title: 'Delivered',
                    value: deliveredCount.toString(),
                    icon: Icons.check_circle_outline,
                    gradient: AppGradients.statOrange,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/earnings'),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppGradients.royal,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This shift (earnings)',
                            style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${_shiftEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF4CD964), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'From your active shift on server',
                                style: TextStyle(color: AppColors.white.withOpacity(0.85), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet, color: AppColors.white, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

            

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                     
                      Navigator.of(context).pushNamed('/orders');
                    },
                    icon: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    label: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (recentOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray.withOpacity(0.6)),
                      const SizedBox(height: 8),
                      const Text(
                        'No recent orders yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: recentOrders.map((order) => _orderItemCard(order)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: AppColors.white.withOpacity(0.9),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderItemCard(OrderModel order) {
    final statusColor = OrderStatusConstants.getColor(order.status);
    final statusLabel = OrderStatusConstants.getLabel(order.status);
    final statusIcon = OrderStatusConstants.getIcon(order.status);
    final isActive = OrderStatusConstants.isActive(order.status);

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
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.dropoff.isNotEmpty ? order.dropoff : 'Address not specified',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rs. ${(order.bill?.total ?? order.total).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      if (isActive)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              '/active_order',
                              arguments: {'order': order},
                            );
                          },
                          icon: const Icon(Icons.camera_alt, size: 14),
                          label: const Text('Upload Bill', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/order_details',
                            arguments: {'order': order},
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('View', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../models/earning_model.dart';
import '../../services/rider_api_service.dart';

class EarningHistoryScreen extends StatefulWidget {
  const EarningHistoryScreen({super.key});

  @override
  State<EarningHistoryScreen> createState() => _EarningHistoryScreenState();
}

class _EarningHistoryScreenState extends State<EarningHistoryScreen> {
  List<EarningItemModel> _earnings = [];
  List<DailyBreakdownModel> _dailyBreakdown = [];
  double _totalDeliveryEarnings = 0.0;
  double _totalBillAmount = 0.0;
  int _totalOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  void _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final res = await RiderApiService.getEarningsHistory();
      if (mounted) {
        setState(() {
          _earnings = res['items'] as List<EarningItemModel>;
          _totalDeliveryEarnings = res['totalDeliveryEarnings'] as double;
          _totalBillAmount = res['totalBillAmount'] as double;
          _totalOrders = res['totalOrders'] as int;
          _dailyBreakdown = res['dailyBreakdown'] as List<DailyBreakdownModel>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earning History'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadEarnings(),
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppGradients.royal,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Rider Earnings',
                            style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rs. ${_totalDeliveryEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _heroMiniStat('Completed Orders', '$_totalOrders'),
                              _heroMiniStat('Total Store Bills', 'Rs. ${_totalBillAmount.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                   
                    if (_dailyBreakdown.isNotEmpty) ...[
                      const Text(
                        'Recent Days Breakdown',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _dailyBreakdown.length,
                          itemBuilder: (ctx, i) {
                            final d = _dailyBreakdown[i];
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(12),
                              width: 110,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                border: Border.all(color: AppColors.lightGray),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(d.dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('${d.orders} orders', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${d.deliveryEarnings.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                   
                    const Text(
                      'Completed Delivery Records',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    if (_earnings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: const Text('No delivered orders yet.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      Column(
                        children: _earnings.map((earn) => _earningCard(earn)).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _heroMiniStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _earningCard(EarningItemModel earn) {
    final dateStr = earn.deliveredAt.isNotEmpty ? earn.deliveredAt.split('T').first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${earn.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(earn.customerName, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(earn.area.isNotEmpty ? earn.area : 'N/A', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Bill', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('Rs. ${earn.billTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Rider Earning', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    '+ Rs. ${earn.shippingFee.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../models/shift_model.dart';
import '../../providers/rider_shift_provider.dart';

class ShiftHistoryScreen extends StatefulWidget {
  const ShiftHistoryScreen({super.key});

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderShiftProvider>().loadShiftHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftProv = context.watch<RiderShiftProvider>();
    final history = shiftProv.shiftHistory;

    int totalMins = 0;
    int totalOrders = 0;
    double totalEarn = 0.0;

    for (var s in history) {
      totalMins += s.durationMinutes;
      totalOrders += s.ordersCompleted;
      totalEarn += s.earnings;
    }

    final totalHours = totalMins ~/ 60;
    final totalRemMins = totalMins % 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shift History'),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: RefreshIndicator(
        onRefresh: () => shiftProv.loadShiftHistory(),
        color: AppColors.primary,
        child: shiftProv.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppGradients.royal,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Shift Performance Summary', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _sumItem('Shifts', history.length.toString()),
                              _divider(),
                              _sumItem('Hours', '${totalHours}h ${totalRemMins}m'),
                              _divider(),
                              _sumItem('Orders', totalOrders.toString()),
                              _divider(),
                              _sumItem('Earned', 'Rs. ${totalEarn.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Past Shifts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    if (history.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: const Text('No past shifts found.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      Column(
                        children: history.map((shift) => _shiftCard(shift)).toList(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sumItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: AppColors.white.withOpacity(0.25));
  }

  Widget _shiftCard(ShiftModel shift) {
    final startStr = shift.startTime.isNotEmpty ? shift.startTime.split('T').first : '';
    final durHours = shift.durationMinutes ~/ 60;
    final durMins = shift.durationMinutes % 60;
    final durLabel = durHours > 0 ? '${durHours}h ${durMins}m' : '${durMins}m';

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
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(startStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: shift.active ? AppColors.success.withOpacity(0.15) : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  shift.active ? 'Active' : 'Completed',
                  style: TextStyle(
                    color: shift.active ? AppColors.success : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
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
                  Text('Duration', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(durLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Orders', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('${shift.ordersCompleted}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Earnings', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${shift.earnings.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
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

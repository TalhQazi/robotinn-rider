import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_text_field.dart';
import '../../components/common/themed_alert.dart';
import '../../components/order/bill_source_picker_modal.dart';
import '../../components/order/bill_image_preview_modal.dart';
import '../../constants/order_status.dart';
import '../../models/order_model.dart';
import 'package:provider/provider.dart';
import '../../providers/rider_orders_provider.dart';
import '../../services/rider_api_service.dart';

class ActiveOrderScreen extends StatefulWidget {
  final OrderModel order;

  const ActiveOrderScreen({super.key, required this.order});

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  final _picker = ImagePicker();
  late List<OrderItemModel> _items;

  final List<File> _receiptFiles = [];
  final List<String> _receiptNotes = [];

  final _amountCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.order.items);
    _amountCtrl.text = widget.order.estimatedPrice > 0 ? widget.order.estimatedPrice.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    _timeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _pickReceipt(int? replaceIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BillSourcePickerModal(
        onCameraSelected: () => _captureReceipt(ImageSource.camera, replaceIndex),
        onGallerySelected: () => _captureReceipt(ImageSource.gallery, replaceIndex),
      ),
    );
  }

  Future<void> _captureReceipt(ImageSource source, int? replaceIndex) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() {
          final file = File(picked.path);
          if (replaceIndex != null && replaceIndex < _receiptFiles.length) {
            _receiptFiles[replaceIndex] = file;
          } else {
            _receiptFiles.add(file);
            _receiptNotes.add('');
          }
        });
      }
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      // Silently return if user denied camera/photo access or cancelled
      if (code.contains('denied') ||
          code.contains('cancel') ||
          msg.contains('denied') ||
          msg.contains('cancel') ||
          msg.contains('not allow')) {
        debugPrint('Receipt capture permission denied or cancelled: ${e.code}');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('denied') ||
          str.contains('cancel') ||
          str.contains('not allow')) {
        debugPrint('Receipt capture cancelled or denied: $e');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not attach receipt image. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeReceipt(int index) {
    setState(() {
      _receiptFiles.removeAt(index);
      if (index < _receiptNotes.length) {
        _receiptNotes.removeAt(index);
      }
    });
  }

  void _previewReceipt(File file) {
    showDialog(
      context: context,
      builder: (ctx) => BillImagePreviewModal(imageFile: file),
    );
  }

  void _handleSubmit() async {
    if (_receiptFiles.isEmpty) {
      ThemedAlert.show(context, title: 'Receipt Required', message: 'You must attach at least one store bill receipt photo.');
      return;
    }

    final billAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (billAmount <= 0) {
      ThemedAlert.show(context, title: 'Invalid Amount', message: 'Please enter a valid bill amount greater than zero.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final shippingFee = double.tryParse(_feeCtrl.text.trim()) ?? 0.0;
      final deliveryTime = int.tryParse(_timeCtrl.text.trim()) ?? 0;

      await RiderApiService.submitStoreBill(
        orderDocId: widget.order.id,
        productPrice: billAmount,
        shippingFee: shippingFee,
        deliveryTime: deliveryTime,
        notes: _notesCtrl.text.trim(),
        receiptFiles: _receiptFiles,
        fileNotes: _receiptNotes,
      );

      if (mounted) {
        context.read<RiderOrdersProvider>().fetchOrders();
        ThemedAlert.show(
          context,
          title: '✅ Submitted to Admin',
          message: 'Your store receipt(s) and bill details have been submitted to Admin for review.',
          buttons: [
            AlertActionItem(
              text: 'OK',
              onPress: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      }
    } catch (err) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Submission Failed', message: err.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final collectedCount = _items.where((i) => i.collected).length;
    final grandTotal = (double.tryParse(_amountCtrl.text) ?? 0.0) + (double.tryParse(_feeCtrl.text) ?? 0.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Active Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '#${order.orderId.isNotEmpty ? order.orderId : order.id.substring(0, 6)}',
              style: const TextStyle(fontSize: 12, color: AppColors.white),
            ),
          ],
        ),
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppGradients.header)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (OrderStatusConstants.normalize(order.status) == OrderStatusConstants.billSubmitted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Store bill was submitted and is currently awaiting Admin approval. You may update items or receipts below if needed.',
                        style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline, 'Customer:', order.customerName),
                  const Divider(height: 16),
                  _infoRow(Icons.storefront_outlined, 'Pickup Store:', order.pickup),
                  const Divider(height: 16),
                  _infoRow(Icons.location_on_outlined, 'Deliver to:', order.dropoff),
                ],
              ),
            ),
            const SizedBox(height: 16),

            
            _sectionContainer(
              title: 'Item Checklist',
              icon: Icons.checklist_rounded,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (collectedCount == _items.length && _items.isNotEmpty)
                      ? AppColors.success
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$collectedCount/${_items.length}',
                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              child: _items.isEmpty
                  ? const Text('No items listed for this order.', style: TextStyle(color: AppColors.textSecondary))
                  : Column(
                      children: _items.map((item) {
                        return CheckboxListTile(
                          value: item.collected,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${item.name} ${item.quantity > 1 ? '(x${item.quantity})' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              decoration: item.collected ? TextDecoration.lineThrough : null,
                              color: item.collected ? AppColors.textSecondary : AppColors.textPrimary,
                              fontWeight: item.collected ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          subtitle: item.store != null ? Text(item.store!, style: const TextStyle(fontSize: 12)) : null,
                          onChanged: (val) {
                            setState(() => item.collected = val ?? false);
                          },
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            
            _sectionContainer(
              title: 'Bill Receipts (${_receiptFiles.length})',
              icon: Icons.receipt_long_outlined,
              trailing: TextButton.icon(
                onPressed: () => _pickReceipt(null),
                icon: const Icon(Icons.add_a_photo_outlined, size: 16, color: AppColors.primary),
                label: const Text('Add Photo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              child: _receiptFiles.isEmpty
                  ? GestureDetector(
                      onTap: () => _pickReceipt(null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withOpacity(0.5), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          color: AppColors.primary.withOpacity(0.04),
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text(
                              'Tap to photograph store receipt',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mandatory before submitting bill to Admin',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(_receiptFiles.length, (idx) {
                        final file = _receiptFiles[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.lightGray),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _previewReceipt(file),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        file,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _previewReceipt(file),
                                      behavior: HitTestBehavior.opaque,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Receipt #${idx + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Tap image to preview',
                                            style: TextStyle(fontSize: 11, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                                    onPressed: () => _pickReceipt(idx),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                    onPressed: () => _removeReceipt(idx),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Notes for this receipt (optional)',
                                  hintStyle: TextStyle(fontSize: 12),
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (val) {
                                  _receiptNotes[idx] = val;
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 16),

          
            _sectionContainer(
              title: 'Payment & Bill Details',
              icon: Icons.payments_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Store Product Amount (Rs.)',
                    hintText: 'Enter actual amount paid at store',
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Rider Fee (Rs.)',
                          hintText: '0',
                          controller: _feeCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Delivery Time (mins)',
                          hintText: 'e.g. 25',
                          controller: _timeCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Notes for Admin',
                    hintText: 'Any extra remarks about items or stores',
                    controller: _notesCtrl,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        'Rs. ${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

          
            CustomButton(
              text: OrderStatusConstants.normalize(order.status) == OrderStatusConstants.billSubmitted
                  ? 'Update Bill & Re-submit to Admin'
                  : 'Submit to Admin',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _sectionContainer({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

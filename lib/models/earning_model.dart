class EarningItemModel {
  final String id;
  final String orderId;
  final String customerName;
  final String area;
  final double productPrice;
  final double shippingFee;
  final double billTotal;
  final int deliveryTime;
  final String deliveredAt;

  EarningItemModel({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.area,
    this.productPrice = 0.0,
    this.shippingFee = 0.0,
    this.billTotal = 0.0,
    this.deliveryTime = 0,
    required this.deliveredAt,
  });

  factory EarningItemModel.fromMap(Map<String, dynamic> map) {
    return EarningItemModel(
      id: map['id']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? 'Customer',
      area: map['area']?.toString() ?? '',
      productPrice: (map['productPrice'] is num) ? (map['productPrice'] as num).toDouble() : 0.0,
      shippingFee: (map['shippingFee'] is num) ? (map['shippingFee'] as num).toDouble() : 0.0,
      billTotal: (map['billTotal'] is num) ? (map['billTotal'] as num).toDouble() : 0.0,
      deliveryTime: (map['deliveryTime'] is num) ? (map['deliveryTime'] as num).toInt() : 0,
      deliveredAt: map['deliveredAt']?.toString() ?? '',
    );
  }
}

class DailyBreakdownModel {
  final String date;
  final String dateLabel;
  final int orders;
  final double deliveryEarnings;
  final double billTotal;

  DailyBreakdownModel({
    required this.date,
    required this.dateLabel,
    required this.orders,
    required this.deliveryEarnings,
    required this.billTotal,
  });
}

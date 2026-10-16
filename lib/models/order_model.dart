import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String id;
  final String name;
  final int quantity;
  final String? store;
  final double price;
  bool collected;

  OrderItemModel({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.store,
    this.price = 0.0,
    this.collected = false,
  });

  factory OrderItemModel.fromMap(dynamic item, int index) {
    if (item is String) {
      return OrderItemModel(
        id: index.toString(),
        name: item,
        quantity: 1,
        collected: false,
      );
    }
    if (item is Map) {
      return OrderItemModel(
        id: item['id']?.toString() ?? index.toString(),
        name: item['name']?.toString() ?? item['text']?.toString() ?? 'Item',
        quantity: (item['quantity'] is num)
            ? (item['quantity'] as num).toInt()
            : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1),
        store: item['store']?.toString() ?? item['selectedStore']?.toString(),
        price: (item['price'] is num)
            ? (item['price'] as num).toDouble()
            : (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0),
        collected: item['collected'] == true,
      );
    }
    return OrderItemModel(id: index.toString(), name: 'Item', quantity: 1);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'store': store,
      'price': price,
      'collected': collected,
    };
  }
}

class BillAttachmentModel {
  final String id;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String uploadTime;
  final String uploadType;
  final String notes;

  BillAttachmentModel({
    required this.id,
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    required this.uploadTime,
    this.uploadType = 'image',
    this.notes = '',
  });

  factory BillAttachmentModel.fromMap(Map<String, dynamic> map) {
    return BillAttachmentModel(
      id: map['id']?.toString() ?? '',
      fileUrl: map['fileUrl']?.toString() ?? map['uri']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? map['name']?.toString() ?? 'Receipt',
      fileSize: (map['fileSize'] is num) ? (map['fileSize'] as num).toInt() : 0,
      uploadTime: map['uploadTime']?.toString() ?? '',
      uploadType: map['uploadType']?.toString() ?? map['type']?.toString() ?? 'image',
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class BillModel {
  final double productPrice;
  final double shippingFee;
  final double amount;
  final double total;
  final int deliveryTime;
  final String receiptImageUrl;
  final String status;
  final List<BillAttachmentModel> attachments;
  final String notes;

  BillModel({
    this.productPrice = 0.0,
    this.shippingFee = 0.0,
    this.amount = 0.0,
    this.total = 0.0,
    this.deliveryTime = 0,
    this.receiptImageUrl = '',
    this.status = 'submitted',
    this.attachments = const [],
    this.notes = '',
  });

  factory BillModel.fromMap(Map<String, dynamic> map) {
    final rawAtts = map['attachments'] as List<dynamic>? ?? [];
    return BillModel(
      productPrice: (map['productPrice'] is num)
          ? (map['productPrice'] as num).toDouble()
          : (double.tryParse(map['productPrice']?.toString() ?? '0') ?? 0.0),
      shippingFee: (map['shippingFee'] is num)
          ? (map['shippingFee'] as num).toDouble()
          : (double.tryParse(map['shippingFee']?.toString() ?? '0') ?? 0.0),
      amount: (map['amount'] is num)
          ? (map['amount'] as num).toDouble()
          : (double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0),
      total: (map['total'] is num)
          ? (map['total'] as num).toDouble()
          : (double.tryParse(map['total']?.toString() ?? '0') ?? 0.0),
      deliveryTime: (map['deliveryTime'] is num)
          ? (map['deliveryTime'] as num).toInt()
          : (int.tryParse(map['deliveryTime']?.toString() ?? '0') ?? 0),
      receiptImageUrl: map['receiptImageUrl']?.toString() ?? '',
      status: map['status']?.toString() ?? 'submitted',
      attachments: rawAtts
          .whereType<Map<String, dynamic>>()
          .map((a) => BillAttachmentModel.fromMap(a))
          .toList(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String orderId;
  final String status;
  final String customerName;
  final String customerId;
  final String customerPhone;
  final String pickup;
  final String dropoff;
  final String area;
  final double total;
  final double estimatedPrice;
  final List<OrderItemModel> items;
  final BillModel? bill;
  final List<BillAttachmentModel> billAttachments;
  final String createdAt;
  final String? riderId;
  final GeoPoint? riderLocation;
  final List<String> rejectedByRiders;
  final String? lastDeclineReason;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.customerName,
    this.customerId = '',
    this.customerPhone = '',
    this.pickup = '',
    this.dropoff = '',
    this.area = '',
    this.total = 0.0,
    this.estimatedPrice = 0.0,
    this.items = const [],
    this.bill,
    this.billAttachments = const [],
    this.createdAt = '',
    this.riderId,
    this.riderLocation,
    this.rejectedByRiders = const [],
    this.lastDeclineReason,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel.fromMap(data, doc.id);
  }

  factory OrderModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final itemsList = <OrderItemModel>[];
    for (int i = 0; i < rawItems.length; i++) {
      itemsList.add(OrderItemModel.fromMap(rawItems[i], i));
    }

    String custName = 'Customer';
    String custId = '';
    String custPhone = '';
    if (data['customer'] is Map) {
      custName = data['customer']['name']?.toString() ?? 'Customer';
      custId = data['customer']['id']?.toString() ?? '';
      custPhone = data['customer']['phone']?.toString() ?? '';
    } else if (data['customerName'] != null) {
      custName = data['customerName'].toString();
      custId = data['customerId']?.toString() ?? '';
    }

    String pickupLocation = data['pickup']?.toString() ?? data['store']?.toString() ?? '';
    if (pickupLocation.isEmpty && itemsList.isNotEmpty && itemsList.first.store != null) {
      pickupLocation = itemsList.first.store!;
    }
    if (pickupLocation.isEmpty) pickupLocation = 'Store';

    
    BillModel? billObj;
    if (data['bill'] is Map<String, dynamic>) {
      billObj = BillModel.fromMap(data['bill']);
    }

    
    final attsList = <BillAttachmentModel>[];
    if (data['billAttachments'] is List && (data['billAttachments'] as List).isNotEmpty) {
      for (var a in (data['billAttachments'] as List)) {
        if (a is Map<String, dynamic>) {
          attsList.add(BillAttachmentModel.fromMap(a));
        }
      }
    }
    if (attsList.isEmpty && billObj != null && billObj.attachments.isNotEmpty) {
      attsList.addAll(billObj.attachments);
    }
    final primaryReceipt = billObj?.receiptImageUrl.isNotEmpty == true
        ? billObj!.receiptImageUrl
        : (data['receiptImageUrl']?.toString() ??
            (data['bill'] is Map ? data['bill']['receiptImageUrl']?.toString() : null) ??
            '');
    if (attsList.isEmpty && primaryReceipt.isNotEmpty) {
      attsList.add(BillAttachmentModel(
        id: 'primary_rec',
        fileUrl: primaryReceipt,
        fileName: 'Store Receipt',
        uploadTime: '',
      ));
    }

    final totalVal = (data['total'] is num)
        ? (data['total'] as num).toDouble()
        : (double.tryParse(data['total']?.toString() ?? '0') ?? 0.0);

    final estVal = (data['estimatedPrice'] is num)
        ? (data['estimatedPrice'] as num).toDouble()
        : ((data['estimatedSubtotal'] is num)
            ? (data['estimatedSubtotal'] as num).toDouble()
            : (double.tryParse(data['estimatedPrice']?.toString() ?? '0') ?? 0.0));

    final rawRejected = data['rejectedByRiders'] as List<dynamic>? ?? [];
    final rejectedList = rawRejected.map((e) => e.toString()).toList();

    return OrderModel(
      id: docId ?? data['id']?.toString() ?? data['_id']?.toString() ?? '',
      orderId: data['orderId']?.toString() ?? docId ?? '',
      status: data['status']?.toString() ?? 'pending',
      customerName: custName,
      customerId: custId,
      customerPhone: custPhone,
      pickup: pickupLocation,
      dropoff: data['dropoff']?.toString() ?? data['deliveryAddress']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      total: totalVal,
      estimatedPrice: estVal > 0 ? estVal : totalVal,
      items: itemsList,
      bill: billObj,
      billAttachments: attsList,
      createdAt: data['createdAt']?.toString() ?? data['date']?.toString() ?? '',
      riderId: (data['rider'] is Map) ? data['rider']['id']?.toString() : data['riderId']?.toString(),
      riderLocation: data['riderLocation'] is GeoPoint ? data['riderLocation'] as GeoPoint : null,
      rejectedByRiders: rejectedList,
      lastDeclineReason: data['lastDeclineReason']?.toString(),
    );
  }
}

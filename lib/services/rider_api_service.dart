import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../constants/order_status.dart';
import '../models/order_model.dart';
import '../models/shift_model.dart';
import '../models/earning_model.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import 'storage_service.dart';

class RiderApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final Map<String, String> _userNameCache = {};


  static int parseTimestamp(dynamic val) {
    if (val == null) return 0;
    if (val is Timestamp) return val.millisecondsSinceEpoch;
    if (val is DateTime) return val.millisecondsSinceEpoch;
    if (val is num) return val > 1e11 ? val.toInt() : (val * 1000).toInt();
    if (val is String) {
      try {
        final d = DateTime.parse(val);
        return d.millisecondsSinceEpoch;
      } catch (_) {}
    }
    return 0;
  }

  static double getRiderDeliveryFee(Map<String, dynamic> order) {
    if (order['bill'] is Map) {
      final sf = double.tryParse(order['bill']['shippingFee']?.toString() ?? '0') ?? 0.0;
      if (sf > 0) return sf;
    }
    final directSf = double.tryParse(order['shippingFee']?.toString() ?? '0') ?? 0.0;
    if (directSf > 0) return directSf;
    final df = double.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0.0;
    if (df > 0) return df;
    return 0.0;
  }


  static const List<String> staticAreas = [
    'F-6', 'F-7', 'F-8', 'F-10', 'F-11',
    'G-6', 'G-7', 'G-8', 'G-9', 'G-10', 'G-11',
    'E-7', 'E-8', 'E-9', 'E-11',
    'I-8', 'I-9', 'I-10',
    'DHA Phase 1', 'DHA Phase 2',
    'Bahria Phase 7', 'Bahria Phase 8',
    'Gulberg Residencia', 'Bani Gala',
  ];

  static Future<List<String>> getAreas() async {
    try {
      final snap = await _firestore.collection('areas').get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs
            .map((doc) => doc.data()['name']?.toString() ?? doc.id)
            .where((s) => s.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return staticAreas;
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String area,
    String vehicleType = 'Motorbike',
    String vehicleNumber = '',
    String? photoNumber,
    String? registrationNumber,
    File? licenseFile,
    File? registrationFile,
    File? bikePhotoFile,
    File? selfieFile,
  }) async {
    UserCredential? credential;
    Map<String, dynamic>? existingProfile;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          credential = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          final existingSnap = await _firestore.collection('users').doc(credential.user!.uid).get();
          if (existingSnap.exists) {
            existingProfile = existingSnap.data();
          }
        } catch (_) {
          throw Exception(
            'This email is already registered with a different password. Please sign in with your existing credentials.',
          );
        }
      } else {
        throw Exception(e.message ?? 'Registration failed.');
      }
    }

    final user = credential.user;
    if (user == null) throw Exception('Registration failed.');

    String licenseUrl = '';
    String registrationUrl = '';
    String bikePhotoUrl = '';
    String selfieUrl = '';

    Future<String> uploadDoc(String path, File file) async {
      try {
        final ref = _storage.ref().child(path);
        await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
        return await ref.getDownloadURL();
      } catch (err) {
        print('Error uploading rider KYC file: $err');
        return '';
      }
    }

    if (licenseFile != null) {
      licenseUrl = await uploadDoc('documents/${user.uid}-license.jpg', licenseFile);
    }
    if (registrationFile != null) {
      registrationUrl = await uploadDoc('documents/${user.uid}-registration.jpg', registrationFile);
    }
    if (bikePhotoFile != null) {
      bikePhotoUrl = await uploadDoc('documents/${user.uid}-bike.jpg', bikePhotoFile);
    }
    if (selfieFile != null) {
      selfieUrl = await uploadDoc('documents/${user.uid}-selfie.jpg', selfieFile);
    }

    final effectiveVehicleNumber = vehicleNumber.isNotEmpty
        ? vehicleNumber
        : (registrationNumber ?? '');

    if (existingProfile != null) {
      final currentTypes = (existingProfile['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [existingProfile['type']?.toString() ?? 'customer'];
      if (!currentTypes.contains('rider')) {
        currentTypes.add('rider');
      }

      final riderFields = {
        'types': currentTypes,
        'type': 'rider',
        'status': 'pending',
        'vehicleType': vehicleType.isNotEmpty ? vehicleType : (existingProfile['vehicleType'] ?? 'Motorbike'),
        'vehicleNumber': effectiveVehicleNumber.isNotEmpty ? effectiveVehicleNumber : (existingProfile['vehicleNumber'] ?? ''),
        'area': area.isNotEmpty ? area : (existingProfile['area'] ?? ''),
        'photoNumber': photoNumber ?? existingProfile['photoNumber'] ?? '',
        'registrationNumber': registrationNumber ?? existingProfile['registrationNumber'] ?? '',
        if (licenseUrl.isNotEmpty) 'licenseImage': licenseUrl,
        if (registrationUrl.isNotEmpty) 'registrationImage': registrationUrl,
        if (bikePhotoUrl.isNotEmpty) 'bikePhoto': bikePhotoUrl,
        if (selfieUrl.isNotEmpty) 'selfie': selfieUrl,
      };

      await _firestore.collection('users').doc(user.uid).update(riderFields);
      final profile = Map<String, dynamic>.from(
        StorageService.sanitizeForJson({...existingProfile, ...riderFields}),
      );

      await _firestore.collection('notifications').add({
        'recipient': 'admin',
        'title': 'New Rider Registered',
        'message': '${name.isNotEmpty ? name : 'A new rider'} has registered and is pending approval.',
        'type': 'rider',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'riderId': user.uid},
      });

      await _auth.signOut();
      await StorageService.remove(AppConstants.keyAuthToken);
      await StorageService.setObject(AppConstants.keyUserInfo, profile);
      await StorageService.setBool(AppConstants.keyIsAuthenticated, false);
      return {'success': true, 'user': profile, 'token': user.uid};
    }

    final profile = {
      'id': user.uid,
      'uid': user.uid,
      'email': email.trim(),
      'name': name.isNotEmpty ? name : 'Rider',
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': effectiveVehicleNumber,
      'licenseImage': licenseUrl,
      'registrationImage': registrationUrl,
      'bikePhoto': bikePhotoUrl,
      'selfie': selfieUrl,
      'photoNumber': photoNumber ?? '',
      'registrationNumber': registrationNumber ?? '',
      'area': area,
      'type': 'rider',
      'types': ['rider'],
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _firestore.collection('users').doc(user.uid).set(profile);

    await _firestore.collection('notifications').add({
      'recipient': 'admin',
      'title': 'New Rider Registered',
      'message': '$name has registered and is pending approval.',
      'type': 'rider',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
      'data': {'riderId': user.uid},
    });

    await _auth.signOut();
    await StorageService.remove(AppConstants.keyAuthToken);
    await StorageService.setObject(AppConstants.keyUserInfo, profile);
    await StorageService.setBool(AppConstants.keyIsAuthenticated, false);
    return {'success': true, 'user': profile, 'token': user.uid};
  }

  static Future<Map<String, dynamic>> checkEmailBanStatus(String email) async {
    if (email.isEmpty) return {'isBanned': false, 'banReason': ''};
    try {
      final clean = email.trim().toLowerCase();
      
      final ridersSnap = await _firestore.collection('riders').where('email', isEqualTo: clean).get();
      for (var doc in ridersSnap.docs) {
        final d = doc.data();
        if (d['isBanned'] == true || d['is_banned'] == true || d['status'] == 'banned') {
          return {
            'isBanned': true,
            'banReason': d['banReason'] ?? d['ban_reason'] ?? 'Your rider account has been suspended by an administrator.',
          };
        }
      }

      final usersSnap = await _firestore.collection('users').where('email', isEqualTo: clean).get();
      for (var doc in usersSnap.docs) {
        final d = doc.data();
        if (d['isBanned'] == true || d['is_banned'] == true || d['status'] == 'banned') {
          return {
            'isBanned': true,
            'banReason': d['banReason'] ?? d['ban_reason'] ?? 'Your rider account has been suspended by an administrator.',
          };
        }
      }
    } catch (_) {}
    return {'isBanned': false, 'banReason': ''};
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cred = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    final user = cred.user;
    if (user == null) throw Exception('Login failed.');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    Map<String, dynamic> profile;

    if (!userDoc.exists) {
      final defaultProfile = {
        'id': user.uid,
        'uid': user.uid,
        'email': user.email ?? cleanEmail,
        'name': 'Rider',
        'phone': '',
        'vehicleType': '',
        'vehicleNumber': '',
        'type': 'rider',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _firestore.collection('users').doc(user.uid).set(defaultProfile);
      profile = defaultProfile;
    } else {
      profile = userDoc.data()!;
    }

  
    bool isBanned = profile['isBanned'] == true || profile['is_banned'] == true || profile['status'] == 'banned';
    String reason = profile['banReason'] ?? profile['ban_reason'] ?? '';

    if (!isBanned) {
      final banCheck = await checkEmailBanStatus(user.email ?? cleanEmail);
      if (banCheck['isBanned'] == true) {
        isBanned = true;
        reason = banCheck['banReason'];
      }
    }

    if (isBanned) {
      await _auth.signOut();
      await StorageService.remove(AppConstants.keyAuthToken);
      await StorageService.remove(AppConstants.keyUserInfo);
      throw Exception('BANNED:${reason.isNotEmpty ? reason : 'Your rider account has been suspended by an administrator.'}');
    }

    
    final currentTypes = (profile['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [profile['type']?.toString() ?? 'rider'];
    if (!currentTypes.contains('rider')) {
      currentTypes.add('rider');
      await _firestore.collection('users').doc(user.uid).update({
        'types': currentTypes,
        'type': 'rider',
        'status': profile['status'] ?? 'pending',
      });
    }
    profile['type'] = 'rider';
    profile['types'] = currentTypes;

    final safeProfile = Map<String, dynamic>.from(
      StorageService.sanitizeForJson(profile),
    );

    await StorageService.setString(AppConstants.keyAuthToken, user.uid);
    await StorageService.setObject(AppConstants.keyUserInfo, safeProfile);
    await StorageService.setBool(AppConstants.keyIsAuthenticated, true);

    return {'success': true, 'token': user.uid, 'user': safeProfile};
  }

  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await StorageService.remove(AppConstants.keyAuthToken);
    await StorageService.remove(AppConstants.keyUserInfo);
    await StorageService.setBool(AppConstants.keyIsAuthenticated, false);
    await StorageService.setObject(AppConstants.keyShiftStatus, {'active': false});
  }

  static Future<Map<String, dynamic>> getMe() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) throw Exception('User not found');
    final rawProfile = snap.data()!;
    final profile = Map<String, dynamic>.from(
      StorageService.sanitizeForJson(rawProfile),
    );

    final currentTypes = (profile['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [profile['type']?.toString() ?? 'rider'];
    if (currentTypes.contains('rider')) {
      profile['type'] = 'rider';
    }
    profile['types'] = currentTypes;

    return {'success': true, 'data': profile, 'user': profile};
  }

  static Future<void> sendOTPCode(String email) async {
    final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    await _firestore.collection('otps').doc(email.trim()).set({
      'email': email.trim(),
      'code': code,
      'createdAt': DateTime.now().toIso8601String(),
    });

    try {
      await http.post(
        Uri.parse('https://formsubmit.co/ajax/${email.trim()}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': 'RobotInn Password Reset',
          'message': 'Your password reset verification code is: $code. Please enter this code in the app to reset your password.',
          '_subject': 'RobotInn Password Reset Verification Code',
        }),
      );
    } catch (e) {
      print('OTP Email warning: $e');
    }
  }

  static Future<void> verifyOTP(String email, String code) async {
    final snap = await _firestore.collection('otps').doc(email.trim()).get();
    if (!snap.exists) throw Exception('Verification code has not been sent or has expired.');
    final data = snap.data()!;
    if (data['code']?.toString().trim() != code.trim()) {
      throw Exception('Invalid verification code.');
    }
    final created = DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now();
    if (DateTime.now().difference(created).inMinutes > 15) {
      throw Exception('Verification code has expired. Please request a new one.');
    }
  }

  static Future<void> verifyOTPAndResetPassword(String email, String code) async {
    await verifyOTP(email, code);
    await _auth.sendPasswordResetEmail(email: email.trim());
    await _firestore.collection('otps').doc(email.trim()).delete();
  }

  static Future<List<OrderModel>> getAvailableOrders() async {
    final user = _auth.currentUser;
    final snap = await _firestore.collection('orders').where('status', isEqualTo: 'pending').get();
    final list = snap.docs
        .map((d) => OrderModel.fromFirestore(d))
        .where((o) => user == null || !o.rejectedByRiders.contains(user.uid))
        .toList();
    list.sort((a, b) => parseTimestamp(b.createdAt).compareTo(parseTimestamp(a.createdAt)));
    return list;
  }

  static Future<List<OrderModel>> getMyOrders({String status = 'all'}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final snap = await _firestore.collection('orders').where('rider.id', isEqualTo: user.uid).get();
    var list = snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();

    // Do not count cancelled orders in rider's orders
    list = list.where((o) => o.status != OrderStatusConstants.cancelled).toList();

    list.sort((a, b) => parseTimestamp(b.createdAt).compareTo(parseTimestamp(a.createdAt)));

    if (status == 'active') {
      return list.where((o) => OrderStatusConstants.isActive(o.status)).toList();
    }
    return list;
  }

  static Stream<List<OrderModel>> streamAvailableOrders() {
    final user = _auth.currentUser;
    return _firestore.collection('orders').where('status', isEqualTo: 'pending').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => OrderModel.fromFirestore(d))
          .where((o) => user == null || !o.rejectedByRiders.contains(user.uid))
          .toList();
      list.sort((a, b) => parseTimestamp(b.createdAt).compareTo(parseTimestamp(a.createdAt)));
      return list;
    });
  }

  static Stream<List<OrderModel>> streamMyOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore.collection('orders').where('rider.id', isEqualTo: user.uid).snapshots().map((snap) {
      var list = snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
      list = list.where((o) => o.status != OrderStatusConstants.cancelled).toList();
      list.sort((a, b) => parseTimestamp(b.createdAt).compareTo(parseTimestamp(a.createdAt)));
      return list;
    });
  }

  static Future<void> declineOrCancelOrder(String orderDocId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final riderSnap = await _firestore.collection('users').doc(user.uid).get();
    final riderData = riderSnap.data() ?? {};
    final riderName = riderData['name'] ?? 'Rider';

    DocumentReference orderDocRef = _firestore.collection('orders').doc(orderDocId);
    DocumentSnapshot orderSnap = await orderDocRef.get();
    String targetDocId = orderDocId;
    if (!orderSnap.exists) {
      final qSnap = await _firestore.collection('orders').where('orderId', isEqualTo: orderDocId).limit(1).get();
      if (qSnap.docs.isNotEmpty) {
        orderDocRef = qSnap.docs.first.reference;
        orderSnap = qSnap.docs.first;
        targetDocId = qSnap.docs.first.id;
      }
    }

    final orderData = orderSnap.data() as Map<String, dynamic>? ?? {};
    final orderCode = orderData['orderId'] ?? targetDocId;
    final customerId = orderData['customer'] is Map ? orderData['customer']['id']?.toString() : orderData['customerId']?.toString();

    await orderDocRef.update({
      'status': OrderStatusConstants.pending,
      'rider': FieldValue.delete(),
      'riderId': FieldValue.delete(),
      'riderLocation': FieldValue.delete(),
      'rejectedByRiders': FieldValue.arrayUnion([user.uid]),
      'lastDeclineReason': reason,
      'declinedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Notify Admin
    try {
      await _firestore.collection('notifications').add({
        'recipient': 'admin',
        'title': '⚠️ Rider Unassigned Order',
        'message': 'Rider $riderName declined Order #$orderCode ($reason). Order returned to pending queue for other riders.',
        'type': 'order_declined',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'orderId': targetDocId, 'riderId': user.uid, 'reason': reason},
      });
    } catch (_) {}

    // Notify Customer
    if (customerId != null && customerId.isNotEmpty) {
      try {
        await _firestore.collection('notifications').add({
          'userId': customerId,
          'title': '🔄 Finding Another Rider',
          'message': 'Your rider had to unassign ($reason). We are searching for another available rider for Order #$orderCode.',
          'type': 'order',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
          'data': {'orderId': targetDocId},
        });
      } catch (_) {}
    }
  }

  static Future<OrderModel> getOrderById(String orderDocId) async {
    final snap = await _firestore.collection('orders').doc(orderDocId).get();
    if (!snap.exists) throw Exception('Order not found');
    return OrderModel.fromFirestore(snap);
  }

  static Future<OrderModel> acceptOrder(String orderDocId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final riderSnap = await _firestore.collection('users').doc(user.uid).get();
    final riderData = riderSnap.data() ?? {};

    final riderInfo = {
      'id': user.uid,
      'name': riderData['name'] ?? 'Rider',
      'phone': riderData['phone'] ?? '',
    };

    await _firestore.collection('orders').doc(orderDocId).update({
      'status': OrderStatusConstants.accepted,
      'rider': riderInfo,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final orderSnap = await _firestore.collection('orders').doc(orderDocId).get();
    final order = orderSnap.data();

    
    if (order != null && order['customer'] is Map && order['customer']['id'] != null) {
      final customerId = order['customer']['id'].toString();
      final customerName = order['customer']['name']?.toString() ?? 'Customer';
      final riderName = riderInfo['name']?.toString() ?? 'Rider';
      final orderCode = order['orderId'] ?? orderDocId;
      try {
        await _firestore.collection('notifications').add({
          'userId': customerId,
          'title': 'Order Accepted',
          'message': 'Rider $riderName has accepted your order #$orderCode.',
          'type': 'order',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
          'data': {'orderId': orderDocId},
        });
        await startConversation(
          customerId,
          orderCode.toString(),
          customerName,
          riderName,
        );
      } catch (_) {}
    }

    return OrderModel.fromFirestore(orderSnap);
  }

  static Future<OrderModel> updateOrderStatus(
    String orderDocId,
    String nextStatus, {
    String? notes,
    int? estimatedDuration,
  }) async {
    await _firestore.collection('orders').doc(orderDocId).update({
      'status': nextStatus,
      'notes': notes ?? '',
      if (estimatedDuration != null) 'estimatedDuration': estimatedDuration,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final snap = await _firestore.collection('orders').doc(orderDocId).get();
    final order = snap.data();

    if (order != null && order['customer'] is Map && order['customer']['id'] != null) {
      final customerId = order['customer']['id'].toString();
      final orderCode = order['orderId'] ?? orderDocId;
      try {
        await _firestore.collection('notifications').add({
          'userId': customerId,
          'title': 'Order Update: ${OrderStatusConstants.getLabel(nextStatus)}',
          'message': 'Your order #$orderCode is now: ${OrderStatusConstants.getLabel(nextStatus)}.',
          'type': 'order',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
          'data': {'orderId': orderDocId},
        });
      } catch (_) {}
    }

    return OrderModel.fromFirestore(snap);
  }

  static Future<void> updateOrderLocation(String orderDocId, double lat, double lng) async {
    await _firestore.collection('orders').doc(orderDocId).update({
      'riderLocation': GeoPoint(lat, lng),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }


  static Future<Map<String, dynamic>> submitStoreBill({
    required String orderDocId,
    required double productPrice,
    required double shippingFee,
    int deliveryTime = 0,
    String notes = '',
    required List<File> receiptFiles,
    List<String> fileNotes = const [],
  }) async {
    if (receiptFiles.isEmpty) {
      throw Exception('At least one bill receipt photo is required.');
    }

    final user = _auth.currentUser;
    final currentUid = user?.uid ?? '';
    final safeId = orderDocId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final uploadedAttachments = <Map<String, dynamic>>[];

    for (int i = 0; i < receiptFiles.length; i++) {
      final file = receiptFiles[i];
      final attId = 'att_${DateTime.now().millisecondsSinceEpoch}_$i';
      final path = 'receipts/${safeId}_$attId.jpg';

      String fileUrl = '';
      try {
        final bytes = await file.readAsBytes();
        final ref = _storage.ref().child(path);
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        fileUrl = await ref.getDownloadURL();
      } catch (e1) {
        print('Storage primary upload error: $e1');
        try {
          final bytes = await file.readAsBytes();
          final altPath = 'bills/${safeId}_$attId.jpg';
          final ref2 = _storage.ref().child(altPath);
          await ref2.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          fileUrl = await ref2.getDownloadURL();
        } catch (e2) {
          print('Storage alt path upload error: $e2');
          try {
            final bytes = await file.readAsBytes();
            final altStorage = FirebaseStorage.instanceFor(bucket: 'robotin-2a51b.appspot.com');
            final ref3 = altStorage.ref().child(path);
            await ref3.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
            fileUrl = await ref3.getDownloadURL();
          } catch (e3) {
            print('Appspot storage upload error: $e3');
            try {
              final bytes = await file.readAsBytes();
              final base64Str = base64Encode(bytes);
              fileUrl = 'data:image/jpeg;base64,$base64Str';
            } catch (_) {}
          }
        }
      }

      if (fileUrl.isNotEmpty) {
        uploadedAttachments.add({
          'id': attId,
          'orderId': orderDocId,
          'riderId': currentUid,
          'storeId': '',
          'storeName': '',
          'fileUrl': fileUrl,
          'fileName': 'Receipt_${i + 1}.jpg',
          'fileSize': await file.length(),
          'uploadTime': DateTime.now().toIso8601String(),
          'uploadType': 'camera',
          'notes': i < fileNotes.length ? fileNotes[i] : '',
          'status': 'submitted',
        });
      }
    }

    if (uploadedAttachments.isEmpty) {
      throw Exception('Failed to upload bill receipt attachments.');
    }

    final totalAmount = productPrice + shippingFee;
    final primaryReceiptUrl = uploadedAttachments.first['fileUrl'];

    final billMap = {
      'productPrice': productPrice,
      'shippingFee': shippingFee,
      'amount': totalAmount,
      'total': totalAmount,
      'deliveryTime': deliveryTime,
      'notes': notes,
      'receiptImageUrl': primaryReceiptUrl,
      'attachments': uploadedAttachments,
      'attachmentsCount': uploadedAttachments.length,
      'status': 'submitted',
      'submittedAt': DateTime.now().toIso8601String(),
      'submittedBy': currentUid,
    };

    DocumentReference orderDocRef = _firestore.collection('orders').doc(orderDocId);
    DocumentSnapshot orderSnap = await orderDocRef.get();
    String targetDocId = orderDocId;
    if (!orderSnap.exists) {
      final qSnap = await _firestore.collection('orders').where('orderId', isEqualTo: orderDocId).limit(1).get();
      if (qSnap.docs.isNotEmpty) {
        orderDocRef = qSnap.docs.first.reference;
        orderSnap = qSnap.docs.first;
        targetDocId = qSnap.docs.first.id;
      }
    }

    await orderDocRef.update({
      'bill': billMap,
      'billAttachments': uploadedAttachments,
      'status': OrderStatusConstants.billSubmitted,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    try {
      final orderData = orderSnap.data() as Map<String, dynamic>?;
      final orderCode = orderData?['orderId'] ?? targetDocId;
      final riderName = orderData?['rider']?['name'] ?? 'Rider';

      await _firestore.collection('notifications').add({
        'recipient': 'admin',
        'title': 'New Bill Submitted',
        'message': 'Rider $riderName submitted ${uploadedAttachments.length} bill receipt(s) for Order #$orderCode.',
        'type': 'bill',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'orderId': targetDocId, 'count': uploadedAttachments.length},
      });
    } catch (_) {}

    return {
      'success': true,
      'receiptImageUrl': primaryReceiptUrl,
      'total': totalAmount,
      'attachments': uploadedAttachments,
    };
  }


  static Future<void> toggleShift(bool isActive, {double? lat, double? lng}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final geoPoint = (lat != null && lng != null) ? GeoPoint(lat, lng) : null;

    if (isActive) {
      // 1. Prevent duplicate active shifts
      final activeSnap = await _firestore
          .collection('shifts')
          .where('riderId', isEqualTo: user.uid)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (activeSnap.docs.isNotEmpty) {
        return; // Already in an active shift, do not create duplicate
      }

      final shiftId = 'SHF-${DateTime.now().millisecondsSinceEpoch}';
      final newShift = {
        'id': shiftId,
        'shiftId': shiftId,
        'riderId': user.uid,
        'startTime': DateTime.now().toIso8601String(),
        'startedAt': DateTime.now().toIso8601String(),
        'endTime': null,
        'active': true,
        'startLocation': geoPoint,
        'ordersCompleted': 0,
        'earnings': 0.0,
      };
      await _firestore.collection('shifts').doc(shiftId).set(newShift);
    } else {
      final activeSnap = await _firestore
          .collection('shifts')
          .where('riderId', isEqualTo: user.uid)
          .where('active', isEqualTo: true)
          .get();

      if (activeSnap.docs.isEmpty) return;

      final ordersSnap = await _firestore.collection('orders').where('rider.id', isEqualTo: user.uid).get();

      final batch = _firestore.batch();
      for (var doc in activeSnap.docs) {
        final shiftData = doc.data();
        final shiftStart = parseTimestamp(shiftData['startTime'] ?? shiftData['startedAt']);
        final shiftEnd = DateTime.now().millisecondsSinceEpoch;

        int shiftOrdersCount = 0;
        double shiftEarningsSum = 0;

        for (var oDoc in ordersSnap.docs) {
          final oData = oDoc.data();
          if (oData['status'] == OrderStatusConstants.delivered) {
            final oTime = parseTimestamp(oData['updatedAt'] ?? oData['createdAt']);
            if (oTime > 0 && shiftStart > 0 && oTime >= shiftStart - 60000 && oTime <= shiftEnd + 60000) {
              shiftOrdersCount += 1;
              shiftEarningsSum += getRiderDeliveryFee(oData);
            }
          }
        }

        final durationMs = shiftEnd - shiftStart;
        // If accidental toggle: shift lasted less than 60 seconds AND had 0 completed orders, discard it
        if (durationMs < 60000 && shiftOrdersCount == 0) {
          batch.delete(doc.reference);
        } else {
          batch.update(doc.reference, {
            'active': false,
            'endTime': DateTime.now().toIso8601String(),
            'endedAt': DateTime.now().toIso8601String(),
            'earnings': shiftEarningsSum,
            'ordersCompleted': shiftOrdersCount,
            'endLocation': geoPoint,
            'duration': durationMs > 0 ? (durationMs ~/ 60000) : 0,
          });
        }
      }
      await batch.commit();
    }
  }

  static Future<ShiftModel?> getCurrentShift() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _firestore
        .collection('shifts')
        .where('riderId', isEqualTo: user.uid)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final shiftData = doc.data();
    final shiftStart = parseTimestamp(shiftData['startTime'] ?? shiftData['startedAt']);

    final ordersSnap = await _firestore.collection('orders').where('rider.id', isEqualTo: user.uid).get();

    int shiftOrdersCount = 0;
    double shiftEarningsSum = 0;

    for (var oDoc in ordersSnap.docs) {
      final o = oDoc.data();
      if (o['status'] == OrderStatusConstants.delivered) {
        final oTime = parseTimestamp(o['updatedAt'] ?? o['createdAt']);
        if (oTime > 0 && shiftStart > 0 && oTime >= shiftStart - 60000) {
          shiftOrdersCount += 1;
          shiftEarningsSum += getRiderDeliveryFee(o);
        }
      }
    }

    final merged = {
      ...shiftData,
      'ordersCompleted': shiftOrdersCount,
      'earnings': shiftEarningsSum,
    };
    return ShiftModel.fromMap(merged, doc.id);
  }

  static Future<List<ShiftModel>> getMyShifts() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _firestore.collection('shifts').where('riderId', isEqualTo: user.uid).get();
    final list = <ShiftModel>[];
    final batch = _firestore.batch();
    bool hasDeletes = false;

    for (var doc in snap.docs) {
      final s = ShiftModel.fromFirestore(doc);
      // Clean up past accidental dummy shifts (completed with 0 orders and 0 duration)
      if (!s.active && s.durationMinutes == 0 && s.ordersCompleted == 0 && s.earnings == 0) {
        batch.delete(doc.reference);
        hasDeletes = true;
        continue;
      }
      list.add(s);
    }

    if (hasDeletes) {
      batch.commit().catchError((_) {});
    }

    list.sort((a, b) => parseTimestamp(b.startTime).compareTo(parseTimestamp(a.startTime)));
    return list;
  }

 
  static Future<Map<String, dynamic>> getEarningsHistory() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final ordersSnap = await _firestore.collection('orders').where('rider.id', isEqualTo: user.uid).get();

    final List<EarningItemModel> earningsList = [];
    double totalDeliveryEarnings = 0.0;
    double totalBillAmount = 0.0;
    final Map<String, Map<String, dynamic>> dailyMap = {};

    for (var doc in ordersSnap.docs) {
      final order = doc.data();
      final status = order['status']?.toString().toLowerCase();
      if (status == 'delivered' || status == 'completed') {
        final rawProductPrice = double.tryParse(order['bill']?['productPrice']?.toString() ?? '0') ?? 0.0;
        final rawShippingFee = getRiderDeliveryFee(order);
        final rawBillTotal = double.tryParse(order['bill']?['total']?.toString() ?? order['total']?.toString() ?? '0') ?? (rawProductPrice + rawShippingFee);

        final dateStr = order['updatedAt']?.toString() ?? order['createdAt']?.toString() ?? DateTime.now().toIso8601String();

        earningsList.add(EarningItemModel(
          id: doc.id,
          orderId: order['orderId']?.toString() ?? doc.id.substring(0, 6),
          customerName: order['customer']?['name']?.toString() ?? 'Customer',
          area: order['area']?.toString() ?? 'N/A',
          productPrice: rawProductPrice,
          shippingFee: rawShippingFee,
          billTotal: rawBillTotal,
          deliveryTime: int.tryParse(order['bill']?['deliveryTime']?.toString() ?? '0') ?? 0,
          deliveredAt: dateStr,
        ));

        totalDeliveryEarnings += rawShippingFee;
        totalBillAmount += rawBillTotal;

        final dateObj = DateTime.tryParse(dateStr) ?? DateTime.now();
        final dayKey = dateObj.toIso8601String().split('T').first;

        if (!dailyMap.containsKey(dayKey)) {
          dailyMap[dayKey] = {
            'orders': 0,
            'deliveryEarnings': 0.0,
            'billTotal': 0.0,
            'dateLabel': '${dateObj.month}/${dateObj.day}',
          };
        }
        dailyMap[dayKey]!['orders'] = (dailyMap[dayKey]!['orders'] as int) + 1;
        dailyMap[dayKey]!['deliveryEarnings'] = (dailyMap[dayKey]!['deliveryEarnings'] as double) + rawShippingFee;
        dailyMap[dayKey]!['billTotal'] = (dailyMap[dayKey]!['billTotal'] as double) + rawBillTotal;
      }
    }

    earningsList.sort((a, b) => parseTimestamp(b.deliveredAt).compareTo(parseTimestamp(a.deliveredAt)));

    final dailyBreakdown = dailyMap.entries.map((e) {
      return DailyBreakdownModel(
        date: e.key,
        dateLabel: e.value['dateLabel'],
        orders: e.value['orders'],
        deliveryEarnings: e.value['deliveryEarnings'],
        billTotal: e.value['billTotal'],
      );
    }).toList();

    return {
      'items': earningsList,
      'totalDeliveryEarnings': totalDeliveryEarnings,
      'totalBillAmount': totalBillAmount,
      'totalOrders': earningsList.length,
      'dailyBreakdown': dailyBreakdown,
    };
  }


  static String generateRiderSupportReply(String userText) {
    final q = userText.toLowerCase();
    if (q.contains('shift') || q.contains('start') || q.contains('online')) {
      return 'To start your shift: Go to the Dashboard and toggle the "Shift On" switch. Make sure location is enabled.';
    }
    if (q.contains('earning') || q.contains('money') || q.contains('pay')) {
      return 'Earnings are calculated from completed deliveries. View shift earnings on Dashboard, or full history in Profile > Earning History.';
    }
    if (q.contains('profile') || q.contains('edit')) {
      return 'To update your profile: Go to Profile > Settings > Edit Profile.';
    }
    if (q.contains('help') || q.contains('support') || q.contains('issue')) {
      return 'Urgent helpline: +92 300 9876543. Or reply here and support will review shortly!';
    }
    return 'Thank you for reaching out to Rider Support. I have logged your message. A Support Admin will reply shortly.';
  }

  static Future<List<ConversationModel>> getConversations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _firestore.collection('conversations').where('participants', arrayContains: user.uid).get();
    final list = <ConversationModel>[];

    for (var doc in snap.docs) {
      final data = doc.data();
      var conv = ConversationModel.fromMap(data, user.uid, doc.id);

      if ((conv.participantName == 'Customer' || conv.participantName.isEmpty) &&
          conv.participantId.isNotEmpty &&
          conv.participantId != 'support_admin') {
        String? resolved = _userNameCache[conv.participantId];

        if (resolved == null || resolved.isEmpty) {
          // 1. Try resolving from orders collection by orderId if available
          if (conv.orderId != null && conv.orderId!.isNotEmpty) {
            try {
              DocumentSnapshot? orderDoc;
              final directSnap = await _firestore.collection('orders').doc(conv.orderId!).get();
              if (directSnap.exists) {
                orderDoc = directSnap;
              } else {
                final q = await _firestore.collection('orders').where('orderId', isEqualTo: conv.orderId).limit(1).get();
                if (q.docs.isNotEmpty) {
                  orderDoc = q.docs.first;
                }
              }
              if (orderDoc != null && orderDoc.exists) {
                final od = orderDoc.data() as Map<String, dynamic>? ?? {};
                final cName = od['customer']?['name']?.toString() ?? od['customerName']?.toString();
                if (cName != null && cName.trim().isNotEmpty && cName.trim() != 'Customer') {
                  resolved = cName.trim();
                }
              }
            } catch (_) {}
          }

          // 2. Try resolving from users collection
          if (resolved == null || resolved.isEmpty) {
            try {
              final userDoc = await _firestore.collection('users').doc(conv.participantId).get();
              if (userDoc.exists) {
                final ud = userDoc.data() ?? {};
                final uName = ud['name']?.toString() ?? ud['displayName']?.toString();
                if (uName != null && uName.trim().isNotEmpty && uName.trim() != 'Customer') {
                  resolved = uName.trim();
                }
              }
            } catch (_) {}
          }

          // 3. Try finding any order where this customer placed an order
          if (resolved == null || resolved.isEmpty) {
            try {
              final oSnap = await _firestore.collection('orders')
                  .where('customer.id', isEqualTo: conv.participantId)
                  .limit(1)
                  .get();
              if (oSnap.docs.isNotEmpty) {
                final od = oSnap.docs.first.data();
                final cName = od['customer']?['name']?.toString() ?? od['customerName']?.toString();
                if (cName != null && cName.trim().isNotEmpty && cName.trim() != 'Customer') {
                  resolved = cName.trim();
                }
              }
            } catch (_) {}
          }

          if (resolved != null && resolved.isNotEmpty) {
            _userNameCache[conv.participantId] = resolved;
            doc.reference.update({
              'participantNames.${conv.participantId}': resolved,
            }).catchError((_) {});
          }
        }

        if (resolved != null && resolved.isNotEmpty) {
          conv = ConversationModel(
            id: conv.id,
            participants: conv.participants,
            participantId: conv.participantId,
            participantName: resolved,
            lastMessage: conv.lastMessage,
            lastMessageTime: conv.lastMessageTime,
            orderId: conv.orderId,
          );
        }
      }

      list.add(conv);
    }

    list.sort((a, b) => parseTimestamp(b.lastMessageTime).compareTo(parseTimestamp(a.lastMessageTime)));
    return list;
  }

  static Stream<List<ConversationModel>> streamConversations() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .asyncMap((snap) async {
          final list = <ConversationModel>[];
          for (var doc in snap.docs) {
            final data = doc.data();
            var conv = ConversationModel.fromMap(data, user.uid, doc.id);

            if ((conv.participantName == 'Customer' || conv.participantName.isEmpty) &&
                conv.participantId.isNotEmpty &&
                conv.participantId != 'support_admin') {
              String? resolved = _userNameCache[conv.participantId];

              if (resolved == null || resolved.isEmpty) {
                if (conv.orderId != null && conv.orderId!.isNotEmpty) {
                  try {
                    DocumentSnapshot? orderDoc;
                    final directSnap = await _firestore.collection('orders').doc(conv.orderId!).get();
                    if (directSnap.exists) {
                      orderDoc = directSnap;
                    } else {
                      final q = await _firestore.collection('orders').where('orderId', isEqualTo: conv.orderId).limit(1).get();
                      if (q.docs.isNotEmpty) {
                        orderDoc = q.docs.first;
                      }
                    }
                    if (orderDoc != null && orderDoc.exists) {
                      final od = orderDoc.data() as Map<String, dynamic>? ?? {};
                      final cName = od['customer']?['name']?.toString() ?? od['customerName']?.toString();
                      if (cName != null && cName.trim().isNotEmpty && cName.trim() != 'Customer') {
                        resolved = cName.trim();
                      }
                    }
                  } catch (_) {}
                }

                if (resolved == null || resolved.isEmpty) {
                  try {
                    final userDoc = await _firestore.collection('users').doc(conv.participantId).get();
                    if (userDoc.exists) {
                      final ud = userDoc.data() ?? {};
                      final uName = ud['name']?.toString() ?? ud['displayName']?.toString();
                      if (uName != null && uName.trim().isNotEmpty && uName.trim() != 'Customer') {
                        resolved = uName.trim();
                      }
                    }
                  } catch (_) {}
                }

                if (resolved == null || resolved.isEmpty) {
                  try {
                    final oSnap = await _firestore.collection('orders')
                        .where('customer.id', isEqualTo: conv.participantId)
                        .limit(1)
                        .get();
                    if (oSnap.docs.isNotEmpty) {
                      final od = oSnap.docs.first.data();
                      final cName = od['customer']?['name']?.toString() ?? od['customerName']?.toString();
                      if (cName != null && cName.trim().isNotEmpty && cName.trim() != 'Customer') {
                        resolved = cName.trim();
                      }
                    }
                  } catch (_) {}
                }

                if (resolved != null && resolved.isNotEmpty) {
                  _userNameCache[conv.participantId] = resolved;
                  doc.reference.update({
                    'participantNames.${conv.participantId}': resolved,
                  }).catchError((_) {});
                }
              }

              if (resolved != null && resolved.isNotEmpty) {
                conv = ConversationModel(
                  id: conv.id,
                  participants: conv.participants,
                  participantId: conv.participantId,
                  participantName: resolved,
                  lastMessage: conv.lastMessage,
                  lastMessageTime: conv.lastMessageTime,
                  orderId: conv.orderId,
                );
              }
            }
            list.add(conv);
          }
          list.sort((a, b) => parseTimestamp(b.lastMessageTime).compareTo(parseTimestamp(a.lastMessageTime)));
          return list;
        });
  }

  static Future<String> startConversation(
    String participantId, [
    String? orderId,
    String? participantName,
    String? myName,
  ]) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final snap = await _firestore.collection('conversations').where('participants', arrayContains: user.uid).get();
    for (var doc in snap.docs) {
      final parts = (doc.data()['participants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (parts.contains(participantId)) {
        final updateData = <String, dynamic>{};
        if (participantName != null && participantName.isNotEmpty) {
          updateData['participantNames.$participantId'] = participantName;
        }
        if (myName != null && myName.isNotEmpty) {
          updateData['participantNames.${user.uid}'] = myName;
        }
        if (orderId != null && (doc.data()['orderId'] == null || doc.data()['orderId'] == '')) {
          updateData['orderId'] = orderId;
        }
        if (updateData.isNotEmpty) {
          await doc.reference.update(updateData).catchError((_) {});
        }
        return doc.id;
      }
    }

    final newConv = {
      'participants': [user.uid, participantId],
      'participantNames': {
        user.uid: myName ?? (user.displayName ?? 'Rider'),
        participantId: participantName ?? (participantId == 'support_admin' ? 'RobotInn Support' : 'Customer'),
      },
      'orderId': orderId,
      'createdAt': DateTime.now().toIso8601String(),
      'lastMessage': null,
    };
    final docRef = await _firestore.collection('conversations').add(newConv);
    return docRef.id;
  }

  static Stream<List<ChatMessageModel>> subscribeMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessageModel.fromMap(d.data(), d.id)).toList());
  }

  static Future<void> sendMessage(String conversationId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final msg = {
      'senderId': user.uid,
      'text': text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };

    await _firestore.collection('conversations').doc(conversationId).collection('messages').add(msg);
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': msg,
    });

  
    try {
      final convDoc = await _firestore.collection('conversations').doc(conversationId).get();
      if (convDoc.exists) {
        final participants = (convDoc.data()?['participants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        if (participants.contains('support_admin')) {
          final botReply = generateRiderSupportReply(text);
          Future.delayed(const Duration(seconds: 1), () async {
            final botMsg = {
              'senderId': 'support_admin',
              'text': botReply,
              'createdAt': DateTime.now().toIso8601String(),
              'read': false,
            };
            await _firestore.collection('conversations').doc(conversationId).collection('messages').add(botMsg);
            await _firestore.collection('conversations').doc(conversationId).update({
              'lastMessage': botMsg,
            });
          });
        }
      }
    } catch (_) {}
  }

  static Future<void> sendMediaMessage(String conversationId, File file) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'chat_media/$conversationId/${timestamp}_receipt.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final mediaUrl = await ref.getDownloadURL();

    final msg = {
      'senderId': user.uid,
      'text': '',
      'mediaUrl': mediaUrl,
      'mediaType': 'image/jpeg',
      'mediaName': 'Photo',
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };

    await _firestore.collection('conversations').doc(conversationId).collection('messages').add(msg);
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': {
        'text': '📷 Photo',
        'senderId': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
      },
    });
  }

  
  static Future<List<NotificationModel>> getNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _firestore.collection('notifications').where('userId', isEqualTo: user.uid).get();
    final list = snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => parseTimestamp(b.createdAt).compareTo(parseTimestamp(a.createdAt)));
    return list;
  }

  static Future<void> markNotificationRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'read': true});
  }

  static Future<void> markAllNotificationsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snap = await _firestore.collection('notifications').where('userId', isEqualTo: user.uid).get();
    final batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }


  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Authentication required');
    await _firestore.collection('users').doc(user.uid).update(data);
  }
}

class RiderUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String area;
  final String? profilePic;
  final String? licenseImage;
  final String? registrationImage;
  final String? bikePhoto;
  final String? selfie;
  final String status;
  final double rating;
  final int deliveries;

  RiderUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.vehicleType = '',
    this.vehicleNumber = '',
    this.area = '',
    this.profilePic,
    this.licenseImage,
    this.registrationImage,
    this.bikePhoto,
    this.selfie,
    this.status = 'pending',
    this.rating = 5.0,
    this.deliveries = 0,
  });

  factory RiderUserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return RiderUserModel(
      id: id ?? map['id']?.toString() ?? map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Rider',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      vehicleType: map['vehicleType']?.toString() ?? map['vehicle']?.toString() ?? '',
      vehicleNumber: map['vehicleNumber']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      profilePic: map['profilePic']?.toString() ?? map['avatar']?.toString(),
      licenseImage: map['licenseImage']?.toString(),
      registrationImage: map['registrationImage']?.toString(),
      bikePhoto: map['bikePhoto']?.toString(),
      selfie: map['selfie']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 5.0,
      deliveries: (map['deliveries'] is int)
          ? map['deliveries'] as int
          : (int.tryParse(map['deliveries']?.toString() ?? '0') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'area': area,
      'profilePic': profilePic,
      'licenseImage': licenseImage,
      'registrationImage': registrationImage,
      'bikePhoto': bikePhoto,
      'selfie': selfie,
      'status': status,
      'rating': rating,
      'deliveries': deliveries,
    };
  }

  RiderUserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    String? area,
    String? profilePic,
    String? status,
    double? rating,
    int? deliveries,
  }) {
    return RiderUserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      area: area ?? this.area,
      profilePic: profilePic ?? this.profilePic,
      licenseImage: licenseImage,
      registrationImage: registrationImage,
      bikePhoto: bikePhoto,
      selfie: selfie,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      deliveries: deliveries ?? this.deliveries,
    );
  }
}

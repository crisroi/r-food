import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstname;
  final String lastname;
  final String email;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;

  // Restaurant-specific fields
  final String? restaurantName;
  final String? location;
  final Map<String, String>? operatingHours;
  final bool? trackQuantity;
  final int? maxMenuItems;
  final bool? isOpen;

  // Delivery partner-specific fields
  final String? profileImageUrl;
  final String? studentId;
  final String? idCardImageUrl;
  final String? courseOfStudy;
  final String? year;
  final String? hostelName;
  final String? hostelType;
  final String? blockNumber;
  final String? roomNumber;
  final String? hostelAllocationUrl;
  final bool? isApproved;
  final String? approvalStatus;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final bool? isAvailable;
  final int? currentDeliveries;
  final int? totalDeliveries;
  final double? totalEarnings;
  final double? averageRating;
  final int? totalRatings;
  final double? walletBalance;

  UserModel({
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.createdAt,
    // Restaurant fields
    this.restaurantName,
    this.location,
    this.operatingHours,
    this.trackQuantity,
    this.maxMenuItems,
    this.isOpen,
    // Delivery partner fields
    this.profileImageUrl,
    this.studentId,
    this.idCardImageUrl,
    this.courseOfStudy,
    this.year,
    this.hostelName,
    this.hostelType,
    this.blockNumber,
    this.roomNumber,
    this.hostelAllocationUrl,
    this.isApproved,
    this.approvalStatus,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
    this.isAvailable,
    this.currentDeliveries,
    this.totalDeliveries,
    this.totalEarnings,
    this.averageRating,
    this.totalRatings,
    this.walletBalance,
  });

  // Get full name
  String get fullName => '$firstname $lastname';

  // Get full hostel address for delivery partners
  String? get hostelAddress {
    if (hostelName == null || hostelType == null || blockNumber == null) {
      return null;
    }
    String address = '$hostelName ($hostelType) - Block $blockNumber';
    if (roomNumber != null) {
      address += ' - Room $roomNumber';
    }
    return address;
  }

  // Check if restaurant is currently open based on operating hours
  bool get isCurrentlyOpen {
    if (role != 'restaurant' || operatingHours == null) return false;
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final openTime = operatingHours!['openTime'] ?? '00:00';
    final closeTime = operatingHours!['closeTime'] ?? '23:59';
    
    return currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0;
  }

  // Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Restaurant fields
      restaurantName: data['restaurantName'],
      location: data['location'],
      operatingHours: data['operatingHours'] != null
          ? Map<String, String>.from(data['operatingHours'])
          : null,
      trackQuantity: data['trackQuantity'],
      maxMenuItems: data['maxMenuItems'],
      isOpen: data['isOpen'],
      // Delivery partner fields
      profileImageUrl: data['profileImageUrl'],
      studentId: data['studentId'],
      idCardImageUrl: data['idCardImageUrl'],
      courseOfStudy: data['courseOfStudy'],
      year: data['year'],
      hostelName: data['hostelName'],
      hostelType: data['hostelType'],
      blockNumber: data['blockNumber'],
      roomNumber: data['roomNumber'],
      hostelAllocationUrl: data['hostelAllocationUrl'],
      isApproved: data['isApproved'],
      approvalStatus: data['approvalStatus'],
      rejectionReason: data['rejectionReason'],
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      isAvailable: data['isAvailable'],
      currentDeliveries: data['currentDeliveries'],
      totalDeliveries: data['totalDeliveries'],
      totalEarnings: data['totalEarnings']?.toDouble(),
      averageRating: data['averageRating']?.toDouble(),
      totalRatings: data['totalRatings'],
      walletBalance: data['walletBalance']?.toDouble(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Restaurant-specific fields
    if (restaurantName != null) data['restaurantName'] = restaurantName;
    if (location != null) data['location'] = location;
    if (operatingHours != null) data['operatingHours'] = operatingHours;
    if (trackQuantity != null) data['trackQuantity'] = trackQuantity;
    if (maxMenuItems != null) data['maxMenuItems'] = maxMenuItems;
    if (isOpen != null) data['isOpen'] = isOpen;

    // Delivery partner-specific fields
    if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
    if (studentId != null) data['studentId'] = studentId;
    if (idCardImageUrl != null) data['idCardImageUrl'] = idCardImageUrl;
    if (courseOfStudy != null) data['courseOfStudy'] = courseOfStudy;
    if (year != null) data['year'] = year;
    if (hostelName != null) data['hostelName'] = hostelName;
    if (hostelType != null) data['hostelType'] = hostelType;
    if (blockNumber != null) data['blockNumber'] = blockNumber;
    if (roomNumber != null) data['roomNumber'] = roomNumber;
    if (hostelAllocationUrl != null) {
      data['hostelAllocationUrl'] = hostelAllocationUrl;
    }
    if (isApproved != null) data['isApproved'] = isApproved;
    if (approvalStatus != null) data['approvalStatus'] = approvalStatus;
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    if (approvedBy != null) data['approvedBy'] = approvedBy;
    if (approvedAt != null) data['approvedAt'] = Timestamp.fromDate(approvedAt!);
    if (isAvailable != null) data['isAvailable'] = isAvailable;
    if (currentDeliveries != null) data['currentDeliveries'] = currentDeliveries;
    if (totalDeliveries != null) data['totalDeliveries'] = totalDeliveries;
    if (totalEarnings != null) data['totalEarnings'] = totalEarnings;
    if (averageRating != null) data['averageRating'] = averageRating;
    if (totalRatings != null) data['totalRatings'] = totalRatings;
    if (walletBalance != null) data['walletBalance'] = walletBalance;

    return data;
  }

  // Copy with method for updating fields
  UserModel copyWith({
    String? uid,
    String? firstname,
    String? lastname,
    String? email,
    String? role,
    String? phoneNumber,
    DateTime? createdAt,
    String? restaurantName,
    String? location,
    Map<String, String>? operatingHours,
    bool? trackQuantity,
    int? maxMenuItems,
    bool? isOpen,
    String? profileImageUrl,
    String? studentId,
    String? idCardImageUrl,
    String? courseOfStudy,
    String? year,
    String? hostelName,
    String? hostelType,
    String? blockNumber,
    String? roomNumber,
    String? hostelAllocationUrl,
    bool? isApproved,
    String? approvalStatus,
    String? rejectionReason,
    String? approvedBy,
    DateTime? approvedAt,
    bool? isAvailable,
    int? currentDeliveries,
    int? totalDeliveries,
    double? totalEarnings,
    double? averageRating,
    int? totalRatings,
    double? walletBalance,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      restaurantName: restaurantName ?? this.restaurantName,
      location: location ?? this.location,
      operatingHours: operatingHours ?? this.operatingHours,
      trackQuantity: trackQuantity ?? this.trackQuantity,
      maxMenuItems: maxMenuItems ?? this.maxMenuItems,
      isOpen: isOpen ?? this.isOpen,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      studentId: studentId ?? this.studentId,
      idCardImageUrl: idCardImageUrl ?? this.idCardImageUrl,
      courseOfStudy: courseOfStudy ?? this.courseOfStudy,
      year: year ?? this.year,
      hostelName: hostelName ?? this.hostelName,
      hostelType: hostelType ?? this.hostelType,
      blockNumber: blockNumber ?? this.blockNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      hostelAllocationUrl: hostelAllocationUrl ?? this.hostelAllocationUrl,
      isApproved: isApproved ?? this.isApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      currentDeliveries: currentDeliveries ?? this.currentDeliveries,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      walletBalance: walletBalance ?? this.walletBalance,
    );
  }
}

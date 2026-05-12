class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final int petsCount;
  final int bookingsCount;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.petsCount,
    required this.bookingsCount,
    this.createdAt,
    this.lastLoginAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => AdminUserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: json['role'] as String? ?? 'CLIENTE',
        petsCount: (json['petsCount'] as num?)?.toInt() ?? 0,
        bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        lastLoginAt: DateTime.tryParse(json['lastLoginAt'] as String? ?? ''),
      );
}

class AdminEstabModel {
  final String id;
  final String name;
  final String type;
  final String address;
  final String city;
  final String phone;
  final double rating;
  final int reviewCount;
  final int servicesCount;
  final int bookingsCount;

  AdminEstabModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    required this.servicesCount,
    required this.bookingsCount,
  });

  factory AdminEstabModel.fromJson(Map<String, dynamic> json) {
    final services = json['services'] as List? ?? [];
    return AdminEstabModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Pet Shop',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      servicesCount: (json['servicesCount'] as num?)?.toInt() ?? services.length,
      bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminStatsModel {
  final int totalUsers;
  final int totalEstabs;
  final int totalBookings;
  final double avgRating;
  final int totalReviews;
  final List<MonthBooking> bookingsByMonth;
  final List<ServiceDistribution> serviceDistribution;
  final double avgTicket;
  final double clientRetention;
  final int nps;
  final double monthlyGrowth;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalEstabs,
    required this.totalBookings,
    required this.avgRating,
    required this.totalReviews,
    required this.bookingsByMonth,
    required this.serviceDistribution,
    required this.avgTicket,
    required this.clientRetention,
    required this.nps,
    required this.monthlyGrowth,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final months = (json['bookingsByMonth'] as List? ?? [])
        .map((e) => MonthBooking.fromJson(e as Map<String, dynamic>))
        .toList();
    final services = (json['serviceDistribution'] as List? ?? [])
        .map((e) => ServiceDistribution.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdminStatsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalEstabs: (json['totalEstabs'] as num?)?.toInt() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      bookingsByMonth: months,
      serviceDistribution: services,
      avgTicket: (json['avgTicket'] as num?)?.toDouble() ?? 0,
      clientRetention: (json['clientRetention'] as num?)?.toDouble() ?? 0,
      nps: (json['nps'] as num?)?.toInt() ?? 0,
      monthlyGrowth: (json['monthlyGrowth'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MonthBooking {
  final String month;
  final int count;

  const MonthBooking(this.month, this.count);

  factory MonthBooking.fromJson(Map<String, dynamic> json) => MonthBooking(
        json['month'] as String? ?? '',
        (json['count'] as num?)?.toInt() ?? 0,
      );
}

class ServiceDistribution {
  final String label;
  final double percentage;

  const ServiceDistribution(this.label, this.percentage);

  factory ServiceDistribution.fromJson(Map<String, dynamic> json) =>
      ServiceDistribution(
        json['label'] as String? ?? '',
        (json['percentage'] as num?)?.toDouble() ?? 0,
      );
}

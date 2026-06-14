class EstabStatsModel {
  final double totalRevenue;
  final double monthRevenue;
  final double avgTicket;
  final int totalBookings;
  final int monthBookings;
  final List<MonthRevenue> last6Months;
  final List<ServiceStat> topServices;

  EstabStatsModel({
    required this.totalRevenue,
    required this.monthRevenue,
    required this.avgTicket,
    required this.totalBookings,
    required this.monthBookings,
    required this.last6Months,
    required this.topServices,
  });

  factory EstabStatsModel.fromJson(Map<String, dynamic> json) {
    final months = (json['last6Months'] as List? ?? [])
        .map((e) => MonthRevenue.fromJson(e as Map<String, dynamic>))
        .toList();
    final services = (json['topServices'] as List? ?? [])
        .map((e) => ServiceStat.fromJson(e as Map<String, dynamic>))
        .toList();
    return EstabStatsModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0,
      avgTicket: (json['avgTicket'] as num?)?.toDouble() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      monthBookings: (json['monthBookings'] as num?)?.toInt() ?? 0,
      last6Months: months,
      topServices: services,
    );
  }
}

class MonthRevenue {
  final String month;
  final double value;

  const MonthRevenue(this.month, this.value);

  factory MonthRevenue.fromJson(Map<String, dynamic> json) => MonthRevenue(
        json['month'] as String? ?? '',
        (json['value'] as num?)?.toDouble() ?? 0,
      );
}

class ServiceStat {
  final String name;
  final int count;

  const ServiceStat(this.name, this.count);

  factory ServiceStat.fromJson(Map<String, dynamic> json) => ServiceStat(
        json['name'] as String? ?? '',
        (json['count'] as num?)?.toInt() ?? 0,
      );
}

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String establishmentId;
  final String bookingId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.establishmentId,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? 'Usuário',
        establishmentId: json['establishmentId'] as String? ?? '',
        bookingId: json['bookingId'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'establishmentId': establishmentId,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      };
}

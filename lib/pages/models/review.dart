// lib/pages/models/review.dart

class Review {
  final String userName;
  final String comment;
  final double rating;

  Review({required this.userName, required this.comment, required this.rating});

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'comment': comment,
      'rating': rating,
    };
  }

  static Review fromJson(Map<String, dynamic> json) {
    return Review(
      userName: json['userName'],
      comment: json['comment'],
      rating: json['rating'],
    );
  }
}
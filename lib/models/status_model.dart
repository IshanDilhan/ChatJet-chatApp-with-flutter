class StatusModel {
  final String statusId;
  final String userId;
  final String username;
  final String userProfileUrl;
  final List<String>? statusImageUrls; // List of image URLs
  final List<String>? statusText; // List of status texts
  final DateTime timestamp;
  final bool isViewed;

  StatusModel({
    required this.statusId,
    required this.userId,
    required this.username,
    required this.userProfileUrl,
    this.statusImageUrls,
    this.statusText,
    required this.timestamp,
    this.isViewed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'userId': userId,
      'username': username,
      'userProfileUrl': userProfileUrl,
      'statusImageUrls': statusImageUrls,
      'statusText': statusText,
      'timestamp': timestamp.toIso8601String(),
      'isViewed': isViewed,
    };
  }

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      statusId: map['statusId'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userProfileUrl: map['userProfileUrl'] ?? '',
      statusImageUrls: List<String>.from(map['statusImageUrls'] ?? []),
      statusText: List<String>.from(map['statusText'] ?? []),
      timestamp: DateTime.parse(map['timestamp']),
      isViewed: map['isViewed'] ?? false,
    );
  }
}

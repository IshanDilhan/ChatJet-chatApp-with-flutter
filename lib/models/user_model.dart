class UserModel {
  final String uid;
  final String username;
  final String mobileNumber;
  final String email;
  final String profilePictureURL;
  final String status;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String bio; // Short biography or description of the user
  final String location; // User's location
  final List<String> interests; // List of interests or hobbies
  final List<String> contacts; // List of user's contacts (friend IDs)

  UserModel({
    required this.uid,
    required this.username,
    required this.mobileNumber,
    required this.email,
    required this.profilePictureURL,
    required this.status,
    required this.createdAt,
    required this.lastLogin,
    required this.bio,
    required this.location,
    required this.interests,
    required this.contacts,
  });

  // Convert a UserModel object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'mobileNumber': mobileNumber,
      'email': email,
      'profilePictureURL': profilePictureURL,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'bio': bio,
      'location': location,
      'interests': interests,
      'contacts': contacts,
    };
  }

  // Convert a map from Firestore into a UserModel object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      username: map['username'],
      mobileNumber: map['mobileNumber'],
      email: map['email'],
      profilePictureURL: map['profilePictureURL'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: DateTime.parse(map['lastLogin']),
      bio: map['bio'],
      location: map['location'],
      interests: List<String>.from(map['interests']),
      contacts: List<String>.from(map['contacts']),
    );
  }
}

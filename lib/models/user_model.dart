class UserModel {
  final String name;
  final String email;
  final String role;
  final String? dob;
  final String? fcmToken;
  final String? phone;
  final String? gender;
  final String? bio;
  final String? imageResourceLink;
  final bool isComplete;
  final bool skippedRegistration;
  final int lessonsCount;
  final double earnedMoney;
  final String? teachMode;

  UserModel({
    required this.name,
    required this.email,
    required this.role,
    this.dob,
    this.fcmToken,
    this.phone,
    this.gender,
    this.bio,
    this.imageResourceLink,
    this.isComplete = false,
    this.skippedRegistration = false,
    this.lessonsCount = 0,
    this.earnedMoney = 0,
    this.teachMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'dob': dob,
      'fcmToken': fcmToken,
      'phone': phone,
      'gender': gender,
      'bio': bio,
      'imageResourceLink': imageResourceLink,
      'isComplete': isComplete,
      'skippedRegistration': skippedRegistration,
      'lessonsCount': lessonsCount,
      'earnedMoney': earnedMoney,
      'teachMode': teachMode,
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      dob: map['dob'],
      fcmToken: map['fcmToken'],
      phone: map['phone'],
      gender: map['gender'],
      bio: map['bio'],
      imageResourceLink: map['imageResourceLink'],
      isComplete: map['isComplete'] ?? false,
      skippedRegistration: map['skippedRegistration'] ?? false,
      lessonsCount: map['lessonsCount'] ?? 0,
      earnedMoney: (map['earnedMoney'] ?? 0).toDouble(),
      teachMode: map['teachMode'],
    );
  }
}

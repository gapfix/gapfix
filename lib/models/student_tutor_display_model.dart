class StudentTutorDisplayModel {
  String? uid;
  String? name;
  String? email;
  String? profileImage;
  String? chatId;
  bool isExpanded; // This might be for UI state within the list, not necessarily persisted
  bool canDelete;
  int unreadCount;
  int unreadChatCount;
  int unreadHomeworkCount;

  StudentTutorDisplayModel({
    this.uid,
    this.name,
    this.email,
    this.profileImage,
    this.chatId,
    this.isExpanded = false,
    this.canDelete = false,
    this.unreadCount = 0,
    this.unreadChatCount = 0,
    this.unreadHomeworkCount = 0,
  });

  // Factory constructor to create a StudentTutorDisplayModel from a Map
  factory StudentTutorDisplayModel.fromJson(Map<String, dynamic> json) {
    return StudentTutorDisplayModel(
      uid: json['uid'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      profileImage: json['profileImage'] as String?,
      chatId: json['chatId'] as String?,
      isExpanded: json['isExpanded'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
      unreadChatCount: json['unreadChatCount'] as int? ?? 0,
      unreadHomeworkCount: json['unreadHomeworkCount'] as int? ?? 0,
    );
  }

  // Method to convert a StudentTutorDisplayModel to a Map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'chatId': chatId,
      'isExpanded': isExpanded,
      'canDelete': canDelete,
      'unreadCount': unreadCount,
      'unreadChatCount': unreadChatCount,
      'unreadHomeworkCount': unreadHomeworkCount,
    };
  }
}
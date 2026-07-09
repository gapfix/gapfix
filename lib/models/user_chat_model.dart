class UserChatModel {
  final String id;
  final String name;

  UserChatModel({required this.id, required this.name});

  factory UserChatModel.fromMap(Map<String, dynamic> map) {
    return UserChatModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

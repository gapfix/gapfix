class SubjectPreference {
  final String name;
  final num price;
  final int duration;

  SubjectPreference({
    required this.name,
    required this.price,
    required this.duration,
  });

  factory SubjectPreference.fromMap(Map<dynamic, dynamic> map, String key) {
    return SubjectPreference(
      name: map['name'] ?? key,
      price: map['price'] ?? 0,
      duration: map['duration'] ?? 60,
    );
  }
}

class TutorModel {
  final String id;
  final String name;
  final String bio;
  final String? imageResourceLink;
  final List<SubjectPreference> preferences;

  TutorModel({
    required this.id,
    required this.name,
    required this.bio,
    this.imageResourceLink,
    required this.preferences,
  });

  factory TutorModel.fromMap(String id, Map<dynamic, dynamic> map) {
    String? img = map['imageResourceLink'];
    if (img == null || img.isEmpty) {
      img = map['profilePicture'];
    }

    List<SubjectPreference> prefs = [];
    if (map['preferences'] != null) {
      final prefsData = map['preferences'];
      if (prefsData is Map) {
        prefsData.forEach((key, value) {
          if (value is Map) {
            prefs.add(SubjectPreference.fromMap(value, key.toString()));
          }
        });
      } else if (prefsData is List) {
        for (var i = 0; i < prefsData.length; i++) {
          final value = prefsData[i];
          if (value is Map) {
            prefs.add(SubjectPreference.fromMap(value, i.toString()));
          }
        }
      }
    }

    return TutorModel(
      id: id,
      name: map['name'] ?? 'Unknown Tutor',
      bio: map['bio'] ?? '',
      imageResourceLink: img,
      preferences: prefs,
    );
  }
}

class BookingModel {
  final String id;
  final String tutorId;
  final String studentId;
  final String subject;
  final int timestamp;
  final int duration;
  final String status;
  final bool isFree;
  final bool isPackage;
  final String? packageId;
  final int packageTotalLessons;
  final int? suggestedTimestamp;
  final String? suggestedSourceDay;
  final String? suggestedDestDay;
  final String? suggestedTime;
  final String? suggestionMessage;
  final String? lastSuggestedBy;
  final String? cancellationReason;
  final String? tutorName;
  final String? studentName;

  BookingModel({
    required this.id,
    required this.tutorId,
    required this.studentId,
    required this.subject,
    required this.timestamp,
    required this.duration,
    required this.status,
    this.isFree = false,
    this.isPackage = false,
    this.packageId,
    this.packageTotalLessons = 1,
    this.suggestedTimestamp,
    this.suggestedSourceDay,
    this.suggestedDestDay,
    this.suggestedTime,
    this.suggestionMessage,
    this.lastSuggestedBy,
    this.cancellationReason,
    this.tutorName,
    this.studentName,
  });

  factory BookingModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return BookingModel(
      id: id,
      tutorId: map['tutorId'] ?? '',
      studentId: map['studentId'] ?? '',
      subject: map['subject'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      duration: map['duration'] ?? 60,
      status: map['status'] ?? 'pending',
      isFree: _parseBool(map['isFree'] ?? map['free']),
      isPackage: _parseBool(map['isPackage'] ?? map['package']),
      packageId: map['packageId']?.toString(),
      packageTotalLessons: map['packageTotalLessons'] ?? 1,
      suggestedTimestamp: map['suggestedTimestamp'],
      suggestedSourceDay: map['suggestedSourceDay'],
      suggestedDestDay: map['suggestedDestDay'],
      suggestedTime: map['suggestedTime'],
      suggestionMessage: map['suggestionMessage'],
      lastSuggestedBy: map['lastSuggestedBy'],
      cancellationReason: map['cancellationReason'],
      tutorName: map['tutorName'],
      studentName: map['studentName'],
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

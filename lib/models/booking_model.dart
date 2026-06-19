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
      isFree: map['isFree'] ?? false,
      isPackage: map['isPackage'] ?? false,
      packageId: map['packageId'],
    );
  }
}

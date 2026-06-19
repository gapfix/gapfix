class SubjectModel {
  final String name;
  final double price;
  final String currency;
  final int duration;

  SubjectModel({
    required this.name,
    required this.price,
    required this.currency,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'duration': duration,
    };
  }

  factory SubjectModel.fromMap(Map<dynamic, dynamic> map) {
    return SubjectModel(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      duration: map['duration'] ?? 60,
    );
  }
}

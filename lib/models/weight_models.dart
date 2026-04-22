class WeightEntry {
  final int? id;
  final int petId;
  final String date;
  final double weight;

  WeightEntry({
    this.id,
    required this.petId,
    required this.date,
    required this.weight,
  });

  WeightEntry copyWith({
    int? id,
    int? petId,
    String? date,
    double? weight,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'date': date,
      'weight': weight,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'],
      petId: map['petId'],
      date: map['date'],
      weight: (map['weight'] as num).toDouble(),
    );
  }
}

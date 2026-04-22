class Vaccination {
  final int? id;
  final int petId;
  final String name;
  final String date;
  final String? nextDueDate;
  final String? notes;

  Vaccination({
    this.id,
    required this.petId,
    required this.name,
    required this.date,
    this.nextDueDate,
    this.notes,
  });

  Vaccination copyWith({
    int? id,
    int? petId,
    String? name,
    String? date,
    String? nextDueDate,
    String? notes,
  }) {
    return Vaccination(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      date: date ?? this.date,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'name': name,
      'date': date,
      'nextDueDate': nextDueDate,
      'notes': notes,
    };
  }

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      id: map['id'],
      petId: map['petId'],
      name: map['name'],
      date: map['date'],
      nextDueDate: map['nextDueDate'],
      notes: map['notes'],
    );
  }
}

class Medication {
  final int? id;
  final int petId;
  final String name;
  final String dosage;
  final String frequency;
  final String startDate;
  final String? endDate;
  final String? notes;

  Medication({
    this.id,
    required this.petId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes,
  });

  Medication copyWith({
    int? id,
    int? petId,
    String? name,
    String? dosage,
    String? frequency,
    String? startDate,
    String? endDate,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      petId: map['petId'],
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      notes: map['notes'],
    );
  }
}

class VetVisit {
  final int? id;
  final int petId;
  final String date;
  final String reason;
  final String? diagnosis;
  final String? treatment;
  final double? cost;
  final String? vetName;
  final String? notes;

  VetVisit({
    this.id,
    required this.petId,
    required this.date,
    required this.reason,
    this.diagnosis,
    this.treatment,
    this.cost,
    this.vetName,
    this.notes,
  });

  VetVisit copyWith({
    int? id,
    int? petId,
    String? date,
    String? reason,
    String? diagnosis,
    String? treatment,
    double? cost,
    String? vetName,
    String? notes,
  }) {
    return VetVisit(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      cost: cost ?? this.cost,
      vetName: vetName ?? this.vetName,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'date': date,
      'reason': reason,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'cost': cost,
      'vetName': vetName,
      'notes': notes,
    };
  }

  factory VetVisit.fromMap(Map<String, dynamic> map) {
    return VetVisit(
      id: map['id'],
      petId: map['petId'],
      date: map['date'],
      reason: map['reason'],
      diagnosis: map['diagnosis'],
      treatment: map['treatment'],
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      vetName: map['vetName'],
      notes: map['notes'],
    );
  }
}

class Appointment {
  final int? id;
  final int? petId;
  final String title;
  final String dateTime;
  final String type;
  final String? notes;
  final int? notificationId;

  Appointment({
    this.id,
    this.petId,
    required this.title,
    required this.dateTime,
    required this.type,
    this.notes,
    this.notificationId,
  });

  Appointment copyWith({
    int? id,
    int? petId,
    String? title,
    String? dateTime,
    String? type,
    String? notes,
    int? notificationId,
  }) {
    return Appointment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'dateTime': dateTime,
      'type': type,
      'notes': notes,
      'notificationId': notificationId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      petId: map['petId'],
      title: map['title'],
      dateTime: map['dateTime'],
      type: map['type'],
      notes: map['notes'],
      notificationId: map['notificationId'],
    );
  }
}

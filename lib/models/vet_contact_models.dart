class VetContact {
  final int? id;
  final String name;
  final String phone;
  final String? address;
  final String? email;
  final String? notes;

  VetContact({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.email,
    this.notes,
  });

  VetContact copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? email,
    String? notes,
  }) {
    return VetContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'notes': notes,
    };
  }

  factory VetContact.fromMap(Map<String, dynamic> map) {
    return VetContact(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      email: map['email'],
      notes: map['notes'],
    );
  }
}

class Pet {
  final int id; 
  final String name;
  final String species;
  final String breed;
  final String birthdate;
  final String gender;
  final double weight;
  final String? photoPath; 

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthdate,
    required this.gender,
    required this.weight,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'birthdate': birthdate,
      'gender': gender,
      'weight': weight,
      'photoPath': photoPath,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      breed: map['breed'],
      birthdate: map['birthdate'],
      gender: map['gender'],
      weight: map['weight'],
      photoPath: map['photoPath'],
    );
  }
}

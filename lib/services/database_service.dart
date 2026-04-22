import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pet_models.dart';
import '../models/health_models.dart';
import '../models/weight_models.dart';
import '../models/note_models.dart';
import '../models/appointment_models.dart';
import '../models/vet_contact_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mypet.db');

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTablesV1(db);
        await _createTablesV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTablesV2(db);
        }
      },
    );
  }

  Future<void> _createTablesV1(Database db) async {
    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT NOT NULL,
        birthdate TEXT NOT NULL,
        gender TEXT NOT NULL,
        weight REAL NOT NULL,
        photoPath TEXT
      )
    ''');
  }

  Future<void> _createTablesV2(Database db) async {
    await db.execute('''
      CREATE TABLE vaccinations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        nextDueDate TEXT,
        notes TEXT,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        notes TEXT,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vet_visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        date TEXT NOT NULL,
        reason TEXT NOT NULL,
        diagnosis TEXT,
        treatment TEXT,
        cost REAL,
        vetName TEXT,
        notes TEXT,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER,
        title TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        notificationId INTEGER,
        FOREIGN KEY (petId) REFERENCES pets(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vet_contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        email TEXT,
        notes TEXT
      )
    ''');
  }

  // ─── Pets ───

  Future<int> insertPet(Pet pet) async {
    final db = await database;
    return await db.insert('pets', pet.toMap()..remove('id'));
  }

  Future<List<Pet>> getPets() async {
    final db = await database;
    final maps = await db.query('pets', orderBy: 'name ASC');
    return maps.map((map) => Pet.fromMap(map)).toList();
  }

  Future<Pet?> getPetById(int id) async {
    final db = await database;
    final maps = await db.query('pets', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Pet.fromMap(maps.first);
  }

  Future<int> updatePet(Pet pet) async {
    final db = await database;
    return await db.update(
      'pets',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  Future<int> deletePet(int id) async {
    final db = await database;
    return await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Pet>> searchPets(String query) async {
    final db = await database;
    final maps = await db.query(
      'pets',
      where: 'name LIKE ? OR species LIKE ? OR breed LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Pet.fromMap(map)).toList();
  }

  // ─── Vaccinations ───

  Future<int> insertVaccination(Vaccination vaccination) async {
    final db = await database;
    return await db.insert('vaccinations', vaccination.toMap()..remove('id'));
  }

  Future<List<Vaccination>> getVaccinationsForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'vaccinations',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Vaccination.fromMap(map)).toList();
  }

  Future<int> updateVaccination(Vaccination vaccination) async {
    final db = await database;
    return await db.update(
      'vaccinations',
      vaccination.toMap(),
      where: 'id = ?',
      whereArgs: [vaccination.id],
    );
  }

  Future<int> deleteVaccination(int id) async {
    final db = await database;
    return await db.delete('vaccinations', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Medications ───

  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap()..remove('id'));
  }

  Future<List<Medication>> getMedicationsForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'medications',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'startDate DESC',
    );
    return maps.map((map) => Medication.fromMap(map)).toList();
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Vet Visits ───

  Future<int> insertVetVisit(VetVisit vetVisit) async {
    final db = await database;
    return await db.insert('vet_visits', vetVisit.toMap()..remove('id'));
  }

  Future<List<VetVisit>> getVetVisitsForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'vet_visits',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => VetVisit.fromMap(map)).toList();
  }

  Future<int> updateVetVisit(VetVisit vetVisit) async {
    final db = await database;
    return await db.update(
      'vet_visits',
      vetVisit.toMap(),
      where: 'id = ?',
      whereArgs: [vetVisit.id],
    );
  }

  Future<int> deleteVetVisit(int id) async {
    final db = await database;
    return await db.delete('vet_visits', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Weight Entries ───

  Future<int> insertWeightEntry(WeightEntry entry) async {
    final db = await database;
    return await db.insert('weight_entries', entry.toMap()..remove('id'));
  }

  Future<List<WeightEntry>> getWeightEntriesForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'weight_entries',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'date ASC',
    );
    return maps.map((map) => WeightEntry.fromMap(map)).toList();
  }

  Future<int> updateWeightEntry(WeightEntry entry) async {
    final db = await database;
    return await db.update(
      'weight_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteWeightEntry(int id) async {
    final db = await database;
    return await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Notes ───

  Future<int> insertNote(PetNote note) async {
    final db = await database;
    return await db.insert('notes', note.toMap()..remove('id'));
  }

  Future<List<PetNote>> getNotesForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    return maps.map((map) => PetNote.fromMap(map)).toList();
  }

  Future<int> updateNote(PetNote note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Appointments ───

  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap()..remove('id'));
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'appointments',
      where: 'dateTime >= ?',
      whereArgs: [now],
      orderBy: 'dateTime ASC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<List<Appointment>> getPastAppointments() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'appointments',
      where: 'dateTime < ?',
      whereArgs: [now],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<List<Appointment>> getAppointmentsForPet(int petId) async {
    final db = await database;
    final maps = await db.query(
      'appointments',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Appointment.fromMap(map)).toList();
  }

  Future<int> updateAppointment(Appointment appointment) async {
    final db = await database;
    return await db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Vet Contacts ───

  Future<int> insertVetContact(VetContact contact) async {
    final db = await database;
    return await db.insert('vet_contacts', contact.toMap()..remove('id'));
  }

  Future<List<VetContact>> getVetContacts() async {
    final db = await database;
    final maps = await db.query('vet_contacts', orderBy: 'name ASC');
    return maps.map((map) => VetContact.fromMap(map)).toList();
  }

  Future<int> updateVetContact(VetContact contact) async {
    final db = await database;
    return await db.update(
      'vet_contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteVetContact(int id) async {
    final db = await database;
    return await db.delete('vet_contacts', where: 'id = ?', whereArgs: [id]);
  }
}

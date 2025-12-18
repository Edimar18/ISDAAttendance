import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Event {
  final int? id;
  final String title;
  final String type;
  final DateTime date;
  final bool isRecorded;

  Event({
    this.id,
    required this.title,
    required this.type,
    required this.date,
    this.isRecorded = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'date': date.toIso8601String(),
      'isRecorded': isRecorded ? 1 : 0,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      isRecorded: map['isRecorded'] == 1,
    );
  }

  Event copyWith({
    int? id,
    String? title,
    String? type,
    DateTime? date,
    bool? isRecorded,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      isRecorded: isRecorded ?? this.isRecorded,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE events ( 
  id $idType, 
  title $textType,
  type $textType,
  date $textType,
  isRecorded $boolType
  )
''');
  }

  Future<Event> create(Event event) async {
    final db = await instance.database;
    final id = await db.insert('events', event.toMap());
    return event.copyWith(id: id);
  }

  Future<Event> readEvent(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'events',
      columns: ['id', 'title', 'type', 'date', 'isRecorded'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Event>> readAllEvents() async {
    final db = await instance.database;
    final result = await db.query('events', orderBy: 'date DESC');
    return result.map((json) => Event.fromMap(json)).toList();
  }

  Future<int> update(Event event) async {
    final db = await instance.database;

    return db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

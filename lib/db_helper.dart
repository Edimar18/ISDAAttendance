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

class Participant {
  final int? id;
  final String name;
  final String course;
  final String year;

  Participant({
    this.id,
    required this.name,
    required this.course,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'course': course,
      'year': year,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
      course: map['course'],
      year: map['year'],
    );
  }
}

class AttendanceRecord {
  final int? id;
  final int eventId;
  final int participantId;
  final DateTime timeIn;
  final DateTime? timeOut;
  final Participant? participant; // Joined data

  AttendanceRecord({
    this.id,
    required this.eventId,
    required this.participantId,
    required this.timeIn,
    this.timeOut,
    this.participant,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'participant_id': participantId,
      'time_in': timeIn.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
    };
  }
  
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
     return AttendanceRecord(
        id: map['id'],
        eventId: map['event_id'],
        participantId: map['participant_id'],
        timeIn: DateTime.parse(map['time_in']),
        timeOut: map['time_out'] != null ? DateTime.parse(map['time_out']) : null,
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

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE events ( 
  id $idType, 
  title $textType,
  type $textType,
  date $textType,
  isRecorded $boolType
  )
''');

    await db.execute('''
CREATE TABLE participants (
  id $idType,
  name $textType,
  course $textType,
  year $textType
)
''');

    await db.execute('''
CREATE TABLE attendance (
  id $idType,
  event_id $intType,
  participant_id $intType,
  time_in $textType,
  time_out TEXT,
  FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
  FOREIGN KEY (participant_id) REFERENCES participants (id) ON DELETE CASCADE
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE participants (
  id $idType,
  name $textType,
  course $textType,
  year $textType
)
''');
    }
    
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE attendance (
  id $idType,
  event_id $intType,
  participant_id $intType,
  time_in $textType,
  time_out TEXT,
  FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
  FOREIGN KEY (participant_id) REFERENCES participants (id) ON DELETE CASCADE
)
''');
    }
  }

  // --- Events CRUD ---

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
    
    // We can do a manual join or just update isRecorded flag based on attendance count query for each event
    // But for simplicity, let's just fetch events and let the UI decide based on querying attendance count if needed,
    // OR, we can assume 'isRecorded' column is the source of truth if we update it.
    // However, the requirement says "it should be based on the attendance record on the event".
    // So let's add a method to check if event has attendance.
    
    final result = await db.query('events', orderBy: 'date DESC');
    
    List<Event> events = result.map((json) => Event.fromMap(json)).toList();
    
    // Option: Verify 'isRecorded' consistency.
    // For now, let's just return events. We will dynamically check attendance status in UI or another method.
    
    return events;
  }
  
  Future<bool> hasAttendanceRecords(int eventId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM attendance WHERE event_id = ?', [eventId]);
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
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

  // --- Participants CRUD ---

  Future<Participant> createParticipant(Participant participant) async {
    final db = await instance.database;
    final id = await db.insert('participants', participant.toMap());
    return Participant(
        id: id,
        name: participant.name,
        course: participant.course,
        year: participant.year
    );
  }
  
  Future<List<Participant>> readAllParticipants() async {
    final db = await instance.database;
    final result = await db.query('participants', orderBy: 'name ASC');
    return result.map((json) => Participant.fromMap(json)).toList();
  }

  Future<int> deleteParticipant(int id) async {
    final db = await instance.database;
    return await db.delete(
      'participants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // --- Attendance CRUD ---
  
  Future<AttendanceRecord> addAttendance(int eventId, int participantId, DateTime timeIn) async {
    final db = await instance.database;
    final record = AttendanceRecord(
        eventId: eventId, 
        participantId: participantId, 
        timeIn: timeIn
    );
    final id = await db.insert('attendance', record.toMap());
    
    // Update event isRecorded flag
    await db.update('events', {'isRecorded': 1}, where: 'id = ?', whereArgs: [eventId]);
    
    return AttendanceRecord(
        id: id, 
        eventId: eventId, 
        participantId: participantId, 
        timeIn: timeIn
    );
  }
  
  Future<List<AttendanceRecord>> getAttendanceForEvent(int eventId) async {
      final db = await instance.database;
      
      // Perform join
      final result = await db.rawQuery('''
        SELECT a.*, p.name, p.course, p.year 
        FROM attendance a
        INNER JOIN participants p ON a.participant_id = p.id
        WHERE a.event_id = ?
        ORDER BY a.time_in DESC
      ''', [eventId]);
      
      return result.map((row) {
          final participant = Participant(
              id: row['participant_id'] as int,
              name: row['name'] as String,
              course: row['course'] as String,
              year: row['year'] as String,
          );
          
          return AttendanceRecord(
              id: row['id'] as int,
              eventId: row['event_id'] as int,
              participantId: row['participant_id'] as int,
              timeIn: DateTime.parse(row['time_in'] as String),
              timeOut: row['time_out'] != null ? DateTime.parse(row['time_out'] as String) : null,
              participant: participant
          );
      }).toList();
  }
  
  Future<void> updateTimeOut(int attendanceId, DateTime timeOut) async {
      final db = await instance.database;
      await db.update(
          'attendance', 
          {'time_out': timeOut.toIso8601String()},
          where: 'id = ?',
          whereArgs: [attendanceId]
      );
  }
  
  Future<void> timeOutAll(int eventId, DateTime timeOut) async {
      final db = await instance.database;
      await db.update(
          'attendance',
          {'time_out': timeOut.toIso8601String()},
          where: 'event_id = ? AND time_out IS NULL',
          whereArgs: [eventId]
      );
  }
  
  Future<void> deleteAttendance(int attendanceId) async {
      final db = await instance.database;
      await db.delete('attendance', where: 'id = ?', whereArgs: [attendanceId]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

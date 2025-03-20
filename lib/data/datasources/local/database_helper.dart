import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/qr_code_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'qr_scanner.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE qr_codes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        scanned_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertQrCode(QrCodeModel qrCode) async {
    Database db = await database;
    return await db.insert('qr_codes', qrCode.toMap());
  }

  Future<List<QrCodeModel>> getAllQrCodes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'qr_codes',
      orderBy: 'scanned_at DESC',
    );

    return List.generate(maps.length, (i) {
      return QrCodeModel.fromMap(maps[i]);
    });
  }

  Future<void> deleteQrCode(int id) async {
    Database db = await database;
    await db.delete(
      'qr_codes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
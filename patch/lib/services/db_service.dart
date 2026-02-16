import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbService {
  DbService._();
  static final DbService instance = DbService._();

  Database? _db;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'hh_protokol.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE crew(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE stores(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            city TEXT NOT NULL,
            store_no TEXT NOT NULL,
            name TEXT,
            address TEXT,
            phone TEXT,
            email TEXT
          );
        ''');
      },
    );
  }

  Database get db {
    final d = _db;
    if (d == null) throw StateError('DB not initialized');
    return d;
  }

  // CREW
  Future<List<Map<String, Object?>>> listCrew({String q = ''}) async {
    if (q.trim().isEmpty) {
      return db.query('crew', orderBy: 'name COLLATE NOCASE');
    }
    final like = '%${q.trim()}%';
    return db.query('crew', where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?', whereArgs: [like, like, like], orderBy: 'name COLLATE NOCASE');
    }

  Future<int> upsertCrew({int? id, required String name, String? phone, String? email}) async {
    final data = {'name': name.trim(), 'phone': phone?.trim(), 'email': email?.trim()};
    if (id == null) return db.insert('crew', data);
    return db.update('crew', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteCrew(int id) => db.delete('crew', where: 'id=?', whereArgs: [id]);

  // STORES
  Future<List<Map<String, Object?>>> listStores({String q = ''}) async {
    if (q.trim().isEmpty) {
      return db.query('stores', orderBy: 'city COLLATE NOCASE, store_no COLLATE NOCASE');
    }
    final like = '%${q.trim()}%';
    return db.query(
      'stores',
      where: 'city LIKE ? OR store_no LIKE ? OR name LIKE ? OR address LIKE ?',
      whereArgs: [like, like, like, like],
      orderBy: 'city COLLATE NOCASE, store_no COLLATE NOCASE',
    );
  }

  Future<int> upsertStore({
    int? id,
    required String city,
    required String storeNo,
    String? name,
    String? address,
    String? phone,
    String? email,
  }) async {
    final data = {
      'city': city.trim(),
      'store_no': storeNo.trim(),
      'name': name?.trim(),
      'address': address?.trim(),
      'phone': phone?.trim(),
      'email': email?.trim(),
    };
    if (id == null) return db.insert('stores', data);
    return db.update('stores', data, where: 'id=?', whereArgs: [id]);
  }

  Future<int> deleteStore(int id) => db.delete('stores', where: 'id=?', whereArgs: [id]);
}

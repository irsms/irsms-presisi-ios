import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Dbhelper {
  static const _databaseName = "irsms_db";
  static const _databaseVersion = 10;

  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, _databaseName),
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<FutureOr<void>> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      db.execute("ALTER TABLE accident ADD COLUMN tkpLaka TEXT;");
    }
  }

  Future<FutureOr<void>> _onCreate(Database db, int version) async {
    //

    // table saksi
    String sql = '''CREATE TABLE IF NOT EXISTS saksi(
      saksiId INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT NOT NULL,
      jenisKelamin TEXT NOT NULL,
      tempatLahir TEXT NOT NULL,
      tanggalLahir TEXT NOT NULL,
      pekerjaan TEXT NOT NULL,
      kewarganegaraan TEXT NOT NULL,
      nomorHP TEXT NOT NULL,
      alamat TEXT NOT NULL,
      accidentUuid TEXT NOT NULL 
    )''';

    await db.execute(sql);
    //
    // table accident pictures
    sql = '''CREATE TABLE IF NOT EXISTS pictures(
      pictureId INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL,
      accidentUuid TEXT NOT NULL 
    )''';

    await db.execute(sql);

    //  await db.execute('DROP TABLE IF EXISTS accident');

    sql = '''
      CREATE TABLE IF NOT EXISTS accident(
      accidentUuid TEXT PRIMARY KEY,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      petugas TEXT NOT NULL,
      nrp TEXT NOT NULL,
      polda TEXT NOT NULL,
      polres TEXT NOT NULL,
      tanggalKejadian TEXT NOT NULL,
      jamKejadian TEXT NOT NULL,
      tanggalLaporan TEXT NOT NULL,
      jamLaporan TEXT NOT NULL,
      informasiKhusus TEXT NOT NULL,
      kecelakaanMenonjol TEXT NOT NULL,
      tipeKecelakaan TEXT NOT NULL,
      kondisiCahaya TEXT NOT NULL,
      cuaca TEXT NOT NULL,
      kerusakanMaterial TEXT NOT NULL,
      nilaiRugiKendaraan DOUBLE DEFAULT 0 NOT NULL,
      nilaiRugiNonKendaraan DOUBLE NOT NULL,
      tkpLaka TEXT NOT NULL

    )''';

    await db.execute(sql);

    sql = '''
      CREATE TABLE IF NOT EXISTS laka(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      nrp TEXT NOT NULL,
      polda TEXT NOT NULL,
      polres TEXT NOT NULL
    )''';

    await db.execute(sql);
    sql = '''
      CREATE TABLE IF NOT EXISTS ref(
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      grp_id TEXT NOT NULL,
      sort TEXT NOT NULL,
      state TEXT NOT NULL
    )''';

    await db.execute(sql);
  }

  Future<int> insert(
      {required String table, required Map<String, dynamic> data}) async {
    int result = 0;
    final Database db = await initializeDB();

    result = await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<List> queryAllRows(String table) async {
    final Database db = await initializeDB();
    final List<Map<String, dynamic>> result = await db.query(table);
    return result;
  }

  Future<List<Map<String, dynamic>>> queryRows(
      {required String table, required String where}) async {
    final Database db = await initializeDB();
    return await db.query(table, where: where);
  }

  Future<int> update(
      {required String table,
      required Map<String, dynamic> data,
      required String columnPK,
      required List whereArgs}) async {
    final Database db = await initializeDB();
    return await db.update(table, data,
        where: '$columnPK = ?', whereArgs: whereArgs);
  }

  Future<int> delete(
      {required String table,
      required String columnPK,
      required List whereArgs}) async {
    final Database db = await initializeDB();
    return await db.delete(table, where: '$columnPK = ?', whereArgs: whereArgs);
  }

  Future<int> queryRowCount(String table) async {
    final Database db = await initializeDB();
    String sql = 'SELECT COUNT(*) FROM $table';
    var results = await db.rawQuery(sql);
    return Sqflite.firstIntValue(results) ?? 0;
  }
}

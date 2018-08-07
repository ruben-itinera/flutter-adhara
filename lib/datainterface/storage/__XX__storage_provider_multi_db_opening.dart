//import 'dart:convert' show json;
//import 'dart:async';
//import 'dart:io';
//import 'package:path/path.dart';
//import 'package:sqflite/sqflite.dart';
//import 'package:sqflite/src/exception.dart'
//    show SqfliteDatabaseException; //TODO handle...
//import 'package:path_provider/path_provider.dart';
//import 'package:adhara/config.dart';
//
//abstract class StorageProvider {
//  Database _db;
//  Config config;
//
//  StorageProvider(this.config);
//
//  get schema;
//  String get tableName;
//  String get constraints => "";
//
//  getOperatorClassFromMap(Map map) {
//    return StorageOperator.fromMap(map);
//  }
//
//  ///Schematic of a Field schema...
//  ///
//  ///{
//  ///   "name": <String>,
//  ///   "type": <String>,
//  ///   "autoincrement": <bool>,
//  ///   "constraints": <UNIQUE|NOT NULL|CHECK|FOREIGN KEY>
//  /// }
//  _convertSchemaFieldToSQL(field) {
//    String name = field["name"] + " ";
//    String type = field["type"] ?? "";
//    String constraints = field["constraints"] ?? "";
//    var ai = field["autoincrement"];
//    String autoincrement = "autoincrement";
//    if (ai == null || ai == false) {
//      autoincrement = "";
//    }
//    /*String nonNull = "";
//    if(constraints == "primary key") {
//      nonNull = "not null";
//    }else{
//      nonNull = (!field["null"])?"not null":"";
//    }*/
//    return """$name $type $constraints $autoincrement""".trim();
//  }
//
//  String get fieldsStringSchema {
//    String schema =
//        this.schema.map(this._convertSchemaFieldToSQL).toList().join(", ");
//    schema += ", _id integer primary key autoincrement";
//    return schema;
//  }
//
//  String get stringSchema {
//    if (this.constraints != "") {
//      return fieldsStringSchema + ", " + this.constraints;
//    }
//    return fieldsStringSchema;
//  }
//
//  Future open({Function onOpen}) async {
//    Directory documentsDirectory = await getApplicationDocumentsDirectory();
//    String path = join(documentsDirectory.path, config.dbName);
//    _db = await openDatabase(path, version: config.dbVersion, onOpen: onOpen);
//  }
//
//  Future createTable() async {
//    return open(onOpen: (Database db /*, int version*/) async {
//      try {
//        await db
//            .execute("create table ${this.tableName} (${this.stringSchema});");
//      } on SqfliteDatabaseException catch (e) {
//        if (e.getResultCode() != 1) {
//          await this.close(); //required as callback is for db:onOpen
//          throw e;
//        }
//      }
//    });
//  }
//
//  Future close() async {
//    (await this.db).close();
//    _db = null;
//  }
//
//  Future<Database> get db async {
////    if(_db == null) {
//    await open();
////    }
//    return _db;
//  }
//
//  Future<StorageOperator> insert(StorageOperator operator) async {
//    Database db = await this.db;
//    try {
//      operator._id = await db.insert(this.tableName, operator.toMap());
//      return operator;
//    } catch (e) {
//      await this
//          .close(); //Performing close in catch as it needs to be awaited for. Finally block needs to be synchronous.
//      throw new Exception(e);
//    }
//  }
//
//  Future<List<StorageOperator>> insertAll(
//      List<StorageOperator> operators) async {
//    Database db = await this.db;
//    try {
//      Batch batch = db.batch();
//      operators.forEach((StorageOperator operator) {
//        batch.insert(this.tableName, operator.toMap());
//      });
//      List<int> results = await batch.commit();
//      for (int i = 0; i < results.length; i++) {
//        operators[i]._id = results[i];
//      }
//      return operators;
//    } catch (e) {
//      await this.close();
//      throw new Exception(e);
//    }
//  }
//
//  List<String> get selectColumns {
//    List<String> columns = [];
//    this.schema.forEach((Map field) {
//      columns.add(field["name"].toString());
//    });
//    columns.add("_id");
//    return columns;
//  }
//
//  Future<List<Map>> getRawList(
//      {bool distinct,
//      List<String> columns,
//      String where,
//      List whereArgs,
//      String groupBy,
//      String having,
//      String orderBy,
//      int limit,
//      int offset}) async {
//    Database db = await this.db;
//    try {
//      // Extracting fields from schema
//      List<String> columns = selectColumns;
//      // Querying the database
//      List<Map> maps = await db.query(
//        this.tableName,
//        distinct: distinct,
//        columns: columns,
//        where: where,
//        whereArgs: whereArgs,
//        groupBy: groupBy,
//        having: having,
//        orderBy: orderBy,
//        limit: limit,
//        offset: offset,
//      );
//      return maps;
//    } catch (e) {
//      await this.close();
//      throw new Exception(e);
//    }
//  }
//
//  Future<List<StorageOperator>> getList(
//      {bool distinct,
//      List<String> columns,
//      String where,
//      List whereArgs,
//      String groupBy,
//      String having,
//      String orderBy,
//      int limit,
//      int offset}) async {
//    List<Map> maps = await this.getRawList(
//      distinct: distinct,
//      columns: columns,
//      where: where,
//      whereArgs: whereArgs,
//      groupBy: groupBy,
//      having: having,
//      orderBy: orderBy,
//      limit: limit,
//      offset: offset,
//    );
//    if (maps != null && maps.length > 0) {
//      List<StorageOperator> soList = [];
//      maps.forEach((map) => soList.add(getOperatorClassFromMap(map)));
//      return soList;
//    }
//    return null;
//  }
//
//  Future<Map> getRaw({String where, List<dynamic> whereArgs}) async {
//    List<Map> maps = await this.getRawList(where: where, whereArgs: whereArgs);
//    if (maps != null && maps.length > 0) {
//      return maps.first;
//    }
//    return null;
//  }
//
//  Future<StorageOperator> get({String where, List<dynamic> whereArgs}) async {
//    Map map = await getRaw(where: where, whereArgs: whereArgs);
//    if (map != null) {
//      return getOperatorClassFromMap(map);
//    }
//    return null;
//  }
//
//  Future<Map> getByIdRaw(int id) async {
//    List<Map> maps = await this.getRawList(where: "_id=${id.toString()}");
//    if (maps != null && maps.length > 0) {
//      return maps.first;
//    }
//    return null;
//  }
//
//  Future<StorageOperator> getById(int id) async {
//    Map map = await getByIdRaw(id);
//    if (map != null) {
//      return getOperatorClassFromMap(map);
//    }
//    return null;
//  }
//
//  Future<int> delete({String where, List whereArgs}) async {
//    Database db = await this.db;
//    try {
//      return await db.delete(this.tableName,
//          where: where, whereArgs: whereArgs);
//    } catch (e) {
//      await this.close();
//      throw new Exception(e);
//    }
//  }
//
//  Future<int> update(
//      StorageOperator operator, String where, List whereArgs) async {
//    Database db = await this.db;
//    int id;
//    try {
//      id = await db.update(this.tableName, operator.toMap(),
//          where: where, whereArgs: whereArgs);
//    } catch (e) {
//      await this.close();
//      throw new Exception(e);
//    }
//    return id;
//  }
//}
//
//class StorageOperator {
//  int _id;
//
//  Map data;
//
//  toMap() {
//    return data;
//  }
//
//  StorageOperator() {
//    return;
//  }
//
//  StorageOperator.fromMap(map) {
//    this.data = map;
//  }
//
//  StorageOperator.fromJSON(jsonObject) {
//    data = json.decode(jsonObject);
//  }
//}
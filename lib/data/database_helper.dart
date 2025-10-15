// `database_helper.dart`
import 'dart:async';
import 'dart:convert';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // Necesario para kIsWeb y defaultTargetPlatform

import 'package:oficinaescolar_colaboradores/models/aviso_model.dart';
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
// ⭐️ IMPORTANTE: Asegúrate de que esta importación apunte a tu modelo BoletaEncabezadoModel
//import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 

/// Clase [DatabaseHelper]
///
/// Esta clase es un Singleton que gestiona todas las operaciones relacionadas
/// con la base de datos SQLite local de la aplicación.
class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'oficina_escolar_db.db';
  static const int _dbVersion = 2; // ✅ Mantenido el número de versión

  static const String _schoolDataTable = 'school_data';
  static const String _colaboradorDataTable = 'colaborador_data'; // ✅ [REF] Cambiado de _alumnoDataTable
  static const String _individualAvisosTable = 'individual_avisos';
  static const String _articulosCafDataTable = 'articulos_caf_data';
  static const String _cafeteriaMovimientosDataTable = 'cafeteria_movimientos_data';
  static const String _sessionDataTable = 'session_data';
  static const String _coloresAppTable = 'colores_app';
  static const String _tokensTable = 'tokens_data';
  // ⭐️ NUEVO: Tabla para la estructura de encabezados de calificación
  static const String _encabezadosBoletaTable = 'boleta_encabezados';
  
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // ⭐️ NUEVO GETTER: Detecta si NO estamos en una plataforma móvil ⭐️
  bool get _debeDeshabilitarDb {
    // 1. Deshabilitar si es Web
    if (kIsWeb) {
      return true;
    }
    // 2. Deshabilitar si es Desktop compilado
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }
  
  Future<Database> get database async {
    // ⭐️ PROTECCIÓN DE ACCESO: Si está deshabilitada, no continuar ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Acceso a DB denegado (Web/Desktop).');
      throw UnsupportedError('La base de datos SQLite está inhabilitada en esta plataforma.');
    }
    
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // ⭐️ PROTECCIÓN DE INICIALIZACIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Ejecutando en Web/Desktop. Se lanza UnsupportedError para prevenir el uso de SQLite.');
      throw UnsupportedError('La inicialización de la base de datos SQLite está restringida en plataformas Web o de escritorio en esta versión.');
    }
    // FIN PROTECCIÓN DE INICIALIZACIÓN
    
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _dbName);
    debugPrint('DatabaseHelper: Ruta de la base de datos: $path');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DatabaseHelper: Creando tablas de la base de datos...');
    await db.execute('''
      CREATE TABLE $_schoolDataTable (
        id TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        last_fetch_time INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_colaboradorDataTable (
        id TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        last_fetch_time INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_individualAvisosTable (
        id_calendario TEXT NOT NULL,
        id_empresa_colaborador_cache_id TEXT NOT NULL,
        titulo TEXT,
        color_titulo TEXT,
        comentario TEXT,
        fecha TEXT,
        fecha_fin TEXT,
        leido INTEGER NOT NULL DEFAULT 0,
        archivo TEXT,
        imagenLocalPath TEXT,
        imagenCacheTimestamp TEXT,
        seccion TEXT,
        tipo_respuesta TEXT,
        seg_respuesta TEXT,
        opcion_1 TEXT,
        opcion_2 TEXT,
        opcion_3 TEXT,
        opcion_4 TEXT,
        opcion_5 TEXT,
        PRIMARY KEY (id_calendario, id_empresa_colaborador_cache_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE $_articulosCafDataTable (
        id TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        last_fetch_time INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_cafeteriaMovimientosDataTable (
        id TEXT PRIMARY KEY,
        saldo_actual REAL,
        data_json TEXT NOT NULL,
        last_fetch_time INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_sessionDataTable (
        id TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        last_update_time INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_coloresAppTable(
        id INTEGER PRIMARY KEY,
        app_color_header TEXT,
        app_color_footer TEXT,
        app_color_background TEXT,
        app_color_botones TEXT,
        app_cred_color_header_1 TEXT,
        app_cred_color_header_2 TEXT,
        app_cred_color_letra_1 TEXT,
        app_cred_color_letra_2 TEXT,
        app_cred_color_background_1 TEXT,
        app_cred_color_background_2 TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_tokensTable(
        id TEXT PRIMARY KEY,
        id_token TEXT,
        token_celular TEXT
      )
    ''');
    // ⭐️ NUEVO: Creación de la tabla de encabezados de boleta
    await db.execute('''
      CREATE TABLE $_encabezadosBoletaTable (
        nivel_educativo TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    debugPrint('DatabaseHelper: Tablas creadas exitosamente.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('DatabaseHelper: Iniciando migración de la base de datos de la versión $oldVersion a $newVersion.');
    debugPrint('DatabaseHelper: Migración completada.');
  }

  Future<void> close() async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Cierre de DB omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await instance.database;
    await db.close();
    _database = null;
    debugPrint('DatabaseHelper: Base de datos cerrada.');
  }

  Future<void> clearAllData() async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Limpieza de DB omitida (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await instance.database;
    await db.delete(_schoolDataTable);
    await db.delete(_colaboradorDataTable); 
    await db.delete(_individualAvisosTable);
    await db.delete(_articulosCafDataTable);
    await db.delete(_cafeteriaMovimientosDataTable);
    await db.delete(_sessionDataTable);
    await db.delete(_coloresAppTable);
    await db.delete(_tokensTable);
    // ⭐️ NUEVO: Limpiar tabla de encabezados de boleta
    await db.delete(_encabezadosBoletaTable); 
    debugPrint('DatabaseHelper: Todas las tablas limpiadas.');
  }

  // --- Métodos Genéricos para Guardar y Obtener Datos ---
  Future<void> _saveData(String tableName, String id, Map<String, dynamic> dataJson, {bool isSessionData = false}) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de $tableName omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final String jsonString = json.encode(dataJson);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      tableName,
      {
        'id': id,
        'data_json': jsonString,
        isSessionData ? 'last_update_time' : 'last_fetch_time': timestamp
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Datos guardados/actualizados en $tableName para ID: $id');
  }

  Future<void> _saveListData(String tableName, String id, List<dynamic> dataJsonList) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de lista $tableName omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final String jsonString = json.encode(dataJsonList);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      tableName,
      {'id': id, 'data_json': jsonString, 'last_fetch_time': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Lista de datos guardada/actualizada en $tableName para ID: $id');
  }
  
  Future<Map<String, dynamic>?> _getData(String tableName, String id, {bool isSessionData = false}) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Obtención de datos de $tableName omitida (Web/Desktop).');
      return null;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final data = maps.first;
      debugPrint('DatabaseHelper: Datos obtenidos de $tableName para ID: $id');
      return {
        'data_json': json.decode(data['data_json'] as String),
        'last_fetch_time': DateTime.fromMillisecondsSinceEpoch(data[isSessionData ? 'last_update_time' : 'last_fetch_time'] as int),
      };
    }
    debugPrint('DatabaseHelper: No se encontraron datos en $tableName para ID: $id');
    return null;
  }
  
  // --- Métodos Específicos para Guardar y Obtener Datos por Tipo ---

  Future<void> saveSchoolData(String id, Map<String, dynamic> dataJson) async {
    await _saveData(_schoolDataTable, id, dataJson);
  }
  Future<Map<String, dynamic>?> getSchoolData(String id) async {
    return await _getData(_schoolDataTable, id);
  }
  
  // ✅ [REF] Nuevos métodos para la tabla de colaboradores
  Future<void> saveColaboradorData(String id, Map<String, dynamic> dataJson) async {
    await _saveData(_colaboradorDataTable, id, dataJson);
  }
  Future<Map<String, dynamic>?> getColaboradorData(String id) async {
    return await _getData(_colaboradorDataTable, id);
  }

  // ⭐️ NUEVO: Métodos para Guardar y Obtener la Configuración de la Boleta
  
  /// Guarda la estructura de encabezados de boleta en la base de datos local.
  Future<void> saveBoletaEncabezados(List<BoletaEncabezadoModel> encabezados) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de encabezados omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    
    // Borrar todo antes de guardar, ya que es una configuración de lista global
    await db.delete(_encabezadosBoletaTable); 
    debugPrint('DatabaseHelper: Limpiada la tabla $_encabezadosBoletaTable.');

    for (final enc in encabezados) {
        // Creamos un Map que puede ser serializado a JSON para la columna 'data'
        final Map<String, dynamic> serializableData = {
            'encabezados': enc.encabezados,
            'relaciones': enc.relaciones,
            'comentarios': enc.comentarios,
            'promedioKey': enc.promedioKey,
        };
        
        final Map<String, dynamic> dataToSave = {
            'nivel_educativo': enc.nivelEducativo,
            'data': json.encode(serializableData),
        };
        await db.insert(
            _encabezadosBoletaTable, 
            dataToSave, 
            conflictAlgorithm: ConflictAlgorithm.replace
        );
    }
    debugPrint('DatabaseHelper: ${encabezados.length} estructuras de boleta guardadas.');
  }

  /// Obtiene la lista de estructuras de encabezados de boleta desde la base de datos local.
  Future<List<BoletaEncabezadoModel>> getBoletaEncabezados() async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Obtención de encabezados omitida (Web/Desktop).');
      return [];
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_encabezadosBoletaTable);

    if (maps.isEmpty) return [];

    return maps.map((map) {
        final Map<String, dynamic> rawData = json.decode(map['data'] as String);
        
        // Reconstruir el modelo desde la data guardada, asegurando los tipos
        return BoletaEncabezadoModel(
            nivelEducativo: map['nivel_educativo'] as String,
            encabezados: Map<String, String>.from(rawData['encabezados'] as Map),
            relaciones: Map<String, String>.from(rawData['relaciones'] as Map),
            comentarios: Map<String, String>.from(rawData['comentarios'] as Map),
            promedioKey: rawData['promedioKey'] as String?,
        );
    }).toList();
  }

  Future<void> saveAvisosData(String cacheId, List<AvisoModel> avisos) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de avisos omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    await db.delete(
      _individualAvisosTable,
      where: 'id_empresa_colaborador_cache_id = ?', // ✅ [REF] Cambiado de id_empresa_alumno_cache_id
      whereArgs: [cacheId],
    );
    debugPrint('DatabaseHelper: Eliminados avisos antiguos para cacheId: $cacheId de $_individualAvisosTable.');

    for (final aviso in avisos) {
      final avisoData = aviso.toDatabaseJson();
      avisoData['id_empresa_colaborador_cache_id'] = cacheId; // ✅ [REF] Cambiado
      await db.insert(
        _individualAvisosTable,
        avisoData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    debugPrint('DatabaseHelper: ${avisos.length} avisos guardados/actualizados en $_individualAvisosTable para cacheId: $cacheId.');
  }

  Future<List<AvisoModel>> getAvisosData(String cacheId) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Obtención de avisos omitida (Web/Desktop).');
      return [];
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _individualAvisosTable,
      where: 'id_empresa_colaborador_cache_id = ?', // ✅ [REF] Cambiado
      whereArgs: [cacheId],
      orderBy: 'fecha DESC',
    );

    if (maps.isNotEmpty) {
      debugPrint('DatabaseHelper: ${maps.length} avisos obtenidos de $_individualAvisosTable para cacheId: $cacheId.');
      return maps.map((map) => AvisoModel.fromDatabaseJson(map)).toList();
    }
    debugPrint('DatabaseHelper: No se encontraron avisos en $_individualAvisosTable para cacheId: $cacheId.');
    return [];
  }

  Future<void> updateAvisoReadStatus(String idCalendario, String cacheId, bool isRead) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Actualización de estado de lectura de aviso omitida (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    await db.update(
      _individualAvisosTable,
      {'leido': isRead ? 1 : 0},
      where: 'id_calendario = ? AND id_empresa_colaborador_cache_id = ?', // ✅ [REF] Cambiado
      whereArgs: [idCalendario, cacheId],
    );
    debugPrint('DatabaseHelper: Estado "leido" actualizado para aviso $idCalendario en $_individualAvisosTable.');
  }

  Future<void> updateAvisoWithImageCache(AvisoModel aviso, String cacheId) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Actualización de caché de imagen de aviso omitida (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    await db.update(
      _individualAvisosTable,
      {
        'imagenLocalPath': aviso.imagenLocalPath,
        'imagenCacheTimestamp': aviso.imagenCacheTimestamp?.toIso8601String(),
      },
      where: 'id_calendario = ? AND id_empresa_colaborador_cache_id = ?', // ✅ [REF] Cambiado
      whereArgs: [aviso.idCalendario, cacheId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Campos de caché de imagen actualizados para aviso ${aviso.idCalendario} en $_individualAvisosTable.');
  }

  Future<void> updateAvisoRespuesta(String idCalendario, String cacheId, String respuesta) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Actualización de respuesta de aviso omitida (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    await db.update(
      _individualAvisosTable,
      {'seg_respuesta': respuesta},
      where: 'id_calendario = ? AND id_empresa_colaborador_cache_id = ?', // ✅ [REF] Cambiado
      whereArgs: [idCalendario, cacheId],
    );
  }
  
  Future<void> saveArticulosCafData(String id, List<dynamic> dataJsonList) async {
    await _saveListData(_articulosCafDataTable, id, dataJsonList);
  }
  Future<Map<String, dynamic>?> getArticulosCafData(String id) async {
    return await _getData(_articulosCafDataTable, id);
  }
  
  Future<void> saveCafeteriaData(String id, double saldoActual, List<dynamic> dataJsonList) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de datos de cafetería omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final String jsonString = json.encode(dataJsonList);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      _cafeteriaMovimientosDataTable,
      {
        'id': id,
        'saldo_actual': saldoActual,
        'data_json': jsonString,
        'last_fetch_time': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Datos de cafetería guardados/actualizados para ID: $id');
  }

  Future<Map<String, dynamic>?> getCafeteriaData(String id) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Obtención de datos de cafetería omitida (Web/Desktop).');
      return null;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _cafeteriaMovimientosDataTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final data = maps.first;
      debugPrint('DatabaseHelper: Datos de cafetería obtenidos para ID: $id');
      return {
        'saldo_actual': data['saldo_actual'] as double?,
        'data_json': json.decode(data['data_json'] as String),
        'last_fetch_time': DateTime.fromMillisecondsSinceEpoch(data['last_fetch_time'] as int),
      };
    }
    debugPrint('DatabaseHelper: No se encontraron datos de cafetería para ID: $id');
    return null;
  }

  Future<void> saveSessionData(String id, Map<String, dynamic> dataJson) async {
    await _saveData(_sessionDataTable, id, dataJson, isSessionData: true);
  }
  Future<Map<String, dynamic>?> getSessionData(String id) async {
    return await _getData(_sessionDataTable, id, isSessionData: true);
  }
  
  Future<void> saveColoresData(Colores colores) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de colores omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    await db.insert(
      _coloresAppTable,
      colores.toMap()..['id'] = 1,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Colores de la app guardados/actualizados.');
  }

  Future<Colores?> getColoresData() async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Obtención de colores omitida (Web/Desktop).');
      return null;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_coloresAppTable, where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      debugPrint('DatabaseHelper: Colores de la app obtenidos.');
      return Colores.fromMap(maps.first);
    }
    debugPrint('DatabaseHelper: No se encontraron colores de la app.');
    return null;
  }
  
  Future<void> saveTokens(String id, String idToken, String fcmToken) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Guardado de tokens omitido (Web/Desktop).');
      return;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    await db.insert(
      _tokensTable,
      {'id': id, 'id_token': idToken, 'token_celular': fcmToken},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Tokens guardados/actualizados en $_tokensTable para ID: $id');
  }

  Future<Map<String, dynamic>?> getTokens(String id) async {
    // ⭐️ PROTECCIÓN ⭐️
    if (_debeDeshabilitarDb) {
      debugPrint('DatabaseHelper: Obtención de tokens omitida (Web/Desktop).');
      return null;
    }
    // FIN PROTECCIÓN
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tokensTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}
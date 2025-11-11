// `UserProvider.dart`
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:oficinaescolar_colaboradores/data/database_helper.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/models/alumno_asistencia_model.dart';
import 'package:oficinaescolar_colaboradores/models/alumno_salon_model.dart';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';
import 'package:oficinaescolar_colaboradores/models/comentario_model.dart';
import 'package:oficinaescolar_colaboradores/models/datos_archivo_a_subir.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; // ✅ [REF] Nuevo modelo
import 'package:oficinaescolar_colaboradores/models/aviso_model.dart';
//import 'package:oficinaescolar_colaboradores/models/cfdi_model.dart'; // Mantener el modelo si la API lo retorna, aunque no usemos el método
import 'package:oficinaescolar_colaboradores/models/articulo_model.dart';
//import 'package:oficinaescolar_colaboradores/models/pago_model.dart'; // Mantener el modelo si la API lo retorna
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';
import 'package:oficinaescolar_colaboradores/screens/lista_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  // --- Datos de Sesión y Control (Variables Privadas) ---
  String _idColaborador = ''; // ✅ [REF] Cambiado de _idAlumno a _idColaborador
  String _idEmpresa = '';
  String _email = '';
  String _escuela = '';
  String _idCiclo = '';
  String _fechaHora = '';
  String _rutaLogoEscuela = '';
  String? _fcmToken;
  String? _idToken;
  String? _tokenCelular;
  String? _idMateriaAlumno;
  String? _idAlumno;

  double _ultimoSaldoConocido = 0.0;
  double get ultimoSaldoConocido => _ultimoSaldoConocido;

  String? _selectedCafeteriaPeriodId;
  String? _selectedCafeteriaCicloId;

  ColaboradorModel? _currentColaboradorDetails; // ✅ [REF] Cambiado de AlumnoModel
  Colores? _colores;

  final _defaultColores = Colores(
    appColorHeader: '',
    appColorFooter: '',
    appColorBackground: '',
    appColorBotones: '',
    appCredColorHeader1: '',
    appCredColorHeader2: '',
    appCredColorLetra1: '',
    appCredColorLetra2: '',
    appCredColorBackground1: '',
    appCredColorBackground2: '',
  );

  // --- Marcas de Tiempo de la última vez que se obtuvieron datos de la API (para lógica de caché) ---
  DateTime? _lastSchoolDataFetch;
  DateTime? _lastColaboradorDataFetch; // ✅ [REF] Cambiado de _lastAlumnoDataFetch
  DateTime? _lastAvisosDataFetch;
  DateTime? _lastArticulosCafDataFetch;
  DateTime? _lastCafeteriaMovimientosDataFetch;
  
  // ✅ [REF] Eliminadas marcas de tiempo para CFDI, Pagos, Cargos, Materias

  // --- Modelos de Datos en Caché y Parseados (Variables Privadas) ---
  EscuelaModel? _escuelaModel;
  ColaboradorModel? _colaboradorModel; // ✅ [REF] Cambiado de AlumnoModel
  List<AvisoModel> _avisos = [];
  List<Articulo> _articulosCaf = [];
  List<Map<String, dynamic>> _cafeteriaMovimientos = [];
  List<BoletaEncabezadoModel> _boletaEncabezados = [];
  List<Map<String, dynamic>> _avisosCreados = [];
  //List<Map<String, dynamic>> _avisosArchivados = [];
  
  // ✅ [REF] Eliminados los modelos de datos para CFDI, Pagos, Cargos, Materias

  final ValueNotifier<void> autoRefreshTrigger = ValueNotifier(null);

  // --- Getters Públicos para Acceder a Datos de Sesión y Modelos ---
  String get idColaborador => _idColaborador; // ✅ [REF] Cambiado de idAlumno
  String get idEmpresa => _idEmpresa;
  String get email => _email;
  String get escuela => _escuela;
  String get idCiclo => _idCiclo;
  String get fechaHora => _fechaHora;
  String? get fcmToken => _fcmToken;
  String? get idToken => _idToken;
  String? get tokenCelular => _tokenCelular;
  String? get idMateriaAlumno => _idMateriaAlumno;
  String? get idAlumno => _idAlumno;

  String get rutaLogoEscuela => _rutaLogoEscuela;
  String? get selectedCafeteriaPeriodId => _selectedCafeteriaPeriodId;
  String? get selectedCafeteriaCicloId => _selectedCafeteriaCicloId;
  DateTime? get lastSchoolDataFetch => _lastSchoolDataFetch;
  DateTime? get lastColaboradorDataFetch => _lastColaboradorDataFetch; // ✅ [REF] Cambiado de lastAlumnoDataFetch
  DateTime? get lastAvisosDataFetch => _lastAvisosDataFetch;
  DateTime? get lastArticulosCafDataFetch => _lastArticulosCafDataFetch;
  DateTime? get lastCafeteriaMovimientosDataFetch => _lastCafeteriaMovimientosDataFetch;

  EscuelaModel? get escuelaModel => _escuelaModel;
  ColaboradorModel? get colaboradorModel => _colaboradorModel; // ✅ [REF] Cambiado de alumnoModel
  List<AvisoModel> get avisos => _avisos;
  List<Articulo> get articulosCaf => _articulosCaf;
  List<Map<String, dynamic>> get cafeteriaMovimientos => _cafeteriaMovimientos;
  ColaboradorModel? get currentColaboradorDetails => _currentColaboradorDetails; // ✅ [REF] Cambiado de currentAlumnoDetails
  List<AlumnoSalonModel> _alumnosSalon = [];

  // Getter para acceder a la configuración de la boleta
  List<BoletaEncabezadoModel> get boletaEncabezados => _boletaEncabezados;
    // ⭐️ INSTANCIAS DE HELPERS ⭐️
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _prefsAvisosCreadosKey = 'avisos_creados_json_list'; // Clave para SharedPreferences
  //static const String _prefsAvisosArchivadosKey = 'avisos_archivados_json_list';
  //List<Map<String, dynamic>> get avisosArchivados => _avisosArchivados;

  // ⭐️ NUEVO GETTER: Avisos creados ⭐️
  List<Map<String, dynamic>> get avisosCreados => _avisosCreados;

  int get unreadAvisosCount => _avisos.where((aviso) => !aviso.leido).length;

  Colores get colores => _colores ?? _defaultColores;

  /// Devuelve la lista de materias asignadas al colaborador actual.
  /// Siempre retorna una lista de MateriaModel, vacía si no hay datos.
  List<MateriaModel> get colaboradorMaterias {
    // El modelo ya es robusto y retorna [] si no hay datos, pero protegemos contra _colaboradorModel nulo.
    return _colaboradorModel?.materiasData ?? [];
  }

  /// Devuelve la lista de clubes asignados al colaborador actual.
  /// Siempre retorna una lista de ClubModel, vacía si no hay datos.
  List<ClubModel> get colaboradorClubes {
    return _colaboradorModel?.materiasClubes ?? [];
  }

  // --- Constructor y Métodos de Inicialización/Cierre ---
  UserProvider() {
    loadUserDataFromDb();
    loadAppColorsFromDb();
    loadAvisosCreados();
  }

  /// ⭐️ [FINAL] Carga la lista de avisos creados usando lógica dual (DB > SharedPreferences o Solo SP en Web).
Future<void> loadAvisosCreados() async {
    debugPrint('UserProvider: Intentando cargar avisos creados...');
    
    List<Map<String, dynamic>> loadedActivos = [];
    
    if (kIsWeb) {
        // 🚀 MODO WEB: Saltamos la DB, vamos directo a SharedPreferences.
        loadedActivos = await _getAvisosCreadosFromPrefs(_prefsAvisosCreadosKey);
        debugPrint('UserProvider: ${loadedActivos.length} activos cargados directamente desde SharedPreferences (Web).');
    } else {
        // 📱 MODO MÓVIL/DESKTOP: Intentamos DB primero.
        try {
            loadedActivos = await _dbHelper.getAvisosCreados(); 
            debugPrint('UserProvider: ${loadedActivos.length} avisos creados (activos) cargados desde DB (Móvil).');
        } catch (e) {
            // Fallback si la DB local falla o no existe (ej. primer arranque en iOS/Android).
            debugPrint('UserProvider: Fallo al cargar avisos desde DB. Intentando SharedPreferences. Error: $e');
            
            loadedActivos = await _getAvisosCreadosFromPrefs(_prefsAvisosCreadosKey);
            debugPrint('UserProvider: ${loadedActivos.length} activos cargados desde SharedPreferences (Fallback Móvil).');
        }
    }

    // 3. ACTUALIZAR ESTADO
    _avisosCreados = loadedActivos.toList(); 
    notifyListeners();
}
  
  /// ⭐️ [MODIFICADO] Guarda una lista de avisos completa en SharedPreferences (Web/Fallback), usando una KEY específica.
  Future<void> _saveAvisosCreadosToPrefs(List<Map<String, dynamic>> avisos, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Serializar toda la lista de Mapas a una cadena JSON
      final String jsonString = json.encode(avisos);
      await prefs.setString(key, jsonString); 
      debugPrint('UserProvider: ${avisos.length} avisos guardados en SharedPreferences con clave: $key.');
    } catch (e) {
      debugPrint('UserProvider: Error al guardar avisos en SharedPreferences: $e');
    }
  }

  /// ⭐️ [MODIFICADO] Obtiene la lista de avisos creados desde SharedPreferences (Web/Fallback), usando una KEY específica.
Future<List<Map<String, dynamic>>> _getAvisosCreadosFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key); 
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      // Deserializar la cadena JSON a una List<dynamic> y luego a List<Map<String, dynamic>>
      final List<dynamic> decodedList = json.decode(jsonString);
      // Asegurar que solo añadimos Mapas válidos
      // ⭐️ CAMBIO CLAVE: El .toList() asegura que la lista devuelta es mutable ⭐️
      final List<Map<String, dynamic>> avisos = decodedList.map((e) => e as Map<String, dynamic>).toList(); 
      
      return avisos;
    } catch (e) {
      debugPrint('UserProvider: Error al obtener avisos desde SharedPreferences con clave $key: $e');
      return [];
    }
}

  Future<void> loadAppColorsFromDb() async {
    debugPrint('UserProvider: Intentando cargar colores desde la base de datos...');
    
    // 1. INTENTO DE CARGA DESDE DB LOCAL (Móvil)
    _colores = await DatabaseHelper.instance.getColoresData(); 

    // 2. FALLBACK A SHARED_PREFERENCES (Web/Fallback)
    if (_colores == null) {
      final Map<String, dynamic> prefsData = await _loadColorsFromPrefs();
      
      // Verificamos si al menos el color principal se cargó de SharedPreferences
      if (prefsData['app_color_header'] != null && prefsData['app_color_header'].isNotEmpty) {
        try {
            _colores = Colores.fromMap(prefsData); 
            debugPrint('UserProvider: Colores cargados desde SharedPreferences (Web/Fallback).');
        } catch (e) {
            // Manejar un posible error de formato si la data de prefs es incorrecta
            debugPrint('Error al parsear colores desde SharedPreferences: $e');
        }
        
      } else {
        debugPrint('UserProvider: No se encontraron colores en la base de datos ni en SharedPreferences.');
      }
    } else {
      debugPrint('UserProvider: Colores cargados desde la base de datos (Móvil).');
    }
    
    notifyListeners(); 
  }

  // Función auxiliar para leer todos los colores de SharedPreferences
  Future<Map<String, dynamic>> _loadColorsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> colorData = {};

    const colorKeys = [
      'app_color_header', 'app_color_footer', 'app_color_background', 
      'app_color_botones', 'app_color_es_degradado', 'app_cred_color_header_1', 
      'app_cred_color_header_2', 'app_cred_color_letra_1', 'app_cred_color_letra_2', 
      'app_cred_color_background_1', 'app_cred_color_background_2', 'app_campos_credencial'
    ];

    // Cargar cada clave
    for (var key in colorKeys) {
      colorData[key] = prefs.getString(key);
    }
    
    // Devolvemos el mapa. Si 'app_color_header' es nulo, significa que no hay data guardada.
    return colorData;
  }
  /// Guarda TODOS los colores y datos de credencial en SharedPreferences para persistencia web
  /// Se llama desde el onPressed de la pantalla de código de escuela.
  Future<void> saveColorsToPrefs(Map<String, dynamic> response) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Lista de todas las claves de color/diseño que vienen en la respuesta
    const colorKeys = [
      'app_color_header', 'app_color_footer', 'app_color_background', 
      'app_color_botones', 'app_color_es_degradado', 'app_cred_color_header_1', 
      'app_cred_color_header_2', 'app_cred_color_letra_1', 'app_cred_color_letra_2', 
      'app_cred_color_background_1', 'app_cred_color_background_2', 'app_campos_credencial'
    ];
    
    // Guardar cada clave en SharedPreferences
    for (var key in colorKeys) {
      // Usamos ?.toString() para asegurar que guardamos cadenas
      final valueToSave = response[key]?.toString() ?? '';
      await prefs.setString(key, valueToSave);
    }
    
    debugPrint('UserProvider: Todos los colores y configuraciones de diseño guardados en SharedPreferences.');
  }

    Future<void> loadUserDataFromDb() async {
    debugPrint('UserProvider: Intentando cargar datos de usuario desde la base de datos...');

    final cachedData = await DatabaseHelper.instance.getSessionData('session_data');
    bool dataLoaded = false;
    Map<String, dynamic> sessionJson = {};

    // 1. INTENTO DE CARGA DESDE DB LOCAL (Móvil)
    if (cachedData != null) {
      sessionJson = cachedData['data_json'] as Map<String, dynamic>;
      debugPrint('UserProvider: Datos de colaborador cargados desde la base de datos (Móvil).');
      dataLoaded = true;
    }

    // 2. FALLBACK A SHARED_PREFERENCES (Web/Fallback)
    if (!dataLoaded) {
      final prefs = await SharedPreferences.getInstance();

      // Reconstruir sessionJson a partir de SharedPreferences
      sessionJson = {
        'idColaborador': prefs.getString('idColaborador') ?? '',
        'idEmpresa': prefs.getString('idEmpresa') ?? '',
        'email': prefs.getString('email') ?? '',
        'escuela': prefs.getString('escuela') ?? '',
        'idCiclo': prefs.getString('idCiclo') ?? '',
        'fechaHora': prefs.getString('fechaHora') ?? '',
        // Tokens (si se guardaron)
        'idToken': prefs.getString('idToken') ?? '', 
        'fcmToken': prefs.getString('fcmToken') ?? '',
      };

      // Verificar si la sesión esencial está presente
      if (sessionJson['idColaborador'].isNotEmpty) {
        debugPrint('UserProvider: Datos de colaborador cargados desde SharedPreferences (Web/Fallback).');
        dataLoaded = true;
      } else {
        debugPrint('UserProvider: No se encontraron datos de usuario en la base de datos ni en SharedPreferences.');
      }
    }

    // 3. ASIGNACIÓN FINAL Y LÓGICA DE TOKENS
    if (dataLoaded) {
      // Asignar variables internas del Provider desde sessionJson
      _idColaborador = sessionJson['idColaborador'] ?? '';
      _idEmpresa = sessionJson['idEmpresa'] ?? '';
      _email = sessionJson['email'] ?? '';
      _escuela = sessionJson['escuela'] ?? '';
      _fechaHora = sessionJson['fechaHora'] ?? '';
      _idCiclo = sessionJson['idCiclo'] ?? '';
      
      // Si manejas más variables específicas del colaborador, inclúyelas aquí.

      // 🔑 Lógica de Tokens: Intentar DB, sino usar el dato del sessionJson (SharedPreferences)
      if (_idColaborador.isNotEmpty) {
        final tokenData = await DatabaseHelper.instance.getTokens(_idColaborador);
        
        if (tokenData != null) {
          // Carga exitosa desde DB (Móvil)
          _idToken = tokenData['id_token'] ?? '';
          _fcmToken = tokenData['token_celular'] ?? '';
          debugPrint('UserProvider: Tokens cargados desde la base de datos (DB).');
        } else if (sessionJson['idToken'] != null && sessionJson['idToken'].isNotEmpty) {
          // Usar tokens recuperados de SharedPreferences (Web)
          _idToken = sessionJson['idToken'] ?? '';
          _fcmToken = sessionJson['fcmToken'] ?? '';
          debugPrint('UserProvider: Tokens cargados desde SharedPreferences (Web).');
        } else {
          debugPrint('UserProvider: No se encontraron tokens.');
        }
      }
    }

    notifyListeners();
  }

  Future<void> _saveSessionData() async {
    await DatabaseHelper.instance.saveSessionData(
      'session_data',
      {
        'idColaborador': _idColaborador, // ✅ [REF] Cambiado de idAlumno
        'idEmpresa': _idEmpresa,
        'email': _email,
        'escuela': _escuela,
        'idCiclo': _idCiclo,
        'fechaHora': _fechaHora,
      },
    );
    debugPrint('UserProvider: Datos de sesión guardados en la base de datos.');
  }

  // Nuevo método para asignación en memoria (Web)
  void setFcmTokenForWeb(String token) {
      _fcmToken = token;
  }

/// Guarda la sesión del colaborador en SharedPreferences para persistencia web
Future<void> saveColaboradorSessionToPrefs({
  required String idColaborador,
  required String idEmpresa,
  required String email,
  required String escuela,
  required String idCiclo,
  required String fechaHora,
  String? idToken, // Opcional, si se guarda aparte
  String? fcmToken, // Opcional, si se guarda aparte
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('idColaborador', idColaborador);
  await prefs.setString('idEmpresa', idEmpresa);
  await prefs.setString('email', email);
  await prefs.setString('escuela', escuela);
  await prefs.setString('idCiclo', idCiclo);
  await prefs.setString('fechaHora', fechaHora);
  await prefs.setString('idToken', idToken ?? ''); 
  await prefs.setString('fcmToken', fcmToken ?? '');

  debugPrint('UserProvider: Sesión de Colaborador guardada en SharedPreferences.');
}

  Future<void> setUserData({
    required String idColaborador,
    required String idEmpresa,
    required String email,
    required String escuela,
    required String idCiclo,
    required String fechaHora,
    String? idToken, 
    String? fcmToken,
  }) async {
    // 1. Asignar variables internas
    _idColaborador = idColaborador;
    _idEmpresa = idEmpresa;
    _email = email;
    _escuela = escuela;
    _idCiclo = idCiclo;
    _fechaHora = fechaHora;
    if (idToken != null) _idToken = idToken; 
    if (fcmToken != null) _fcmToken = fcmToken;

    // 2. Guardar en la DB Local (Móvil)
    await _saveSessionData();

    // ⭐️ 3. GUARDAR PERSISTENTEMENTE EN SHARED_PREFERENCES (Web/Fallback)
    await saveColaboradorSessionToPrefs(
      idColaborador: idColaborador,
      idEmpresa: idEmpresa,
      email: email,
      escuela: escuela,
      idCiclo: idCiclo,
      fechaHora: fechaHora,
      // Si manejas los tokens en el login, pásalos aquí:
       idToken: idToken,
      fcmToken: fcmToken,
    );
    
    debugPrint('UserProvider: Datos de sesión establecidos.');
    notifyListeners();
  }

  Map<String, List<AlumnoSalonModel>> get groupedAlumnosBySalon {
    // 1. Obtener los datos (seguro contra nulos)
    final List<AlumnoSalonModel> alumnos = colaboradorModel?.alumnosSalon ?? [];
    if (alumnos.isEmpty) return {};

    final Map<String, List<AlumnoSalonModel>> salones = {};

    // 2. Agrupar alumnos por el nombre del salón
    for (var alumno in alumnos) {
      if (salones.containsKey(alumno.salon)) {
        salones[alumno.salon]!.add(alumno);
      } else {
        salones[alumno.salon] = [alumno];
      }
    }

    // 3. Ordenamiento (Mejora de UX)
    // a. Ordenar alumnos dentro de cada salón por nombre completo
    salones.forEach((key, value) {
      // Nota: Asume que AlumnoSalonModel tiene el getter nombreCompleto
      value.sort((a, b) => a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));
    });
    
    // b. Ordenar los salones alfabéticamente
    final sortedKeys = salones.keys.toList()..sort();
    
    final sortedSalones = {for (var key in sortedKeys) key: salones[key]!};

    return sortedSalones;
}

  Future<void> enviarComentario(Comentario comentario) async {
    // ... (este método no cambia, solo su uso)
    if (_escuela.isEmpty || _idColaborador.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para enviar comentario.');
      throw Exception('Datos de sesión incompletos. Por favor, reinicia la app.');
    }

    final Map<String, String> body = {
      'escuela': _escuela,
      'id_colaborador': _idColaborador, // ✅ [REF] Cambiado de id_alumno
      'comentario': comentario.texto,
      'tipo_comentario': _mapTipoComentarioToString(comentario.tipo),
    };

    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.setComentariosAppEndpoint}');
    
    try {
      final response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        debugPrint('Comentario enviado exitosamente. ¡Gracias!');
      } else {
        String errorMessage = 'Ocurrió un error al enviar el comentario.';
        try {
          final responseData = json.decode(response.body);
          errorMessage = responseData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint('Error decodificando la respuesta del servidor: $e');
        }
        debugPrint('Error de servidor: ${response.statusCode} - $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Excepción al enviar comentario: $e');
      throw Exception('No se pudo conectar al servidor. Revisa tu conexión a internet.');
    }
  }

  String _mapTipoComentarioToString(TipoComentario tipo) {
    // ... (este método no cambia)
    switch (tipo) {
      case TipoComentario.problema:
        return 'Reportar un problema';
      case TipoComentario.idea:
        return 'Tengo una idea para mejorarla';
      case TipoComentario.desacuerdo:
        return 'No estoy de acuerdo con';
      case TipoComentario.felicitacion:
        return 'Felicitaciones';
      case TipoComentario.sugerencia:
        return 'Sugerencia';
    }
  }

  Future<Map<String, dynamic>> uploadCalificacionesArchivos({
    required String idAlumno,
    required String idSalon,
    // ❌ CAMBIO DE TIPO: Usamos el nuevo modelo en una lista
    required List<DatosArchivoASubir> archivosParaSubir, 
  }) async {
    final String escuelaCode = _escuela;
    
    // ⭐️ CORRECCIÓN CLAVE: CONCATENAR la URL base y el endpoint ⭐️
    final String fullApiUrl = 
        '${ApiConstants.apiBaseUrl}${ApiConstants.uploadFileCalificacion}';
    
    if (escuelaCode.isEmpty || idAlumno.isEmpty || idSalon.isEmpty) {
      return {'status': 'error', 'message': 'Datos de sesión o alumno/salón incompletos.'};
    }
    
    debugPrint('UserProvider: Preparando subida de archivos a $fullApiUrl para Alumno: $idAlumno, Salón: $idSalon');

    try {
      // 1. Crear la solicitud Multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(fullApiUrl),
      );

      // 2. Agregar parámetros de texto requeridos (Form-Encoded)
      request.fields['escuela'] = escuelaCode;
      request.fields['id_alumno'] = idAlumno;
      request.fields['id_salon'] = idSalon;

      // ⭐️ IMPRESIÓN DE DEPURACIÓN DE PARÁMETROS DE TEXTO ⭐️
      debugPrint('DEBUG SUBIDA: Parámetros de Texto:');
      request.fields.forEach((key, value) {
        debugPrint('  - $key: $value');
      });
      
      // 3. Agregar los archivos opcionales (archivo_calif_#)
      bool hasFilesToUpload = false;
      
      // ⭐️ IMPRESIÓN DE DEPURACIÓN DE ARCHIVOS A ADJUNTAR ⭐️
      debugPrint('DEBUG SUBIDA: Archivos a Adjuntar:');
      
      // 🔑 BUCLE CORREGIDO: Itera sobre el nuevo modelo de archivo
      for (final archivo in archivosParaSubir) {
        final String campoArchivo = archivo.nombreCampoApi;
        
        if (!kIsWeb) {
          // ====================================================================
          // 💻 LÓGICA PARA MÓVIL/DESKTOP (USA dart:io.File y fromPath)
          // ====================================================================
          final String? localPath = archivo.rutaLocal;
          if (localPath != null && localPath.isNotEmpty) {
            final file = File(localPath);
            if (await file.exists()) {
              hasFilesToUpload = true;
              
              request.files.add(
                await http.MultipartFile.fromPath(
                  campoArchivo, 
                  localPath,
                  filename: '${campoArchivo}_${idAlumno}_${DateTime.now().millisecondsSinceEpoch}.pdf',
                ),
              );
              debugPrint('  - Móvil: Campo API: $campoArchivo, Ruta Local: $localPath');
            } else {
              debugPrint('Advertencia Móvil: Archivo local no encontrado en la ruta: $localPath');
            }
          }
        } else {
          // ====================================================================
          // 🌐 LÓGICA PARA WEB (USA Bytes y fromBytes) - ¡SOLUCIÓN!
          // ====================================================================
          final Uint8List? bytes = archivo.bytesArchivo;
          final String? nombre = archivo.nombreArchivo;
          
          if (bytes != null && bytes.isNotEmpty && nombre != null && nombre.isNotEmpty) {
            hasFilesToUpload = true;
            
            // Adjuntar el archivo usando los BYTES (compatible con Web)
            request.files.add(
              http.MultipartFile.fromBytes(
                campoArchivo, 
                bytes,
                filename: nombre,
              ),
            );
            debugPrint('  - Web: Campo API: $campoArchivo, Nombre Archivo: $nombre');
          } else {
             debugPrint('Advertencia Web: Bytes o nombre del archivo no disponibles para: $campoArchivo');
          }
        }
      }

      if (!hasFilesToUpload) {
        return {'status': 'warning', 'message': 'No se seleccionó ningún archivo nuevo para subir.'};
      }
      
      // 4. Enviar la solicitud
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Respuesta de subida HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 5. Procesar la respuesta
        final rawData = json.decode(response.body) as Map<String, dynamic>;
        
        // La respuesta del JSON incluye status y message.
        return rawData; 
      } else {
        // Error HTTP no 200 (ej: 404, 500)
        return {'status': 'error', 'message': 'Error de servidor: ${response.statusCode}'};
      }
    } on SocketException {
      return {'status': 'error', 'message': 'Fallo de conexión a internet.'};
    } on Exception catch (e) {
      return {'status': 'error', 'message': 'Excepción al subir archivo: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteCalificacionesArchivo({
    
        required String idAlumno,
        required String idSalon,
        required String campoAActualizar,
        required String archivoAEliminar,
    }) async {
        final url = Uri.parse('${ApiConstants.apiBaseUrl}/delete_file_calificacion');
        final String escuelaCode = _escuela;
        final response = await http.post(
            url,
            body: {
                'escuela': escuelaCode, 
                'id_alumno': idAlumno,
                'id_salon': idSalon,
                'campo_a_actualizar': campoAActualizar,
                'archivo_a_eliminar': archivoAEliminar,
            },
        );

        if (response.statusCode == 200) {
            return json.decode(response.body);
        } else {
            // Manejar errores HTTP, por ejemplo, devolviendo un mapa de error
            //debugPrint(response.body);
            return {'status': 'error', 'message': 'Fallo en la conexión al servidor. Código: ${response.statusCode}'};
        }
    }

    // Función auxiliar para mapear el texto del combo al código de la API
String _mapDestinatarioToApiCode(String destinatario) {
    switch (destinatario) {
        case 'Todos los Alumnos':
            return 'Alumnos';
        case 'Todos los Colaboradores':
            return 'Colaboradores';
        case 'Nivel Educativo':
            // Asumo que el API espera 'AlumnosNivelEdu' para evitar ambigüedad con 'Nivel Educativo'
            return 'AlumnosNivelEdu';
        case 'Salón':
            // Asumo que el API espera 'AlumnosSalon' para evitar ambigüedad con 'Salón'
            return 'AlumnosSalon';
        case 'Alumno Específico':
            return 'AlumnoEspecifico';
        case 'Colaborador Específico':
            return 'ColaboradorEspecifico';
        case 'Todos':
        default:
            return 'Todos';
    }
}

Future<Map<String, dynamic>> saveAviso(Map<String, dynamic> avisoData) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.setCreaAvisoEndpoint}');

    // --- 1. Inicializar IDs (Mantenido) ---
    String idSalon = '0';
    String idAlumno = '0';
    String idColaboradorDestino = '0'; 

    // Datos de la sesión
    final String idTokenValue = _idToken ?? ''; 
    final String escuelaCode = _escuela;
    final String idEmpresaValue = _idEmpresa; 
    final String idCicloValue = _idCiclo;     
    
    final String tipoDestinatario = avisoData['destinatario_tipo'];
    final String? valorEspecifico = avisoData['destinatario_valor'];
    final String tipoRespuesta = avisoData['requiere_respuesta'];
    
    final RegExp regExp = RegExp(r'\((\d+)\)'); 

    // --- 2. Determinar los IDs de Destino Específico (Mantenido) ---
    if (tipoDestinatario == 'Salón' && valorEspecifico != null) {
         final AvisoSalaModel? salonData = colaboradorModel?.avisoSalones.firstWhere(
            (s) => s.salon == valorEspecifico, 
            // ignore: cast_from_null_always_fails
            orElse: () => null as AvisoSalaModel , 
         );
         idSalon = salonData?.idSalon ?? '0';
         
    } else if (tipoDestinatario == 'Alumno Específico' && valorEspecifico != null) {
        final match = regExp.firstMatch(valorEspecifico);
        idAlumno = match?.group(1) ?? '0';
        
    } else if (tipoDestinatario == 'Colaborador Específico' && valorEspecifico != null) {
        final AvisoColaboradorModel? colaboradorData = colaboradorModel?.avisoColaboradores.firstWhere(
            (c) => c.nombreCompleto == valorEspecifico,
            // ignore: cast_from_null_always_fails
            orElse: () => null as AvisoColaboradorModel, 
        );
        idColaboradorDestino = colaboradorData?.idColaborador ?? '0';
    } 
    
    // --- 3. Mapeo de la Sección (seccion) (Mantenido) ---
    final String apiSeccionCode = _mapDestinatarioToApiCode(tipoDestinatario);

    // Obtener la cadena de opciones concatenadas que viene de la vista
    final String opcionesConcatenadas = avisoData['opciones_multiples'] ?? '';
    List<String> opcionesList = [];

    if (tipoRespuesta == 'Seleccion' && opcionesConcatenadas.isNotEmpty) {
        opcionesList = opcionesConcatenadas
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    }

    String opcion1 = opcionesList.isNotEmpty ? opcionesList[0] : '';
    String opcion2 = opcionesList.length > 1 ? opcionesList[1] : '';
    String opcion3 = opcionesList.length > 2 ? opcionesList[2] : '';

    // --- 4. Preparar el Body para la API (Mantenido) ---
    final Map<String, String> body = {
        'escuela': escuelaCode,
        'id_calendario': avisoData['id_calendario'] ?? '0', 
        'id_colaborador': idColaboradorDestino, 
        'id_salon': idSalon, 
        'id_alumno': idAlumno, 
        'id_token': idTokenValue, 
        'titulo': avisoData['titulo'],
        'comentario': avisoData['cuerpo'],
        'id_empresa': idEmpresaValue,
        'id_ciclo': idCicloValue,
        'seccion': apiSeccionCode, 
        'tipo_respuesta': tipoRespuesta, 
        'fecha_inicio': avisoData['fecha_inicio'],
        'fecha_fin': avisoData['fecha_fin'],
        'opcion_1': opcion1, 
        'opcion_2': opcion2, 
        'opcion_3': opcion3,
        if (tipoDestinatario == 'Nivel Educativo') 'nivel_educativo_valor': valorEspecifico ?? '',
    };

    debugPrint('UserProvider: Enviando aviso a API: $body');
        
    // --- 5. Ejecución y Manejo de Respuesta ---
    try {
        final response = await http.post(url, body: body);

        debugPrint('UserProvider: Código de estado de la respuesta: ${response.statusCode}');
        
        if (response.body.isEmpty) {
            return {'success': false, 'message': 'Respuesta vacía del servidor (${response.statusCode}).'};
        }
        
        final Map<String, dynamic> result = json.decode(response.body);

        if (response.statusCode == 200 && result['status'] == 'Correcto') {
            
            // ⭐️ LÓGICA DE PERSISTENCIA LOCAL (SOLO SI EL API ES EXITOSO) ⭐️
            
            final String originalId = avisoData['id_calendario'] ?? '0';
            final bool isNew = originalId == '0'; 
            
            final String idAvisoServer = result['message']?.toString() ?? originalId;
            
            // 1. Crear el mapa de datos para guardar localmente (DB/SP)
            final Map<String, dynamic> avisoLocal = {
                'id_aviso': idAvisoServer, 
                'id_calendario': idAvisoServer, 
                'titulo': avisoData['titulo'],
                'comentario': avisoData['cuerpo'], 
                'seccion': apiSeccionCode,
                'valor_especifico': valorEspecifico ?? '', 
                'tipo_respuesta': tipoRespuesta,
                'fecha_inicio': avisoData['fecha_inicio'],
                'fecha_fin': avisoData['fecha_fin'],
                'opcion_1': opcion1,
                'opcion_2': opcion2,
                'opcion_3': opcion3,
            };

            debugPrint('UserProvider: Aviso ${isNew ? 'creado' : 'editado'}. ID de calendario asignado para persistencia local: $idAvisoServer');

            // 2. Intentar guardar/actualizar en la Base de Datos (Móvil)
            if (!kIsWeb) { // 👈 ÚNICO CAMBIO: Omitir en Web
                try {
                    await _dbHelper.saveAvisoCreado(avisoLocal); 
                    debugPrint('UserProvider: Aviso creado guardado/actualizado exitosamente en DB local (Mobile).');
                } catch (e) {
                    debugPrint('UserProvider: Fallo al guardar aviso creado en DB. Usando SharedPreferences. Error: $e');
                }
            } else {
                 debugPrint('UserProvider: Ejecutando en Web. Se omite el guardado en DB local.');
            }
            
            // 3. Actualizar la lista en memoria (_avisosCreados) (Válido para todas las plataformas)
            if (isNew) {
                _avisosCreados.insert(0, avisoLocal); 
            } else {
                final int activoIndex = _avisosCreados.indexWhere((a) => a['id_calendario'] == originalId);

                if (activoIndex != -1) {
                    _avisosCreados[activoIndex] = avisoLocal;
                } else {
                    _avisosCreados.insert(0, avisoLocal); 
                }
            }

            // 4. Guardamos la lista en SharedPreferences (Válido para todas las plataformas)
            await _saveAvisosCreadosToPrefs(_avisosCreados, _prefsAvisosCreadosKey);
            
            // 5. Notificar a las vistas
            notifyListeners(); 

            final String action = isNew ? 'creado' : 'actualizado';
            return {'success': true, 'message': 'Aviso ${action} con éxito. ID: $idAvisoServer'};
        
        } else {
            // Fallo de la API (Mantenido)
            dynamic apiMessage = result['message'];
            String errorMessage;
            
            if (apiMessage is Map) {
                errorMessage = apiMessage.toString();
            } else {
                errorMessage = apiMessage?.toString() ?? 'Error desconocido.';
            }
            
            return {'success': false, 'message': errorMessage};
        }
    } catch (e) {
        debugPrint('UserProvider: Excepción al guardar aviso: $e');
        return {'success': false, 'message': 'Error de conexión: ${e.toString()}'};
    }
}

Future<Map<String, dynamic>> deleteAvisoCreado(String idAviso) async {
    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.eliminaAviso}');

    final String idTokenValue = _idToken ?? ''; 
    final String escuelaCode = _escuela;
    final String idEmpresaValue = _idEmpresa; 
    
    // Los parámetros son: escuela, id_calendario, id_token, id_empresa
    final Map<String, String> body = {
        'escuela': escuelaCode,
        'id_calendario': idAviso, 
        'id_token': idTokenValue, 
        'id_empresa': idEmpresaValue,
        // No se requiere id_ciclo según tu captura de Postman
    };

    // ⭐️ DEBUG PRINT AÑADIDO: Muestra la URL completa ⭐️
    debugPrint('UserProvider: URL de eliminación: $url');
    // ⭐️ DEBUG PRINT EXISTENTE: Muestra el cuerpo (parámetros) de la solicitud ⭐️
    debugPrint('UserProvider: Enviando solicitud de eliminación para ID: $idAviso con BODY: $body');

    try {
        final response = await http.post(url, body: body);

        debugPrint('UserProvider: Código de estado de la respuesta: ${response.statusCode}');
        
        if (response.body.isEmpty) {
            return {'success': false, 'message': 'Respuesta vacía del servidor (${response.statusCode}).'};
        }
        
        final Map<String, dynamic> result = json.decode(response.body);

        // ⭐️ DEBUG PRINT ADICIONAL: Muestra la respuesta de la API ⭐️
        debugPrint('UserProvider: Respuesta de API (JSON): $result');

        if (response.statusCode == 200 && result['status'] == 'Correcto') {
            
            // 1. Eliminar de la Base de Datos Local (Móvil)
            try {
                await _dbHelper.deleteAvisoCreado(idAviso);
                debugPrint('UserProvider: Aviso con ID $idAviso eliminado de la DB local.');
            } catch (e) {
                debugPrint('UserProvider: Fallo al eliminar aviso creado de DB. Continuando con memoria/prefs. Error: $e');
            }
            
            // 2. Eliminar de la lista en memoria (_avisosCreados)
            // La clave de búsqueda es 'id_calendario'
            _avisosCreados.removeWhere((aviso) => aviso['id_calendario'] == idAviso);
            debugPrint('UserProvider: Aviso con ID $idAviso eliminado de la lista en memoria.');

            // 3. Guardamos la lista actualizada en SharedPreferences (Fallback)
            await _saveAvisosCreadosToPrefs(_avisosCreados, _prefsAvisosCreadosKey);
            
            // 4. Notificar a las vistas
            notifyListeners(); 

            // Devolver éxito a la vista
            final String message = result['message']?.toString() ?? 'Aviso eliminado con éxito.';
            return {'success': true, 'message': message};
        
        } else {
            // Fallo de la API
            final String errorMessage = result['message']?.toString() ?? 'Error desconocido al intentar eliminar.';
            return {'success': false, 'message': 'Error de API al eliminar aviso: $errorMessage'};
        }
    } catch (e) {
        debugPrint('UserProvider: Excepción al eliminar aviso: $e');
        return {'success': false, 'message': 'Error de conexión: ${e.toString()}'};
    }
}

  Future<List<AlumnoAsistenciaModel>> fetchAlumnosPorCurso({
      required String idCurso,
      required TipoCurso tipoCurso,
    }) async {
      
      // Obtener los datos base del colaborador para la URL
      final String escuelaCode = _escuela;
      final String idMateriaAlumno = _idMateriaAlumno ?? '';
      final String idToken = _idToken ?? ''; 
      final String fechaHoraApiCall = _fechaHora.isNotEmpty ? _fechaHora : generateApiFechaHora();

      if (escuelaCode.isEmpty || idColaborador.isEmpty || idCurso.isEmpty) {
        debugPrint('UserProvider: Datos de sesión o idCurso incompletos para cargar alumnos.');
        return [];
      }
      
      // 1. Determinar el endpoint y la URL
      String apiEndpoint;
      if (tipoCurso == TipoCurso.materia) {
        apiEndpoint = ApiConstants.getCursoListaAlumnos(escuelaCode,  idMateriaAlumno,fechaHoraApiCall, idToken);
      } else {
        apiEndpoint = ApiConstants.getAlumnosClub(escuelaCode,  idCurso, fechaHoraApiCall, idToken);
      }

      final alumnosDataUrl = Uri.parse(apiEndpoint);
      
      debugPrint('UserProvider: Llamando a API de alumnos para ${tipoCurso.name} (ID: $idCurso): $alumnosDataUrl');
      
      try {
        final response = await http.get(alumnosDataUrl);

        if (response.statusCode == 200) {

          // 🚨 NUEVOS PRINTS PARA DEBUGGING 🚨
          debugPrint('UserProvider: Status de respuesta de alumnos: ${response.statusCode}');
          debugPrint('UserProvider: Cuerpo de la respuesta de alumnos: ${response.body}'); // ✅ ESTO TE MOSTRARÁ EL JSON

          final rawData = json.decode(response.body);

          if (rawData is List) {
            // 2. Parsear la lista de alumnos
            final List<AlumnoAsistenciaModel> alumnos = rawData
                .map((e) => AlumnoAsistenciaModel.fromJson(e as Map<String, dynamic>))
                .toList();
                
            debugPrint('UserProvider: Se cargaron ${alumnos.length} alumnos para el curso ID $idCurso.');
            return alumnos;
          } else {
            debugPrint('UserProvider: La API devolvió un formato inesperado (no es una lista).');
            return [];
          }
        } else {
          debugPrint('UserProvider: Error HTTP al cargar alumnos (${response.statusCode}).');
          return [];
        }
      } on SocketException {
        debugPrint('UserProvider: SocketException al cargar alumnos. Sin conexión.');
      } on http.ClientException {
        debugPrint('UserProvider: ClientException al cargar alumnos. Problema de red.');
      } catch (e) {
        debugPrint('UserProvider: Excepción general al cargar alumnos: $e.');
      }

      return [];
    }

    Future<List<Map<String, dynamic>>> fetchAlumnosParaCalificar({
      required String idCurso, // Este será el idMateriaClase/idClub
      required TipoCurso tipoCurso,
    }) async {
      
      // Obtener los datos base del colaborador para la URL
      final String escuelaCode = _escuela;
      // Usaremos idCurso (que es el idMateriaClase) para el endpoint de materia, 
      // ya que la API no requiere _idMateriaAlumno (variable de estado) aquí.
      final String idMateriaClase = idCurso; 
      final String idToken = _idToken ?? ''; 
      final String fechaHoraApiCall = _fechaHora.isNotEmpty ? _fechaHora : generateApiFechaHora();

      if (escuelaCode.isEmpty || idColaborador.isEmpty || idMateriaClase.isEmpty) {
        debugPrint('UserProvider: Datos de sesión o idCurso/idMateriaClase incompletos para cargar alumnos para calificar.');
        return [];
      }
      
      // 1. Determinar el endpoint y la URL
      String apiEndpoint;
      if (tipoCurso == TipoCurso.materia) {
        // ✅ Usamos el idCurso/idMateriaClase en lugar de la variable de estado _idMateriaAlumno.
        // ASUMIMOS que ApiConstants.getCursoListaAlumnos() usa el segundo parámetro para filtrar la materia.
        apiEndpoint = ApiConstants.getCursoListaAlumnos(escuelaCode,  idMateriaClase, fechaHoraApiCall, idToken);
      } else {
        apiEndpoint = ApiConstants.getAlumnosClub(escuelaCode,  idCurso, fechaHoraApiCall, idToken);
      }

      final alumnosDataUrl = Uri.parse(apiEndpoint);
       debugPrint('--- [API CALIFICACIONES - CONSULTA] ---');
      debugPrint('URL de la API: $alumnosDataUrl');
      
      debugPrint('UserProvider: Llamando a API de alumnos para CALIFICAR ${tipoCurso.name} (ID: $idCurso): $alumnosDataUrl');
      
      try {
        final response = await http.get(alumnosDataUrl);

        if (response.statusCode == 200) {

          final rawData = json.decode(response.body);
            debugPrint('JSON de Respuesta (Status 200): ${response.body}');
          debugPrint('--- [FIN LOG CALIFICACIONES - CONSULTA] ---');

          if (rawData is List) {
            // 2. Devolvemos la lista de Map<String, dynamic> (JSON crudo)
            // Esto es crucial para que la UI pueda manejar campos dinámicos de P1, P2, OB, etc.
            final List<Map<String, dynamic>> alumnosData = rawData
                .whereType<Map<String, dynamic>>()
                .toList();
                
            debugPrint('UserProvider: Se cargaron ${alumnosData.length} alumnos para CALIFICAR (ID $idCurso).');
            return alumnosData;
          } else {
            debugPrint('UserProvider: La API devolvió un formato inesperado para calificaciones (no es una lista).');
            return [];
          }
        } else {
          debugPrint('UserProvider: Error HTTP al cargar alumnos para calificar (${response.statusCode}).');
          return [];
        }
      } on SocketException {
        debugPrint('UserProvider: SocketException al cargar alumnos para calificar. Sin conexión.');
      } on http.ClientException {
        debugPrint('UserProvider: ClientException al cargar alumnos para calificar. Problema de red.');
      } catch (e) {
        debugPrint('UserProvider: Excepción general al cargar alumnos para calificar: $e.');
      }

      return [];
    }
  
  Future<void> setSelectedCafeteriaPeriod(String? idPeriodo, String? idCiclo) async {
    // ... (este método no cambia)
    if (_selectedCafeteriaPeriodId != idPeriodo || _selectedCafeteriaCicloId != idCiclo) {
      _selectedCafeteriaPeriodId = idPeriodo;
      _selectedCafeteriaCicloId = idCiclo;
      notifyListeners();

      debugPrint('UserProvider: Filtro de cafetería cambiado a Periodo: $idPeriodo, Ciclo: $idCiclo. Recargando movimientos.');
      await fetchAndLoadCafeteriaMovimientosData(
        idColaborador: _idColaborador, // ✅ [REF] Cambiado de idAlumno
        idPeriodo: _selectedCafeteriaPeriodId,
        idCiclo: _selectedCafeteriaCicloId,
        forceRefresh: true,
      );
    }
  }

  Future<void> _clearColaboradorPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 🛑 CRÍTICO: Eliminar las claves de sesión principales del colaborador
    await prefs.remove('idColaborador');
    await prefs.remove('idEmpresa');
    await prefs.remove('email');
    await prefs.remove('escuela');
    await prefs.remove('idCiclo');
    await prefs.remove('fechaHora');
    
    // 🔑 CRÍTICO: Eliminar los tokens
    await prefs.remove('idToken');
    await prefs.remove('fcmToken');
    
    // (Añade aquí cualquier otra clave que uses en saveColaboradorSessionToPrefs)

    //appLog('UserProvider: SharedPreferences del Colaborador limpiado.');
  } 

  Future<void> clearUserData() async {
    _idColaborador = ''; // ✅ [REF] Cambiado de _idAlumno
    _idEmpresa = '';
    _email = '';
    _escuela = '';
    _idCiclo = '';
    _fechaHora = '';
    _rutaLogoEscuela = '';

    _selectedCafeteriaPeriodId = null;
    _selectedCafeteriaCicloId = null;
    _currentColaboradorDetails = null; // ✅ [REF] Cambiado de _currentAlumnoDetails

    _lastSchoolDataFetch = null;
    _lastColaboradorDataFetch = null; // ✅ [REF] Cambiado de _lastAlumnoDataFetch
    _lastAvisosDataFetch = null;
    _lastArticulosCafDataFetch = null;
    _lastCafeteriaMovimientosDataFetch = null;

    _escuelaModel = null;
    _colaboradorModel = null; // ✅ [REF] Cambiado de _alumnoModel
    _avisos = [];
    _articulosCaf = [];
    _cafeteriaMovimientos = [];
    _colores = null;
    
    // ✅ [REF] Eliminadas las variables para pagos, cfdi, y materias

    notifyListeners();

    await DatabaseHelper.instance.clearAllData();

    // 2. 🚀 CRÍTICO: Limpiar Shared Preferences (Web/Fallback)
    await _clearColaboradorPrefs();
    debugPrint('UserProvider: Datos de usuario y base de datos local limpiados.');
  }

  String generateApiFechaHora() {
    // ... (este método no cambia)
    final now = DateTime.now();
    final formatter = DateFormat('ddMMyyyyHHmmss');
    return formatter.format(now);
  }

   /// ✅ NUEVO MÉTODO: Genera la fecha actual en formato 'AAAA-MM-DD'.
  String generarFechaActualApi() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(now);
  }

  void triggerAutoRefresh() {
    // ... (este método no cambia)
    autoRefreshTrigger.value = null;
    debugPrint('UserProvider: Señal de auto-refresco activada.');
  }

  bool shouldFetchSchoolDataFromApi() {
    // ... (este método no cambia)
    if (_lastSchoolDataFetch == null) {
      debugPrint('UserProvider: No hay marca de tiempo para datos de escuela. Se necesita API.');
      return true;
    }
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: ApiConstants.minutosRecarga));
    final bool needsFetch = _lastSchoolDataFetch!.isBefore(tenMinutesAgo);
    debugPrint('UserProvider: Última carga de escuela: $_lastSchoolDataFetch. Hace 10 min: $tenMinutesAgo. ¿Necesita API? $needsFetch');
    return needsFetch;
  }
  
  bool shouldFetchColaboradorDataFromApi() {
    // ✅ [REF] Nuevo método para la lógica de caché del colaborador
    if (_lastColaboradorDataFetch == null) {
      debugPrint('UserProvider: No hay marca de tiempo para datos de colaborador. Se necesita API.');
      return true;
    }
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: ApiConstants.minutosRecarga));
    final bool needsFetch = _lastColaboradorDataFetch!.isBefore(tenMinutesAgo);
    debugPrint('UserProvider: Última carga de colaborador: $_lastColaboradorDataFetch. Hace 10 min: $tenMinutesAgo. ¿Necesita API? $needsFetch');
    return needsFetch;
  }
  
  bool shouldFetchAvisosDataFromApi() {
    // ... (este método no cambia)
    if (_lastAvisosDataFetch == null) {
      debugPrint('UserProvider: No hay marca de tiempo para datos de avisos. Se necesita API.');
      return true;
    }
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: ApiConstants.minutosRecarga));
    final bool needsFetch = _lastAvisosDataFetch!.isBefore(tenMinutesAgo);
    debugPrint('UserProvider: Última carga de avisos: $_lastAvisosDataFetch. Hace 10 min: $tenMinutesAgo. ¿Necesita API? $needsFetch');
    return needsFetch;
  }

  bool shouldFetchArticulosCafDataFromApi() {
    // ... (este método no cambia)
    if (_lastArticulosCafDataFetch == null) {
      debugPrint('UserProvider: No hay marca de tiempo para datos de artículos de cafetería. Se necesita API.');
      return true;
    }
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: ApiConstants.minutosRecarga));
    final bool needsFetch = _lastArticulosCafDataFetch!.isBefore(tenMinutesAgo);
    debugPrint('UserProvider: Última carga de artículos de cafetería: $_lastArticulosCafDataFetch. Hace 10 min: $tenMinutesAgo. ¿Necesita API? $needsFetch');
    return needsFetch;
  }
  
  bool shouldFetchCafeteriaMovimientosDataFromApi() {
    // ... (este método no cambia)
    if (_lastCafeteriaMovimientosDataFetch == null) {
      debugPrint('UserProvider: No hay marca de tiempo para movimientos de cafetería. Se necesita API.');
      return true;
    }
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: ApiConstants.minutosRecarga));
    final bool needsFetch = _lastCafeteriaMovimientosDataFetch!.isBefore(tenMinutesAgo);
    debugPrint('UserProvider: Última carga de movimientos de cafetería: $_lastCafeteriaMovimientosDataFetch. Hace 10 min: $tenMinutesAgo. ¿Necesita API? $needsFetch');
    return needsFetch;
  }

  // ✅ [REF] Eliminados los métodos shouldFetch para CFDI, Pagos, Cargos, Materias

  Future<Map<String, String>> obtenerInfoDispositivo() async {
    // ... (este método no cambia)
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'modelo_marca': '${androidInfo.brand} ${androidInfo.model}',
        'sistema_operativo': 'Android ${androidInfo.version.release}',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'modelo_marca': '${iosInfo.name} ${iosInfo.model}',
        'sistema_operativo': '${iosInfo.systemName} ${iosInfo.systemVersion}',
      };
    } else {
      return {
        'modelo_marca': 'Desconocido',
        'sistema_operativo': 'Desconocido',
      };
    }
  }

  Future<void> actualizarInfoToken({
    required String escuela,
    required String idColaborador,
    required String tokenCelular,
    required String status,
  }) async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String modeloMarca = '';
      String? sistemaOperativo = '';

      // 🛑 CORRECCIÓN CLAVE: Usar kIsWeb para la lógica de plataforma.
      if (kIsWeb) {
        // ✅ WEB: Usamos la información del navegador
        final WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        modeloMarca = webInfo.browserName.name.toUpperCase();
        sistemaOperativo = webInfo.platform;
        
      } else if (Platform.isAndroid) {
        // 🔵 MÓVIL/DESKTOP: Android (Usando dart:io)
        final androidInfo = await deviceInfo.androidInfo;
        modeloMarca = '${androidInfo.manufacturer} ${androidInfo.model}';
        sistemaOperativo = 'Android ${androidInfo.version.release}';

      } else if (Platform.isIOS) {
        // 🔵 MÓVIL/DESKTOP: iOS (Usando dart:io)
        final iosInfo = await deviceInfo.iosInfo;
        modeloMarca = '${iosInfo.name} ${iosInfo.model}';
        sistemaOperativo = 'iOS ${iosInfo.systemVersion}';
      }

      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.updateInfoTokenEndpoint}');
      final body = {
        'escuela': escuela,
        'id_colaborador': idColaborador,
        'token_celular': tokenCelular,
        'status': status,
        if (status == 'activo') ...{
          'modelo_marca': modeloMarca,
          'sistema_operativo': sistemaOperativo,
        }
      };

      debugPrint('Enviando actualización token con body: $body');

      final response = await http.post(url, body: body);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'correcto') {
        debugPrint('Token actualizado correctamente');
        final String idToken = responseData['id_token']?.toString() ?? '';
        _idToken = idToken;
        _tokenCelular = tokenCelular;
        
        // 🛑 CORRECCIÓN CLAVE: Lógica de Persistencia
        if (_idToken != null && _idToken!.isNotEmpty) {
            // SOLO EN MÓVIL: Intentar guardar en la base de datos (SQLite)
            if (!kIsWeb) {
                await DatabaseHelper.instance.saveTokens(idColaborador, _idToken!, _tokenCelular!);
                debugPrint('UserProvider: Tokens guardados en la base de datos local.');
            } else {
                debugPrint('UserProvider: Tokens actualizados en memoria (Web).');
            }
        } else {
            debugPrint('El ID Token retornado está vacío o es nulo.');
        }

        notifyListeners();
      } else {
        debugPrint('Error actualizando token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Excepción actualizando token: $e');
    }
  }
  

  Future<void> processAndSaveSchoolColors(Map<String, dynamic> apiResponse) async {
    // ... (este método no cambia)
    final newColores = Colores.fromMap(apiResponse);
    await DatabaseHelper.instance.saveColoresData(newColores);
    _colores = newColores;
    debugPrint('UserProvider: Colores de la app guardados y estado actualizado.');
    notifyListeners();
  }

  Future<EscuelaModel?> fetchAndLoadSchoolData({bool forceRefresh = false}) async {
    // ... (este método no cambia)
    final String escuelaCode = _escuela;
    final String idEmpresa = _idEmpresa;
    final String fechaHoraApiCall = _fechaHora.isNotEmpty ? _fechaHora : generateApiFechaHora();
    final String idColaborador = _idColaborador;
    final String idPersonaParam = '0';
    final String idToken = _idToken ?? '';

    if (escuelaCode.isEmpty || idEmpresa.isEmpty || fechaHoraApiCall.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para cargar datos de la escuela.');
      _escuelaModel = null;
      notifyListeners();
      return null;
    }

    Map<String, dynamic>? schoolJsonData;
    debugPrint('UserProvider: Intentando cargar datos de la escuela desde el caché local...');
    final cachedData = await DatabaseHelper.instance.getSchoolData(idEmpresa);

    if (cachedData != null) {
      schoolJsonData = cachedData['data_json'];
      _lastSchoolDataFetch = cachedData['last_fetch_time'];
      debugPrint('UserProvider: Datos de la escuela cargados desde el caché local.');
    }

    notifyListeners();

    if (forceRefresh || shouldFetchSchoolDataFromApi()) {
      debugPrint('UserProvider: Intentando obtener datos de la escuela desde la API...');
      try {
        final schoolDataUrl = Uri.parse(ApiConstants.getSchoolData(escuelaCode, idEmpresa, fechaHoraApiCall, idColaborador, idPersonaParam, idToken));
        final schoolResponse = await http.get(schoolDataUrl);

        if (schoolResponse.statusCode == 200) {
          final rawData = json.decode(schoolResponse.body);
          if (rawData['status'] == 'success' && rawData['school'] != null) {
            await DatabaseHelper.instance.saveSchoolData(idEmpresa, rawData);
            _lastSchoolDataFetch = DateTime.now();
            debugPrint('UserProvider: Datos de la escuela obtenidos y guardados desde la API.');
            schoolJsonData = rawData;
          } else {
            debugPrint('UserProvider: La API de la escuela devolvió estado no exitoso o sin datos. Manteniendo caché.');
          }
        } else {
          debugPrint('UserProvider: Error HTTP al cargar datos de la escuela (${schoolResponse.statusCode}). Manteniendo caché.');
        }
      } on SocketException {
        debugPrint('UserProvider: SocketException al cargar datos de la escuela. Sin conexión. Mostrando datos cacheados.');
      } on http.ClientException {
        debugPrint('UserProvider: ClientException al cargar datos de la escuela. Problema de red. Mostrando datos cacheados.');
      } catch (e) {
        debugPrint('UserProvider: Excepción al cargar datos de la escuela: $e. Mostrando datos cacheados.');
      }
    }

    if (schoolJsonData != null) {
      try {
        _escuelaModel = EscuelaModel.fromJson(schoolJsonData);
        _idCiclo = _escuelaModel!.cicloEscolar.idCiclo;
        _rutaLogoEscuela = _escuelaModel!.rutaLogo;
        notifyListeners();
        debugPrint('UserProvider: EscuelaModel actualizado (final).');
        return _escuelaModel;
      } catch (e) {
        debugPrint('UserProvider: Error al parsear EscuelaModel (final): $e');
        _escuelaModel = null;
        notifyListeners();
        return null;
      }
    }

    _escuelaModel = null;
    notifyListeners();
    debugPrint('UserProvider: No se pudieron cargar los datos de la escuela desde la API o el caché.');
    return null;
  }

  void _procesarAlumnosSalon(Map<String, dynamic> rawData) {
    // 'alumnos_salon' es la clave que esperamos en el JSON completo
    final rawAlumnosSalon = rawData['alumnos_salon'] as List<dynamic>? ?? [];
    
    // Convertimos cada mapa a AlumnoSalonModel y actualizamos la lista de estado
    _alumnosSalon = rawAlumnosSalon
        .map((e) => AlumnoSalonModel.fromJson(e as Map<String, dynamic>))
        .toList();

    debugPrint('UserProvider: Se procesaron ${_alumnosSalon.length} registros de alumnos por salón.');
}

  Future<ColaboradorModel?> fetchAndLoadColaboradorData({bool forceRefresh = false}) async {
    final String escuelaCode = _escuela;
    final String idColaborador = _idColaborador;
    final String idEmpresa = _idEmpresa; // Usado como id_escuela
    final String idCicloEscolar = _idCiclo;
    final String fechaHoraApiCall = _fechaHora.isNotEmpty ? _fechaHora : generateApiFechaHora();
    final String idToken = _idToken ?? ''; 

    if (escuelaCode.isEmpty || idColaborador.isEmpty || idEmpresa.isEmpty || fechaHoraApiCall.isEmpty || idCicloEscolar.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para cargar datos del colaborador. Faltan: escuelaCode=$escuelaCode, idColaborador=$idColaborador, idEmpresa=$idEmpresa, fechaHoraApiCall=$fechaHoraApiCall, idCicloEscolar=$idCicloEscolar');
      _colaboradorModel = null;
      _currentColaboradorDetails = null;
      notifyListeners();
      return null;
    }

    // Usaremos esta variable para mantener el JSON completo (de caché o API)
    Map<String, dynamic>? colaboradorJsonData;
    ColaboradorModel? tempColaboradorModel;

    debugPrint('UserProvider: Intentando cargar datos del colaborador desde el caché local...');
    final cachedData = await DatabaseHelper.instance.getColaboradorData(idColaborador);
    
    // ⭐️ INTEGRACIÓN (INICIO): Cargar la estructura de la boleta desde el caché/DB
    _boletaEncabezados = await DatabaseHelper.instance.getBoletaEncabezados();

    if (cachedData != null) {
      colaboradorJsonData = cachedData['data_json'];
      _lastColaboradorDataFetch = cachedData['last_fetch_time'];
      debugPrint('UserProvider: Datos del colaborador cargados desde el caché local.');
      
      try {
        // ✅ Carga inicial desde caché (para mostrar algo rápido)
        tempColaboradorModel = ColaboradorModel.fromJson(colaboradorJsonData!);
        _colaboradorModel = tempColaboradorModel;
        _currentColaboradorDetails = tempColaboradorModel;

        _procesarAlumnosSalon(colaboradorJsonData);

        // ⭐️ Actualizar la variable del Provider con la data del modelo, si existe en caché
        if (tempColaboradorModel.encabezadosBoleta.isNotEmpty) {
           _boletaEncabezados = tempColaboradorModel.encabezadosBoleta;
        }

        notifyListeners(); // Notificamos para mostrar datos rápidos de caché

      } catch (e) {
        // Fallo de parseo debido a formato obsoleto de caché
        debugPrint('UserProvider: Error al parsear ColaboradorModel desde el caché. Esto es común si la estructura de la API cambió. Forzando API: $e');
        _colaboradorModel = null;
        _currentColaboradorDetails = null;
        forceRefresh = true; // Forzar API si falla la caché
      }
    } else {
      debugPrint('UserProvider: No hay datos de colaborador en caché.');
    }

    // 2. Lógica de API
    if (forceRefresh || shouldFetchColaboradorDataFromApi()) {
      debugPrint('UserProvider: Intentando obtener datos del colaborador desde la API...');
      try {
        // ✅ [USO CORRECTO DE LA URL]: Patrón: id_colaborador/id_escuela/id_ciclo_escolar/fechahora/id_token
        final colaboradorDataUrl = Uri.parse(
          ApiConstants.getColaboradorAllData(escuelaCode,idColaborador, idEmpresa, idCicloEscolar, fechaHoraApiCall, idToken)
        );
        debugPrint('UserProvider: Llamando a la URL de la API: $colaboradorDataUrl');
        
        final colaboradorResponse = await http.get(colaboradorDataUrl);
        
        debugPrint('UserProvider: Status de respuesta: ${colaboradorResponse.statusCode}');
        debugPrint('UserProvider: Cuerpo de la respuesta: ${colaboradorResponse.body}');

        if (colaboradorResponse.statusCode == 200) {
          final rawData = json.decode(colaboradorResponse.body);
          
          // ✅ Validamos el éxito y que contenga los datos clave
          if (rawData is Map<String, dynamic> && rawData['status'] == 'success' && rawData['persona_data'] != null) {
            
            // Si la API tiene éxito, actualizamos colaboradorJsonData
            colaboradorJsonData = rawData; 
            
            // Guardamos el JSON COMPLETO en la caché.
            await DatabaseHelper.instance.saveColaboradorData(idColaborador, rawData);
            _lastColaboradorDataFetch = DateTime.now();
            debugPrint('UserProvider: Datos del colaborador obtenidos y guardados desde la API.');
            
          } else {
            debugPrint('UserProvider: La API devolvió estado no exitoso o sin datos. Manteniendo caché si existe.');
          }
        } else {
          debugPrint('UserProvider: Error HTTP al cargar datos del colaborador (${colaboradorResponse.statusCode}). Manteniendo caché si existe.');
        }
      } on SocketException {
        debugPrint('UserProvider: SocketException al cargar datos del colaborador. Sin conexión. Mostrando datos cacheados.');
      } on http.ClientException {
        debugPrint('UserProvider: ClientException al cargar datos del colaborador. Problema de red. Mostrando datos cacheados.');
      } catch (e) {
        debugPrint('UserProvider: Excepción general al cargar datos del colaborador desde la API: $e. Mostrando datos cacheados.');
      }
    }
    
    // 3. Lógica de validación y retorno final (incluyendo guardado de encabezados)
    if (colaboradorJsonData != null) {
      try {
        // ✅ Parseamos el JSON final (ya sea de caché o de la API)
        tempColaboradorModel = ColaboradorModel.fromJson(colaboradorJsonData);
        
        // Asumiendo que idColaborador.isNotEmpty es la validación de un registro válido
        if (tempColaboradorModel.idColaborador.isNotEmpty) {
          
          // ⭐️ INTEGRACIÓN CLAVE (FINAL): Guardar la estructura de la Boleta en la base de datos
          if (tempColaboradorModel.encabezadosBoleta.isNotEmpty) {
             await DatabaseHelper.instance.saveBoletaEncabezados(tempColaboradorModel.encabezadosBoleta);
             // Actualizar la variable del Provider con la data fresca de la API
             _boletaEncabezados = tempColaboradorModel.encabezadosBoleta; 
             debugPrint('UserProvider: Estructura de Boleta guardada/actualizada.');
          }
          
          _colaboradorModel = tempColaboradorModel;
          _currentColaboradorDetails = tempColaboradorModel;
          notifyListeners();
          debugPrint('UserProvider: ColaboradorModel actualizado (final).');
          return _colaboradorModel;
        }
      } catch (e) {
        debugPrint('UserProvider: Error al parsear ColaboradorModel (final): $e');
      }
    }

    _colaboradorModel = null;
    _currentColaboradorDetails = null;
    notifyListeners();
    debugPrint('UserProvider: No se pudieron cargar los datos del colaborador desde la API o el caché.');
    return null;
  }

  Future<String?> getAvisoImagePath(AvisoModel aviso) async {
    if (aviso.archivo == null || aviso.archivo!.isEmpty) {
      return null;
    }

    final imageUrl = '${ApiConstants.assetsBaseUrl}${aviso.archivo}';

    // ⭐️ CAMBIO CLAVE 1: Devolver URL de red si es la web
    if (kIsWeb) {
      debugPrint('UserProvider: Devolviendo URL de red para Web: $imageUrl');
      return imageUrl; // 🛑 Devuelve la URL de red completa
    }

    // ----------------------------------------------------
    // Lógica de Caché Móvil (solo se ejecuta si NO es Web)
    // ----------------------------------------------------
    final now = DateTime.now();
    final bool isCacheExpired = aviso.imagenCacheTimestamp != null
        ? now.difference(aviso.imagenCacheTimestamp!).inDays > 7
        : true;

    if (aviso.imagenLocalPath != null && !isCacheExpired) {
      final localFile = File(aviso.imagenLocalPath!);
      if (await localFile.exists()) {
        debugPrint('UserProvider: Usando imagen desde caché local para ${aviso.idCalendario}');
        return localFile.path;
      }
    }

    debugPrint('UserProvider: Descargando y cacheadando imagen para ${aviso.idCalendario}');
    try {
      final fileInfo = await DefaultCacheManager().downloadFile(imageUrl);
      aviso.imagenLocalPath = fileInfo.file.path;
      aviso.imagenCacheTimestamp = now;

      final String cacheId = '${_idEmpresa}_$_idColaborador';
      await DatabaseHelper.instance.updateAvisoWithImageCache(aviso, cacheId);
      return fileInfo.file.path; // 🛑 Devuelve la ruta local para móvil
    } catch (e) {
      debugPrint('UserProvider: Error al descargar la imagen: $e');
      return null;
    }
  }

  Future<List<AvisoModel>> fetchAndLoadAvisosData({bool forceRefresh = false}) async {
    final String escuelaCode = _escuela;
    final String idEmpresa = _idEmpresa;
    final String fechaHoraApiCall = generateApiFechaHora();
    final String idAlumnoParam = '0';
    final String idSalonParam = '0';
    final String nivelEducativoParam = '0';
    final String idPersonaParam = '0';
    final String idToken = _idToken ?? '0'; 
    final String idColaborador = _idColaborador; 

    if (escuelaCode.isEmpty || idEmpresa.isEmpty || fechaHoraApiCall.isEmpty || idColaborador.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para cargar avisos.');
      _avisos = [];
      notifyListeners();
      return _avisos;
    }
    final String cacheId = '${idEmpresa}_$idColaborador'; 
    List<AvisoModel> fetchedAvisos = [];
    debugPrint('UserProvider: fetchAndLoadAvisosData - Intentando cargar avisos desde el caché local para el colaborador $idColaborador...');
    fetchedAvisos = await DatabaseHelper.instance.getAvisosData(cacheId);
    if (fetchedAvisos.isNotEmpty) {
      debugPrint('UserProvider: fetchAndLoadAvisosData - Avisos cargados desde el caché local: ${fetchedAvisos.length} avisos.');
      _avisos = fetchedAvisos;
      notifyListeners();
    } else {
      _avisos = [];
      notifyListeners();
      debugPrint('UserProvider: fetchAndLoadAvisosData - No hay avisos en caché para el colaborador $idColaborador.');
    }
    if (forceRefresh || shouldFetchAvisosDataFromApi()) {
      debugPrint('UserProvider: fetchAndLoadAvisosData - Intentando obtener avisos desde la API...');
      try {
        final avisosDataUrl = Uri.parse(
          ApiConstants.getAvisos(escuelaCode, idEmpresa, fechaHoraApiCall,idAlumnoParam , idSalonParam, nivelEducativoParam, idPersonaParam, idToken,idColaborador) 
        );
        debugPrint('UserProvider: fetchAndLoadAvisosData - URL de la API de avisos: $avisosDataUrl');
        final avisosResponse = await http.get(avisosDataUrl);
        
        
        if (avisosResponse.statusCode == 200) {
          final rawData = json.decode(avisosResponse.body);
          if (rawData is List) {
            final List<AvisoModel> newAvisosFromApi = rawData.map((e) {
              final aviso = AvisoModel.fromJson(e as Map<String, dynamic>);
              return aviso;
            }).toList();
            final List<AvisoModel> existingAvisosInDb = await DatabaseHelper.instance.getAvisosData(cacheId);
            final Map<String, bool> existingReadStatus = {
              for (var aviso in existingAvisosInDb) aviso.idCalendario: aviso.leido
            };
            final List<AvisoModel> finalAvisosToSave = newAvisosFromApi.map((newAviso) {
              if (existingReadStatus.containsKey(newAviso.idCalendario) && existingReadStatus[newAviso.idCalendario] == true) {
                newAviso.leido = true;
              }
              return newAviso;
            }).toList();
            await DatabaseHelper.instance.saveAvisosData(cacheId, finalAvisosToSave);
            _lastAvisosDataFetch = DateTime.now();
            debugPrint('UserProvider: fetchAndLoadAvisosData - Datos de avisos obtenidos y guardados desde la API.');
            fetchedAvisos = finalAvisosToSave;
          } else {
            debugPrint('UserProvider: fetchAndLoadAvisosData - La API de avisos devolvió un formato inesperado. Manteniendo caché si existe.');
          }
        } else {
          debugPrint('UserProvider: fetchAndLoadAvisosData - Error HTTP al cargar avisos (${avisosResponse.statusCode}). Manteniendo caché si existe.');
        }
      } on SocketException {
        debugPrint('UserProvider: fetchAndLoadAvisosData - SocketException al cargar avisos. Sin conexión. Mostrando datos cacheados.');
      } on http.ClientException {
        debugPrint('UserProvider: fetchAndLoadAvisosData - ClientException al cargar avisos. Problema de red. Mostrando datos cacheados.');
      } catch (e) {
        debugPrint('UserProvider: fetchAndLoadAvisosData - Excepción general al cargar avisos desde la API: $e. Mostrando datos cacheados.');
      }
    }
    _avisos = fetchedAvisos;
    notifyListeners();
    debugPrint('UserProvider: fetchAndLoadAvisosData - Avisos actualizados (final).');
    return _avisos;
  }
  

  Future<List<Articulo>> fetchAndLoadArticulosCafData(String tipoCafeteria, {bool forceRefresh = false}) async {
    // ... (este método no cambia, solo la URL de la API)
    final String escuelaCode = _escuela;
    final String idEmpresa = _idEmpresa;
    final String idColaborador = _idColaborador; // ✅ [REF] Cambiado de idAlumno
    final String fechaHoraApiCall = generateApiFechaHora();
    final String idPersonaParam = '0';
    final String idToken = _idToken ?? ''; 

    if (escuelaCode.isEmpty || idEmpresa.isEmpty || tipoCafeteria.isEmpty || fechaHoraApiCall.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para cargar artículos de cafetería.');
      _articulosCaf = [];
      notifyListeners();
      return _articulosCaf;
    }

    final String cacheId = '${idEmpresa}_$tipoCafeteria';

    List<dynamic>? articulosCafJsonList;

    debugPrint('UserProvider: Intentando cargar artículos de cafetería desde el caché local...');
    final cachedData = await DatabaseHelper.instance.getArticulosCafData(cacheId);
    if (cachedData != null) {
      articulosCafJsonList = cachedData['data_json'] as List<dynamic>;
      _lastArticulosCafDataFetch = cachedData['last_fetch_time'];
      debugPrint('UserProvider: Artículos de cafetería cargados desde el caché local.');
      try {
        _articulosCaf = articulosCafJsonList.map((e) => Articulo.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('UserProvider: Error al parsear ArticulosCaf cacheados: $e');
        _articulosCaf = [];
        notifyListeners();
      }
    } else {
      _articulosCaf = [];
      notifyListeners();
      debugPrint('UserProvider: No hay artículos de cafetería en caché.');
    }

    if (forceRefresh || shouldFetchArticulosCafDataFromApi()) {
      debugPrint('UserProvider: Intentando obtener artículos de cafetería desde la API...');
      try {
        final articulosCafDataUrl = Uri.parse(
          ApiConstants.getArticulosCaf(escuelaCode, idEmpresa, tipoCafeteria, fechaHoraApiCall, idPersonaParam, idColaborador, idToken) // ✅ [REF] Cambiado a idColaborador
        );
        final articulosCafResponse = await http.get(articulosCafDataUrl);

        if (articulosCafResponse.statusCode == 200) {
          final rawData = json.decode(articulosCafResponse.body);
          if (rawData is List) {
            articulosCafJsonList = rawData;
            await DatabaseHelper.instance.saveArticulosCafData(cacheId, rawData);
            _lastArticulosCafDataFetch = DateTime.now();
            debugPrint('UserProvider: Datos de artículos de cafetería obtenidos y guardados desde la API.');
          } else {
            debugPrint('UserProvider: La API de artículos de cafetería devolvió un formato inesperado. Manteniendo caché si existe.');
          }
        } else {
          debugPrint('UserProvider: Error HTTP al cargar artículos de cafetería (${articulosCafResponse.statusCode}). Manteniendo caché si existe.');
        }
      } on SocketException {
        debugPrint('UserProvider: SocketException al cargar artículos de cafetería. Sin conexión a internet. Mostrando datos cacheados.');
      } on http.ClientException {
        debugPrint('UserProvider: ClientException al cargar artículos de cafetería. Problema de red. Mostrando datos cacheados.');
      } catch (e) {
        debugPrint('UserProvider: Excepción general al cargar artículos de cafetería desde la API: $e. Mostrando datos cacheados.');
      }
    }
    if (articulosCafJsonList != null) {
      try {
        _articulosCaf = articulosCafJsonList.map((e) => Articulo.fromJson(e as Map<String, dynamic>)).toList();
        notifyListeners();
        debugPrint('UserProvider: Artículos de cafetería actualizados (final).');
        return _articulosCaf;
      } catch (e) {
        debugPrint('UserProvider: Error al parsear ArticulosCaf (final): $e');
        _articulosCaf = [];
        notifyListeners();
        return _articulosCaf;
      }
    }
    _articulosCaf = [];
    notifyListeners();
    debugPrint('UserProvider: No se pudieron cargar los artículos de cafetería desde la API o el caché.');
    return _articulosCaf;
  }

  // ✅ [REF] Eliminados los métodos para Pagos Realizados y Cargos Pendientes
  
  void setUltimoSaldoConocido(double saldo) {
    _ultimoSaldoConocido = saldo;
    notifyListeners();
  }

  Future<void> fetchAndLoadCafeteriaMovimientosData({
    required String idColaborador, // ✅ [REF] Cambiado de idAlumno
    required String? idPeriodo,
    required String? idCiclo,
    bool forceRefresh = false,
  }) async {
    final String escuelaCode = _escuela;
    final String idAlumno = '0'; 
    final String fechaHoraApiCallFormatted = generateApiFechaHora();
    final String periodParam = idPeriodo ?? '';
    final String cicloParam = idCiclo ?? '';
    final String idEmpresa = _idEmpresa;
    final String idToken = _idToken ?? ''; 
    

    if (escuelaCode.isEmpty || idColaborador.isEmpty || fechaHoraApiCallFormatted.isEmpty) {
      debugPrint('UserProvider: Datos de sesión o parámetros incompletos para cargar movimientos de cafetería.');
      _cafeteriaMovimientos = [];
      notifyListeners();
      return;
    }

    final String cacheId = '${escuelaCode}_${idColaborador}_${periodParam.isEmpty ? 'NO_PERIOD' : periodParam}_${cicloParam.isEmpty ? 'NO_CICLO' : cicloParam}'; // ✅ [REF] Cambiado de idAlumno
    debugPrint('UserProvider: Intentando cargar desde el caché local...');
    final cachedData = await DatabaseHelper.instance.getCafeteriaData(cacheId);
    if (cachedData != null) {
      try {
        final List<dynamic> cachedDataList = cachedData['data_json'] as List<dynamic>;
        _lastCafeteriaMovimientosDataFetch = cachedData['last_fetch_time'];

        if (cachedData['saldo_actual'] != null) {
          _ultimoSaldoConocido = double.tryParse(cachedData['saldo_actual'].toString()) ?? 0.0;
        }

        _cafeteriaMovimientos = cachedDataList
            .where((item) => item['Folio'] != 'Totales')
            .map((item) {
          return {
            'folio': item['Folio']?.toString() ?? '',
            'fecha': item['Periodo']?.toString() ?? '',
            'descripcion': item['Alumn@']?.toString() ?? '', // ✅ [REF] Esta clave puede cambiar en tu nueva API
            'cargo': double.tryParse(item['Cargo']?.toString().replaceAll(',', '') ?? '0.00') ?? 0.00,
            'abono': double.tryParse(item['Abono']?.toString().replaceAll(',', '') ?? '0.00') ?? 0.00,
            'saldo': double.tryParse(item['Saldo']?.toString().replaceAll(',', '') ?? '0.00') ?? 0.00,
          };
        }).toList();
        notifyListeners();
        debugPrint('UserProvider: Movimientos de cafetería cargados desde el caché local.');
      } catch (e) {
        debugPrint('UserProvider: Error al parsear movimientos de cafetería cacheados: $e');
        _cafeteriaMovimientos = [];
        notifyListeners();
      }
    } else {
      _cafeteriaMovimientos = [];
      notifyListeners();
      debugPrint('UserProvider: No hay movimientos de cafetería en caché.');
    }

    if (forceRefresh || shouldFetchCafeteriaMovimientosDataFromApi()) {
      debugPrint('UserProvider: Intentando obtener datos desde la API...');
      try {
        final movimientosDataUrl = Uri.parse(
          ApiConstants.getEdoCtaCafeteria(escuelaCode, idAlumno, idColaborador, periodParam, cicloParam, fechaHoraApiCallFormatted,idEmpresa,idToken)
        );
        debugPrint('UserProvider: API URL para movimientos de cafetería: $movimientosDataUrl');
        final movimientosResponse = await http.get(movimientosDataUrl);

        if (movimientosResponse.statusCode == 200) {
          try {
            final List<dynamic> rawData = json.decode(movimientosResponse.body);
            if (rawData.isNotEmpty && rawData[0]['Saldo_actual'] != null) {
              final String saldoString = rawData[0]['Saldo_actual'].toString().replaceAll(',', '');
              final double apiSaldo = double.tryParse(saldoString) ?? 0.0;
              setUltimoSaldoConocido(apiSaldo);
              final List<dynamic> movimientosList = rawData
                  .where((item) => item['Folio'] != 'Totales')
                  .toList();
              _cafeteriaMovimientos = movimientosList.map((item) {
                return {
                  'folio': item['Folio']?.toString() ?? '',
                  'fecha': item['Periodo']?.toString() ?? '',
                  'descripcion': item['Alumn@']?.toString() ?? '',
                  'cargo': double.tryParse(item['Cargo']?.toString().replaceAll(',', '') ?? '0.00') ?? 0.00,
                  'abono': double.tryParse(item['Abono']?.toString().replaceAll(',', '') ?? '0.00') ?? 0.00,
                  'saldo': double.tryParse(item['Saldo']?.toString().replaceAll(',', '') ?? '0.00') ?? 0.00,
                };
              }).toList();
              await DatabaseHelper.instance.saveCafeteriaData(cacheId, apiSaldo, movimientosList);
              _lastCafeteriaMovimientosDataFetch = DateTime.now();
              notifyListeners();
              debugPrint('UserProvider: Datos de cafetería obtenidos, procesados y guardados desde la API.');
            } else {
              debugPrint('UserProvider: La API devolvió un formato inesperado o el saldo es nulo.');
            }
          } on FormatException catch (e) {
            debugPrint('UserProvider: FormatException al decodificar JSON: $e');
          }
        }
      } on SocketException {
        debugPrint('UserProvider: SocketException. Sin conexión.');
      } on http.ClientException {
        debugPrint('UserProvider: ClientException. Problema de red.');
      } catch (e) {
        debugPrint('UserProvider: Excepción general al cargar desde la API: $e.');
      }
    }
    if (_cafeteriaMovimientos.isEmpty && cachedData == null) {
      debugPrint('UserProvider: No se pudieron cargar los movimientos desde la API o el caché.');
    }
  }

  // ✅ [REF] Eliminado el método fetchAndLoadMateriasData

 Future<void> markAvisoAsRead(String idCalendario, {String? respuesta}) async {
    if (_escuela.isEmpty || _idEmpresa.isEmpty || _idColaborador.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para marcar aviso o enviar respuesta.');
      return;
    }
     final String idTokenParam = _idToken ?? '0'; 
    final Map<String, String> body = {
      // ... (cuerpo de la petición HTTP) ...
      'escuela': _escuela,
      'id_calendario': idCalendario,
      'id_alumno':'0',
      'id_persona':'0',
      'seg_respuesta': respuesta ?? '',
      'id_colaborador': _idColaborador, 
      'id_token': idTokenParam, 
    };

    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.setAvisoLeidoEndpoint}');

    debugPrint('➡️ API Petición POST a: $url');
    debugPrint('➡️ Parámetros BODY enviados: $body');
    
    try {
      final response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        debugPrint('Aviso $idCalendario marcado como leído y/o respuesta enviada.');
        final avisoIndex = _avisos.indexWhere((a) => a.idCalendario == idCalendario);
        
        if (avisoIndex != -1) {
          
          // 🚀 LÓGICA DE PERSISTENCIA CONDICIONAL
          if (!kIsWeb) {
              final dbHelper = DatabaseHelper.instance;
              final cacheId = '${_idEmpresa}_$_idColaborador';

              // Marcar como leído y guardar respuesta en la base de datos (SOLO EN MÓVIL)
              await dbHelper.updateAvisoReadStatus(idCalendario, cacheId, true);
              await dbHelper.updateAvisoRespuesta(idCalendario, cacheId, respuesta ?? '');
          }
          // ------------------------------------------

          // 2. Actualizar el estado en memoria (_avisos)
          final currentAviso = _avisos[avisoIndex];
          _avisos[avisoIndex] = AvisoModel(
            idCalendario: currentAviso.idCalendario,
            titulo: currentAviso.titulo,
            colorTitulo: currentAviso.colorTitulo,
            comentario: currentAviso.comentario,
            fecha: currentAviso.fecha,
            fechaFin: currentAviso.fechaFin,
            archivo: currentAviso.archivo,
            leido: true, // ✅ Actualizado en memoria
            seccion: currentAviso.seccion,
            tipoRespuesta: currentAviso.tipoRespuesta,
            segRespuesta: respuesta ?? '', // ✅ Actualizado en memoria
            opcion1: currentAviso.opcion1,
            opcion2: currentAviso.opcion2,
            opcion3: currentAviso.opcion3,
            opcion4: currentAviso.opcion4,
            opcion5: currentAviso.opcion5,
            imagenLocalPath: currentAviso.imagenLocalPath,
            imagenCacheTimestamp: currentAviso.imagenCacheTimestamp,
          );
        }
        notifyListeners();
      } else {
        debugPrint('Error de servidor al marcar aviso: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Excepción al marcar aviso: $e');
      // 🛑 NOTA: Si ves errores de CORS en la web, se capturarán aquí
    }
  }

  Future<void> initializeAllUserData({bool forceRefresh = false}) async {
    debugPrint('UserProvider: Iniciando initializeAllUserData (forceRefresh: $forceRefresh)');

    await loadUserDataFromDb();

    if (_idColaborador.isEmpty || _idEmpresa.isEmpty || _escuela.isEmpty) { // ✅ [REF] Cambiado de idAlumno
      debugPrint('UserProvider: Faltan datos de sesión esenciales. No se pueden inicializar.');
      return;
    }
    
    await fetchAndLoadSchoolData(forceRefresh: forceRefresh);
    
    if (_idColaborador.isNotEmpty) { // ✅ [REF] Cambiado de idAlumno
      await fetchAndLoadAllColaboradorSpecificData(_idColaborador, forceRefresh: forceRefresh); // ✅ [REF] Nuevo método de orquestación
    } else {
      debugPrint('UserProvider: No se encontró ningún colaborador, no se cargarán datos específicos.');
    }
    debugPrint('UserProvider: initializeAllUserData completado.');
  }

  Future<void> fetchAndLoadAllColaboradorSpecificData(String idColaborador, {bool forceRefresh = false}) async {
    // ✅ [REF] Nuevo método para orquestar la carga de datos del colaborador
    debugPrint('UserProvider: Iniciando fetchAndLoadAllColaboradorSpecificData para el colaborador: $idColaborador (forceRefresh: $forceRefresh)');
    
    await fetchAndLoadColaboradorData(forceRefresh: forceRefresh);

    if (_currentColaboradorDetails == null) {
      debugPrint('UserProvider: _currentColaboradorDetails no está listo. Abortando carga de datos específicos.');
      return;
    }

    await fetchAndLoadAvisosData(forceRefresh: forceRefresh);
    await fetchAndLoadArticulosCafData('cafeteria', forceRefresh: forceRefresh);

    String effectivePeriodId = _selectedCafeteriaPeriodId ?? '';
    String effectiveCicloId = _selectedCafeteriaCicloId ?? (_idCiclo.isNotEmpty ? _idCiclo : '');

    if (_selectedCafeteriaPeriodId == null && _escuelaModel != null && _escuelaModel!.cafPeriodos.isNotEmpty) {
      final List<PeriodoCafeteria> availablePeriods = _escuelaModel!.cafPeriodos;
      if (_escuelaModel!.cafPeriodoActual.isNotEmpty && availablePeriods.any((p) => p.idPeriodo == _escuelaModel!.cafPeriodoActual)) {
        final matchingPeriod = availablePeriods.firstWhere((p) => p.idPeriodo == _escuelaModel!.cafPeriodoActual);
        effectivePeriodId = matchingPeriod.idPeriodo;
        effectiveCicloId = matchingPeriod.idCiclo;
        debugPrint('UserProvider: Predeterminando periodo de cafetería al actual de la API: Periodo: "$effectivePeriodId", Ciclo: "$effectiveCicloId"');
      }
      else if (availablePeriods.any((p) => p.activo == '1')) {
        final activePeriod = availablePeriods.firstWhere((p) => p.activo == '1');
        effectivePeriodId = activePeriod.idPeriodo;
        effectiveCicloId = activePeriod.idCiclo;
        debugPrint('UserProvider: Predeterminando periodo de cafetería al primer activo: Periodo: "$effectivePeriodId", Ciclo: "$effectiveCicloId"');
      }
      else {
        effectivePeriodId = availablePeriods.first.idPeriodo;
        effectiveCicloId = availablePeriods.first.idCiclo;
        debugPrint('UserProvider: Predeterminando periodo de cafetería al primer disponible: Periodo: "$effectivePeriodId", Ciclo: "$effectiveCicloId"');
      }
      _selectedCafeteriaPeriodId = effectivePeriodId;
      _selectedCafeteriaCicloId = effectiveCicloId;
    } else if (_selectedCafeteriaPeriodId != null) {
      effectivePeriodId = _selectedCafeteriaPeriodId!;
      effectiveCicloId = _selectedCafeteriaCicloId!;
      debugPrint('UserProvider: Usando periodo de cafetería ya seleccionado: Periodo: "$effectivePeriodId", Ciclo: "$effectiveCicloId"');
    } else {
      effectivePeriodId = '';
      effectiveCicloId = _idCiclo.isNotEmpty ? _idCiclo : '';
      debugPrint('UserProvider: No se encontró un período de cafetería válido, usando cadenas vacías. Periodo: "$effectivePeriodId", Ciclo: "$effectiveCicloId"');
    }

    await fetchAndLoadCafeteriaMovimientosData(
      idColaborador: idColaborador, // ✅ [REF] Cambiado de idAlumno
      idPeriodo: effectivePeriodId,
      idCiclo: effectiveCicloId,
      forceRefresh: forceRefresh,
    );
    debugPrint('UserProvider: fetchAndLoadAllColaboradorSpecificData completado para el colaborador: $idColaborador');
  }

  /// Envía el estado de asistencia de todos los alumnos de un curso o club a la API.
  Future<Map<String, dynamic>> setAsistenciaClubesOMaterias({
    required String idCurso,
    required TipoCurso tipoCurso,
    required Map<String, AttendanceStatus> attendanceState,
    required List<AlumnoAsistenciaModel> alumnosLista, // ✅ Agregada para obtener id_alumno
  }) async {
    
    // El idTokenParam sigue siendo necesario para el BODY (aunque ya no va en el cuerpo JSON principal)
    final String idTokenParam = _idToken ?? '0'; // Usamos '0' o cadena vacía si es nulo.

    // 1. Preparar los datos de asistencia como un ARRAY DE OBJETOS
    final List<Map<String, dynamic>> listaAsistenciaAEnviar = [];
    
    // Nueva variable para buscar el id_alumno rápidamente (O(1))
    final Map<String, String> mapaBusquedaIdAlumno = {
      for (var alumno in alumnosLista) 
        alumno.idCursoAlumno: alumno.idAlumno
    };
    
    attendanceState.forEach((idCursoAlumno, status) {
      
      // Obtener el id_alumno usando el idCursoAlumno como clave
      final String idAlumno = mapaBusquedaIdAlumno[idCursoAlumno] ?? '0'; // '0' como valor predeterminado seguro

      // Usamos el ID del curso-alumno como el 'id' en el JSON
      final int id = int.tryParse(idCursoAlumno) ?? 0; 
      
      // Mantenemos los valores 1 o 0
      final String apiStatus = status == AttendanceStatus.presente ? '1' : '0';
      
      // ✅ MODIFICACIÓN: Incluir id_alumno en el objeto JSON
      listaAsistenciaAEnviar.add({
        'id': id, // id_curso_alu
        'id_alumno': idAlumno, // <-- NUEVO CAMPO REQUERIDO
        'asistencia': apiStatus, // Clave 'asistencia' y valor '1' o '0'
      });
    });

    // 2. Stringificar la lista de asistencia (JSON en una cadena para el body)
    // ✅ CLAVE: Codificamos SOLO el array de asistencia para que sea el valor de un campo
    final String asistenciaDataJsonString = json.encode(listaAsistenciaAEnviar); 
    
    // 3. Construir los datos de la solicitud como un Map<String, String> para Form-encode
    final String tipoCursoString = tipoCurso == TipoCurso.materia ? 'materia' : 'club';
  
    final String fechaHoraApiCall = _fechaHora.isNotEmpty ? _fechaHora : generateApiFechaHora();
    final String fechaActualApiCall = generarFechaActualApi(); 
    
    // ✅ CLAVE: Se usa Map<String, String> para Form-encode
    final Map<String, String> body = {
      'escuela': _escuela,
      'id_escuela': idEmpresa,
      'id_curso': idCurso,
      
      'tipo_curso': tipoCursoString,
      'id_ciclo': idCiclo, 
      //'id_colaborador': _idColaborador,
      'fechahora': fechaActualApiCall, 
      //'id_token': idTokenParam, 
      // ✅ CLAVE: El array JSON va aquí como una CADENA de texto
      'asistencia': asistenciaDataJsonString, 
      'fecha_asistencia': fechaHoraApiCall,
    };

    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.setAsistenciaClubes}');
    
    // ⭐️ LOG DE DEPURACIÓN DETALLADO ⭐️
    debugPrint('--- [API ASISTENCIA - FORM-ENCODE] ---');
    debugPrint('URL de API: $url');
    debugPrint('BODY MAP ENVIADO: $body'); 
    debugPrint('JSON ARRAY ENVIADO EN EL CAMPO "asistencia": $asistenciaDataJsonString');
    debugPrint('--- [FIN LOG ASISTENCIA] ---');

    // 4. VALIDACIÓN DE SESIÓN (SOLO ESCUELA Y COLABORADOR REQUERIDOS)
    if (_escuela.isEmpty || _idColaborador.isEmpty) {
      debugPrint('UserProvider: Datos de sesión (Escuela o Colaborador) incompletos.');
      return {'status': 'error', 'message': 'Error de sesión. Faltan datos esenciales (Escuela/Colaborador).'};
    }

    // 5. LLAMADA HTTP
    try {
      // ✅ CLAVE: Enviamos el Map<String, String>. http.post lo codifica automáticamente como Form-encode.
      final response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success') {
          debugPrint('Asistencia enviada exitosamente.');
          return {'status': 'success', 'message': responseData['message'] ?? 'Asistencia guardada con éxito.'};
        } else {
          String errorMessage = responseData['message'] ?? 'Ocurrió un error al guardar la asistencia.';
          debugPrint('Error de API: $errorMessage');
          debugPrint('Respuesta de error completa del servidor: ${response.body}');
          return {'status': 'error', 'message': errorMessage};
        }
      } else {
        debugPrint('Error de servidor HTTP: ${response.statusCode}');
        debugPrint('Cuerpo de la respuesta del servidor: ${response.body}');
        return {'status': 'error', 'message': 'Error de conexión con el servidor (${response.statusCode}).'};
      }
    } on SocketException {
      debugPrint('Excepción al enviar asistencia: SocketException');
      return {'status': 'error', 'message': 'No se pudo conectar al servidor. Revisa tu conexión a internet.'};
    } on http.ClientException {
      debugPrint('Excepción al enviar asistencia: ClientException');
      return {'status': 'error', 'message': 'Problema de red al enviar datos.'};
    } catch (e) {
      debugPrint('Excepción general al enviar asistencia: $e');
      return {'status': 'error', 'message': 'Ocurrió un error inesperado al guardar la asistencia.'};
    }
  }

  Future<Map<String, dynamic>> saveCalificaciones({
    required String idCurso,
    required List<Map<String, dynamic>> calificacionesLista,
    required BoletaEncabezadoModel estructuraBoleta, // ✅ MODIFICACIÓN: Nuevo parámetro para simplificar el JSON
  }) async {
    
    // Preparar datos de sesión (ID Token no requerido)
    final String idTokenParam = _idToken ?? '0'; 
    
    // Usaremos el generador de fecha AAAA-MM-DD que ya tienes
    final String fechaActualApiCall = generateApiFechaHora(); 
    
    // 1. Validar datos mínimos
    if (_escuela.isEmpty || _idColaborador.isEmpty || idCurso.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para guardar calificaciones.');
      return {'status': 'error', 'message': 'Error de sesión. Faltan datos esenciales (Escuela/Colaborador/Curso).'};
    }

    final String idColaborador = _idColaborador;

    // ✅ MODIFICACIÓN: Lógica para SIMPLIFICAR EL JSON a enviar
    // ------------------------------------

    // 1. Recolectar TODAS las claves de calificación/observación de la boleta:
    Set<String> clavesDeCalificacion = {};

    // Añadir todas las claves de relaciones (P1, P2, CF, etc.)
    estructuraBoleta.relaciones.values.forEach((relationString) {
      relationString.split(',').forEach((key) {
        if (key.trim().isNotEmpty) clavesDeCalificacion.add(key.trim());
      });
    });

    // Añadir todas las claves de comentarios (OBSERVACION_FINAL, etc.)
    clavesDeCalificacion.addAll(estructuraBoleta.comentarios.keys);
    debugPrint('Claves de Boleta a enviar: ${clavesDeCalificacion.toList()}');

    // 2. Transformar la lista de alumnos para incluir SOLO los IDs y las calificaciones.
    final List<Map<String, dynamic>> listaCalificacionesAEnviar = calificacionesLista.map((alumno) {
        final Map<String, dynamic> alumnoData = {};
        
        // ID's ESENCIALES
        alumnoData['id_curso'] = alumno['id_curso'];
        alumnoData['id_alumno'] = alumno['id_alumno']; // Requerido para identificar el alumno
        alumnoData['id_alu_mat'] = alumno['id_alu_mat']; // Requerido para identificar el registro
        
        // Agregar SOLO las claves de calificación que existen, tienen valor, y no son nulas
        for (String clave in clavesDeCalificacion) {
            if (alumno.containsKey(clave) && alumno[clave] != null) {
                 final String valor = alumno[clave].toString().trim();
                 if (valor.isNotEmpty) {
                    alumnoData[clave] = valor;
                 }
            }
        }
        
        return alumnoData;
    }).toList();
    
    // ------------------------------------

    // El parámetro 'calificacion' de la API debe ser un JSON String de esta lista.
    final String calificacionesDataJsonString = json.encode(listaCalificacionesAEnviar);
    
    // 3. Construir el cuerpo (body) de la solicitud POST
    final Map<String, String> finalBody = {
      'escuela': _escuela,
      'id_curso': idCurso,
      //'id_alumno': idColaborador, // ID del colaborador que envía
      'fechahora': fechaActualApiCall, // AAAA-MM-DD
      'calificacion': calificacionesDataJsonString, // El JSON simplificado
    };


    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.setMateriasCalif}');
    
    // ⭐️ LOG DE DEPURACIÓN DETALLADO ⭐️
    debugPrint('--- [API CALIFICACIONES] ---');
    debugPrint('URL de API: $url');
    debugPrint('Body (escuela): $_escuela');
    debugPrint('Body (id_curso): $idCurso');
    //debugPrint('Body (id_alumno - colaborador): $idColaborador');
    debugPrint('Body (fechahora): $fechaActualApiCall');
    debugPrint('Body (calificacion length): ${calificacionesDataJsonString.length} bytes');
    
    // ✅ MODIFICACIÓN: Imprimir el JSON completo que se está enviando en 'calificacion'
    debugPrint('JSON COMPLETO ENVIADO EN EL CAMPO "calificacion": $calificacionesDataJsonString');
    
    debugPrint('--- [FIN LOG CALIFICACIONES] ---' );

    // 4. LLAMADA HTTP
    try {
      final response = await http.post(url, body: finalBody);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // ✅ MODIFICACIÓN: Print para ver el JSON de respuesta
        debugPrint('UserProvider: JSON retornado por la API: ${response.body}');
        
        if (responseData['status'] == 'correcto') { // Usamos 'correcto' basado en las imágenes
          debugPrint('Calificaciones guardadas exitosamente.');
          return {'status': 'success', 'message': responseData['message'] ?? 'Calificaciones guardadas con éxito.'};
        } else {
          String errorMessage = responseData['message'] ?? 'Error al guardar calificaciones.';
          debugPrint('Error de API: $errorMessage');
          debugPrint('Respuesta de error completa del servidor: ${response.body}');
          return {'status': 'error', 'message': errorMessage};
        }
      } else {
        debugPrint('Error de servidor HTTP: ${response.statusCode}');
        return {'status': 'error', 'message': 'Error de conexión con el servidor (${response.statusCode}).'};
      }
    } on SocketException {
      return {'status': 'error', 'message': 'No se pudo conectar al servidor. Revisa tu conexión a internet.'};
    } catch (e) {
      debugPrint('Excepción general al guardar calificaciones: $e');
      return {'status': 'error', 'message': 'Ocurrió un error inesperado al guardar calificaciones.'};
    }
  }
}
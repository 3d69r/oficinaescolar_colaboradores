// `UserProvider.dart`
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:oficinaescolar_colaboradores/data/database_helper.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/models/alumno_asistencia_model.dart';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';
import 'package:oficinaescolar_colaboradores/models/comentario_model.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; // ✅ [REF] Nuevo modelo
import 'package:oficinaescolar_colaboradores/models/aviso_model.dart';
//import 'package:oficinaescolar_colaboradores/models/cfdi_model.dart'; // Mantener el modelo si la API lo retorna, aunque no usemos el método
import 'package:oficinaescolar_colaboradores/models/articulo_model.dart';
//import 'package:oficinaescolar_colaboradores/models/pago_model.dart'; // Mantener el modelo si la API lo retorna
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';

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
    
  // Getter para acceder a la configuración de la boleta
  List<BoletaEncabezadoModel> get boletaEncabezados => _boletaEncabezados;

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
  }

  Future<void> loadAppColorsFromDb() async {
    // ... (este método no cambia)
    debugPrint('UserProvider: Intentando cargar colores desde la base de datos...');
    _colores = await DatabaseHelper.instance.getColoresData();
    notifyListeners();
    if (_colores != null) {
      debugPrint('UserProvider: Colores cargados desde la base de datos.');
    } else {
      debugPrint('UserProvider: No se encontraron colores en la base de datos.');
    }
  }

  Future<void> loadUserDataFromDb() async {
    debugPrint('UserProvider: Intentando cargar datos de usuario desde la base de datos...');
    final cachedData = await DatabaseHelper.instance.getSessionData('session_data');
    if (cachedData != null) {
      final sessionJson = cachedData['data_json'] as Map<String, dynamic>;
      _idColaborador = sessionJson['idColaborador'] ?? ''; // ✅ [REF] Cambiado de idAlumno
      _idEmpresa = sessionJson['idEmpresa'] ?? '';
      _email = sessionJson['email'] ?? '';
      _escuela = sessionJson['escuela'] ?? '';
      _fechaHora = sessionJson['fechaHora'] ?? '';
      _idCiclo = sessionJson['idCiclo'] ?? '';
      
      if (_idColaborador.isNotEmpty) {
        final tokenData = await DatabaseHelper.instance.getTokens(_idColaborador);
        if (tokenData != null) {
          _idToken = tokenData['id_token'] ?? '';
          _fcmToken = tokenData['token_celular'] ?? '';
          debugPrint('UserProvider: Tokens cargados desde la base de datos (idToken: $_idToken)');
        } else {
          debugPrint('UserProvider: No se encontraron tokens en la base de datos.');
        }
      }
      debugPrint('UserProvider: Datos de usuario cargados desde la base de datos.');
    } else {
      debugPrint('UserProvider: No se encontraron datos de usuario en la base de datos.');
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

  Future<void> setUserData({
    required String idColaborador, // ✅ [REF] Cambiado de idAlumno
    required String idEmpresa,
    required String email,
    required String escuela,
    required String idCiclo,
    required String fechaHora,
  }) async {
    _idColaborador = idColaborador; // ✅ [REF] Cambiado de idAlumno
    _idEmpresa = idEmpresa;
    _email = email;
    _escuela = escuela;
    _idCiclo = idCiclo;
    _fechaHora = fechaHora;

    await _saveSessionData();
    debugPrint('UserProvider: Datos de sesión establecidos.');
    notifyListeners();
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
      
      debugPrint('UserProvider: Llamando a API de alumnos para CALIFICAR ${tipoCurso.name} (ID: $idCurso): $alumnosDataUrl');
      
      try {
        final response = await http.get(alumnosDataUrl);

        if (response.statusCode == 200) {

          final rawData = json.decode(response.body);

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
    debugPrint('UserProvider: Datos de usuario y base de datos local limpiados.');
  }

  String generateApiFechaHora() {
    // ... (este método no cambia)
    final now = DateTime.now();
    final formatter = DateFormat('ddMMyyyyHHmmss');
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
    required String idColaborador, // ✅ [REF] Cambiado de idAlumno
    required String tokenCelular,
    required String status,
  }) async {
    // ... (la lógica es la misma)
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String modeloMarca = '';
      String sistemaOperativo = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        modeloMarca = '${androidInfo.manufacturer} ${androidInfo.model}';
        sistemaOperativo = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        modeloMarca = '${iosInfo.name} ${iosInfo.model}';
        sistemaOperativo = 'iOS ${iosInfo.systemVersion}';
      }

      final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.updateInfoTokenEndpoint}');
      final body = {
        'escuela': escuela,
        'id_persona': idColaborador, // ✅ [REF] Cambiado de id_persona
        'token_celular': tokenCelular,
        'status': status,
        if (status == 'activo') ...{
          'modelo_marca': modeloMarca,
          'sistema_operativo': sistemaOperativo,
        }
      };

      final response = await http.post(url, body: body);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'correcto') {
        debugPrint('Token actualizado correctamente');
        final String idToken = responseData['id_token']?.toString() ?? '';
        _idToken = idToken;
        _tokenCelular = tokenCelular;
        if (_idToken != null && _idToken!.isNotEmpty) {
          await DatabaseHelper.instance.saveTokens(idColaborador, _idToken!, _tokenCelular!);
          debugPrint('UserProvider: Tokens guardados en la base de datos local.');
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
    // ... (este método no cambia)
    if (aviso.archivo == null || aviso.archivo!.isEmpty) {
      return null;
    }
    final imageUrl = '${ApiConstants.assetsBaseUrl}${aviso.archivo}';
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

      final String cacheId = '${_idEmpresa}_$_idColaborador'; // ✅ [REF] Cambiado de idAlumno
      await DatabaseHelper.instance.updateAvisoWithImageCache(aviso, cacheId);
      return fileInfo.file.path;
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
    final String fechaHoraApiCallFormatted = generateApiFechaHora();
    final String periodParam = idPeriodo ?? '';
    final String cicloParam = idCiclo ?? '';
    final String idEmpresa = _idEmpresa;
    final String idToken = _idToken ?? ''; 
    final String idAlumno = '0'; 

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
          ApiConstants.getEdoCtaCafeteria(escuelaCode, idColaborador, periodParam, cicloParam, fechaHoraApiCallFormatted, idEmpresa, idToken, idAlumno) // ✅ [REF] Cambiado a idColaborador
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
    // ... (este método no cambia, solo su uso)
    if (_escuela.isEmpty || _idEmpresa.isEmpty || _idColaborador.isEmpty) {
      debugPrint('UserProvider: Datos de sesión incompletos para marcar aviso o enviar respuesta.');
      return;
    }
     final String idTokenParam = _idToken ?? '0'; 
    final Map<String, String> body = {
      'escuela': _escuela,
      'id_calendario': idCalendario,
      'id_alumno':'0',
      'id_persona':'0',
      'seg_respuesta': respuesta ?? '',
      'id_colaborador': _idColaborador, 
      'id_token': idTokenParam, 
    };

    final url = Uri.parse('${ApiConstants.apiBaseUrl}${ApiConstants.setAvisoLeidoEndpoint}');
    
    try {
      final response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        debugPrint('Aviso $idCalendario marcado como leído y/o respuesta enviada.');
        final avisoIndex = _avisos.indexWhere((a) => a.idCalendario == idCalendario);
        if (avisoIndex != -1) {
          final dbHelper = DatabaseHelper.instance;
          final cacheId = '${idEmpresa}_$idColaborador'; // ✅ [REF] Cambiado de idAlumno

         // 1. Marcar como leído en la base de datos
          await dbHelper.updateAvisoReadStatus(idCalendario, cacheId, true);

          // 2. Guardar la respuesta si existe
          await dbHelper.updateAvisoRespuesta(idCalendario, cacheId, respuesta ?? '');
          final currentAviso = _avisos[avisoIndex];
          _avisos[avisoIndex] = AvisoModel(
            idCalendario: currentAviso.idCalendario,
            titulo: currentAviso.titulo,
            colorTitulo: currentAviso.colorTitulo,
            comentario: currentAviso.comentario,
            fecha: currentAviso.fecha,
            fechaFin: currentAviso.fechaFin,
            archivo: currentAviso.archivo,
            leido: true,
            seccion: currentAviso.seccion,
            tipoRespuesta: currentAviso.tipoRespuesta,
            segRespuesta: respuesta ?? '',
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
}
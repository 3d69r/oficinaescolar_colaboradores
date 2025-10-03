// lib/config/api_constants.dart

/// Clase que contiene las constantes de URL de la API y activos.
/// Centraliza todos los endpoints y URLs base para facilitar la gestión
/// y el mantenimiento del código.
class ApiConstants {
  // La URL base para los endpoints de tu API.
  // Esta es la ruta completa donde se encuentran tus scripts de API.
  static const String apiBaseUrl = 'https://oficinaescolar.com/ws_oficinae/index.php/api/';

  static const String apiUrl = 'https://oficinaescolar.com.mx/ws_oficinae/index.php/api/';

  // La URL base para los archivos estáticos (imágenes, documentos, etc.).
  // Si tus imágenes están directamente bajo el dominio principal sin el 'ws_oficinae',
  // esta será la URL base para ellas.
  static const String assetsBaseUrl = 'https://oficinaescolar.com/';

  // --- Endpoints fijos para métodos POST (si aplican) ---
  // Estos endpoints ahora se concatenarán directamente con apiBaseUrl.
  static const String validateEscuelaEndpoint = 'validate_escuela';
  static const String validateUserEndpoint = 'validate_user';

  // Endpoint específico para set_aviso_leido (ahora es un POST)
  static const String setAvisoLeidoEndpoint = 'set_aviso_leido';

  // Endpoint para recuperación de contraseña
  static const String forgotPasswordEndpoint = 'recuperar_psw';

  // Nuevo endpoint para carga de archivo y comentario
  static const String cargaArchivoYComentarioEndpoint = 'carga_archivo_y_comentario';

  // Endpoint para actualizar el token del dispositivo
  static const String updateInfoTokenEndpoint = 'update_info_token';

  // Endpoint para enviar comentarios 
  static const String setComentariosAppEndpoint = 'set_comentarios_app';

  // Nuevo endpoint para adjuntar un CFDI por correo
  static const String setAdjuntarCfdiEndpoint = 'set_adjuntar_cfdi';

  // endpoint de prueba para las cabeceras 
  static const String notificarFirebaseEndpoint = 'notificar_firebase';

  // endpoint para enviar la lista de asistencia de clubes 
  static const String setAsistenciaClubes = 'set_asistencia_clubes';

  //Duración minima en la que se debe de recargar la información entre cambio de pestaña
  static const int minutosRecarga = 10;

  // --- Métodos para construir URLs GET con parámetros dinámicos ---
  // Estos métodos ahora usan apiBaseUrl para las llamadas a la API.

  /// API: get_school_data/escuela/id_empresa/fechahora
  /// Obtiene los datos de la escuela y el ciclo escolar actual.
  /// id_empresa es el mismo que id_escuela.
  static String getSchoolData(String escuela, String idEmpresa, String fechaHora, String idAlumno, String idPersona, String idToken ) {
    return '${apiBaseUrl}get_school_data/$escuela/$idEmpresa/$fechaHora/$idAlumno/$idPersona/$idToken';
  }
  
  /// API: get_boleta_alu/escuela/id_alumno/fechahora
  /// Obtiene la boleta de calificaciones en formato HTML.
  static String getBoletaAlumno(String escuela, String idAlumno, String fechaHora) {
    return '${apiBaseUrl}get_boleta_alu/$escuela/$idAlumno/$fechaHora';
  }

   // ✅ NUEVO ENDPOINT para Alumnos de una Materia
  static String getCursoListaAlumnos(String escuela,  String idMateriaClase, String fechaHora, String idToken) {
    return '${apiBaseUrl}get_curso_lista_alumnos/$escuela/$idMateriaClase/$fechaHora/$idToken';
  }

  // ✅ NUEVO ENDPOINT para Alumnos de un Club
  static String getAlumnosClub(String escuela,  String idCurso, String fechaHora ,String idToken) {
    return '${apiBaseUrl}get_alumnos_club/$escuela/$idCurso/$fechaHora/$idToken';
  }

  /// API: get_persona_data/escuela/id_persona/id_empresa/id_ciclo_escolar/fechahora
  /// Obtiene los datos de la persona (padre/madre) y sus alumnos (hijos).
  static String getPersonaData(String escuela, String idPersona, String idEmpresa, String idCicloEscolar, String fechaHora, String idToken) {
    return '${apiBaseUrl}get_persona_data/$escuela/$idPersona/$idEmpresa/$idCicloEscolar/$fechaHora/$idToken';
  }

  /// API: get_alumno_data/escuela/id_alumno/id_ciclo_escolar/fechahora
  /// Obtiene datos específicos de un alumno.
  static String getAlumnoData(String escuela, String idAlumno, String idCicloEscolar, String fechaHora) {
    return '${apiBaseUrl}get_alumno_data/$escuela/$idAlumno/$idCicloEscolar/$fechaHora';
  }

  /// API: get_edo_cta_cafeteria/escuela/id_alumno/id_colaborador/id_periodo/id_ciclo/fechahora
  /// Obtiene el estado de cuenta de cafetería de un alumno.
  static String getEdoCtaCafeteria(String escuela, String idAlumno, String idColaborador, String idPeriodo, String idCiclo, String fechaHora, String idEmpresa, String idToken) {
    return '${apiBaseUrl}get_edo_cta_cafeteria/$escuela/$idAlumno/$idColaborador/$idPeriodo/$idCiclo/$fechaHora/$idEmpresa/$idToken';
  }

  /// API: get_cargos_pendientes/escuela/id_empresa/id_ciclo/id_alumno/fechahora
  /// Obtiene los cargos pendientes de un alumno.
  static String getCargosPendientes(String escuela, String idEmpresa, String idCiclo, String idAlumno, String fechaHora, String idPersona, String idToken) {
    return '${apiBaseUrl}get_cargos_pendientes/$escuela/$idEmpresa/$idCiclo/$idAlumno/$fechaHora/$idPersona/$idToken';
  }

  /// API: get_pagado/escuela/id_empresa/id_alumno/fechahora
  /// Obtiene los pagos realizados por un alumno.
  static String getPagado(String escuela, String idEmpresa, String idAlumno, String fechaHora, String idPersona, String idToken) {
    return '${apiBaseUrl}get_pagado/$escuela/$idEmpresa/$idAlumno/$fechaHora/$idPersona/$idToken';
  }

  /// API: get_cfdi_v1/escuela/id_empresa/id_alumno/fechahora
  /// Obtiene Comprobantes Fiscales Digitales por Internet (CFDI) para un alumno.
  static String getCfdiV1(String escuela, String idEmpresa, String idAlumno, String fechaHora, String idPersona, String idToken) {
    return '${apiBaseUrl}get_cfdi_v1/$escuela/$idEmpresa/$idAlumno/$fechaHora/$idPersona/$idToken';
  }

  // NUEVO MÉTODO: Construye la URL completa para el endpoint de envío de CFDI.
  // Utiliza el dominio 'apiUrl'.
  static String getAdjuntarCfdi() {
    return '$apiUrl$setAdjuntarCfdiEndpoint';
  }

  // NUEVO MÉTODO: Construye la URL completa para el endpoint de recuperación de co       ntraseña.
  // Utiliza el dominio 'apiUrl'.
  static String getForgotPasswordUrl() {
    return '$apiUrl$forgotPasswordEndpoint';
  }

  /// API: get_avisos/escuela/id_empresa/fechahora/id_alumno
  /// Obtiene los avisos para la escuela, filtrados opcionalmente por alumno.
  static String getAvisos(String escuela, String idEmpresa, String fechaHora, String idAlumno, String idSalon, String nivelEducativo, String idPersona, String idToken, String idColaborador) {
    return '${apiBaseUrl}get_avisos/$escuela/$idEmpresa/$fechaHora/$idAlumno/$idSalon/$nivelEducativo/$idPersona/$idToken/$idColaborador';
  }

  /// API: get_articulos_caf/escuela/id_empresa/cafeteria/fechahora
  /// Obtiene los artículos de cafetería disponibles.
  static String getArticulosCaf(String escuela, String idEmpresa, String tipoCafeteria, String fechaHora, String idPersona, String idAlumno, String idToken) {
    return '${apiBaseUrl}get_articulos_caf/$escuela/$idEmpresa/$tipoCafeteria/$fechaHora/$idPersona/$idAlumno/$idToken';
  }

  /// API: get_materias_alu/escuela/id_alumno/id_curso/fecha_hora
  /// Obtiene las materias de un alumno para un curso específico.
  /// Si id_curso es '0', muestra todas las materias.
  static String getMateriasAlumno(String escuela, String idAlumno, String idCurso, String fechaHora, String idEmpresa, String idPersona, String idToken) {
    return '${apiBaseUrl}get_materias_alu/$escuela/$idAlumno/$idCurso/$fechaHora/$idEmpresa/$idPersona/$idToken';
  }
  
  /// Utiliza el dominio 'apiUrl'.
  static String getNotificarFirebaseUrl() {
    return '$apiUrl$notificarFirebaseEndpoint';
  }

  /// API: get_colaborador_data/escuela/id_colaborador/id_empresa/id_ciclo_escolar/fechahora/id_token
  /// Obtiene los datos específicos de un colaborador.
  static String getColaboradorAllData(String escuela, String idColaborador, String idEmpresa, String idCicloEscolar, String fechaHora, String idToken) {
    return '${apiBaseUrl}get_colaborador_data/$escuela/$idColaborador/$idEmpresa/$idCicloEscolar/$fechaHora/$idToken';
  }

  /// API: download_file/escuela/seccion/id_empresa/extension_file/fechahora/nombre_archivo_sin_extension
  /// Descarga un archivo.
  /// NOTA: Esta URL de descarga puede usar assetsBaseUrl si los archivos están en una ruta similar a las imágenes.
  static String downloadFile(String escuela, String seccion, String idEmpresa, String extensionFile, String fechaHora, String nombreArchivoSinExtension) {
    // Si los archivos descargables están en una ruta como 'assets/downloads/...' bajo el dominio principal,
    // entonces usar assetsBaseUrl aquí. Si tienen una ruta diferente, ajusta.
    // Por ahora, asumo que 'download_file' es un endpoint de la API y no un archivo estático directo.
    // Si 'download_file' es un script PHP que sirve el archivo, entonces usa apiBaseUrl.
    // Si es una ruta directa a un archivo estático, usa assetsBaseUrl.
    // Basándome en el patrón de tus otras APIs, es más probable que sea un endpoint de API.
    return '${apiBaseUrl}download_file/$escuela/$seccion/$idEmpresa/$extensionFile/$fechaHora/$nombreArchivoSinExtension';
  }
}

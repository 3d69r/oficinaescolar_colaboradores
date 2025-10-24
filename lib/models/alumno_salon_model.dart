// alumno_salon_model.dart

class AlumnoSalonModel {
  final String idAlumno;
  final String idCicloAlumno;
  final String nivelEducativo;
  final String idSalon;
  final String salon;
  final String primerNombre;
  final String segundoNombre;
  final String apellidoPat;
  final String apellidoMat;
  
  // Lista de campos de archivo de calificación.
  // La clave es el nombre del campo (ej: 'archivo_calif_1') y el valor es la ruta/estado actual.
  final Map<String, String> archivosCalificacion;

  AlumnoSalonModel({
    required this.idAlumno,
    required this.idCicloAlumno,
    required this.nivelEducativo,
    required this.idSalon,
    required this.salon,
    required this.primerNombre,
    required this.segundoNombre,
    required this.apellidoPat,
    required this.apellidoMat,
    required this.archivosCalificacion,
  });

  factory AlumnoSalonModel.fromJson(Map<String, dynamic> json) {
    // 1. Extraer dinámicamente todos los campos que empiezan con 'archivo_calif_'
    final Map<String, String> archivos = {};
    json.forEach((key, value) {
      if (key.startsWith('archivo_calif_') && value is String) {
        archivos[key] = value;
      }
    });

    return AlumnoSalonModel(
      idAlumno: json['id_alumno'] as String? ?? '',
      idCicloAlumno: json['id_ciclo_alumno'] as String? ?? '',
      nivelEducativo: json['nivel_educativo'] as String? ?? '',
      idSalon: json['id_salon'] as String? ?? '',
      salon: json['salon'] as String? ?? '',
      primerNombre: json['primer_nombre'] as String? ?? '',
      segundoNombre: json['segundo_nombre'] as String? ?? '',
      apellidoPat: json['apellido_pat'] as String? ?? '',
      apellidoMat: json['apellido_mat'] as String? ?? '',
      archivosCalificacion: archivos,
    );
  }

  String get nombreCompleto => '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.trim().replaceAll(RegExp(r'\s+'), ' ');
}
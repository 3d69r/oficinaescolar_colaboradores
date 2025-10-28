// alumno_salon_model.dart (Implementación COMPLETA con copyWith)

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

  // 🔑 MÉTODO AÑADIDO: Permite crear una nueva instancia con cambios
  AlumnoSalonModel copyWith({
    String? idAlumno,
    String? idCicloAlumno,
    String? nivelEducativo,
    String? idSalon,
    String? salon,
    String? primerNombre,
    String? segundoNombre,
    String? apellidoPat,
    String? apellidoMat,
    Map<String, String>? archivosCalificacion,
  }) {
    return AlumnoSalonModel(
      idAlumno: idAlumno ?? this.idAlumno,
      idCicloAlumno: idCicloAlumno ?? this.idCicloAlumno,
      nivelEducativo: nivelEducativo ?? this.nivelEducativo,
      idSalon: idSalon ?? this.idSalon,
      salon: salon ?? this.salon,
      primerNombre: primerNombre ?? this.primerNombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      apellidoPat: apellidoPat ?? this.apellidoPat,
      apellidoMat: apellidoMat ?? this.apellidoMat,
      archivosCalificacion: archivosCalificacion ?? this.archivosCalificacion,
    );
  }

  String get nombreCompleto => '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.trim().replaceAll(RegExp(r'\s+'), ' ');
}
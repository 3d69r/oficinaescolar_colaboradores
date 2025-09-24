class AlumnoAsistenciaModel {
  final String idCursoAlumno;
  final String idCurso;
  final String idAlumno;
  final bool activo;
  final String primerNombre;
  final String segundoNombre;
  final String apellidoPat;
  final String apellidoMat;

  // Propiedad calculada para simplificar la vista
  String get nombreCompleto {
    final List<String> parts = [primerNombre, segundoNombre, apellidoPat, apellidoMat]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  AlumnoAsistenciaModel({
    required this.idCursoAlumno,
    required this.idCurso,
    required this.idAlumno,
    required this.activo,
    required this.primerNombre,
    required this.segundoNombre,
    required this.apellidoPat,
    required this.apellidoMat,
  });

  factory AlumnoAsistenciaModel.fromJson(Map<String, dynamic> json) {
    return AlumnoAsistenciaModel(
      idCursoAlumno: json['id_curso_alu'] as String? ?? '',
      idCurso: json['id_curso'] as String? ?? '',
      idAlumno: json['id_alumno'] as String? ?? '',
      // Convertimos la cadena '1'/'0' a booleano
      activo: (json['activo'] as String? ?? '0') == '1',
      primerNombre: json['primer_nombre'] as String? ?? '',
      segundoNombre: json['segundo_nombre'] as String? ?? '',
      apellidoPat: json['apellido_pat'] as String? ?? '',
      apellidoMat: json['apellido_mat'] as String? ?? '',
    );
  }
}
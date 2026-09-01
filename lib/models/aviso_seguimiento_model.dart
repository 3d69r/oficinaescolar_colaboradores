class AvisoSeguimientoModel {
  final String idSeguimiento;
  final String idCalendario;
  final String segIdAlumno;
  final String segIdColaborador;
  final bool segLeido;
  final String segFechaLeido;
  final String segHoraLeido;
  final String segAceptadoRechazado;
  final String segIdPersona;
  final String segRespuesta;

  // Datos del alumno relacionado (para quien es el aviso)
  final String primerNombre;
  final String segundoNombre;
  final String apellidoPat;
  final String apellidoMat;
  final String salon;
  final String nivelEducativo;

  // Datos de quien vio el aviso (si fue un padre/madre)
  final String? nombrePersona;
  final String? apellidoPatPersona;
  final String? apellidoMatPersona;

  // Datos de quien vio el aviso (si fue un colaborador)
  final String? nombreColaborador;
  final String? apellidoPatColaborador;
  final String? apellidoMatColaborador;

  AvisoSeguimientoModel({
    required this.idSeguimiento,
    required this.idCalendario,
    required this.segIdAlumno,
    required this.segIdColaborador,
    required this.segLeido,
    required this.segFechaLeido,
    required this.segHoraLeido,
    required this.segAceptadoRechazado,
    required this.segIdPersona,
    required this.segRespuesta,
    required this.primerNombre,
    required this.segundoNombre,
    required this.apellidoPat,
    required this.apellidoMat,
    required this.salon,
    required this.nivelEducativo,
    this.nombrePersona,
    this.apellidoPatPersona,
    this.apellidoMatPersona,
    this.nombreColaborador,
    this.apellidoPatColaborador,
    this.apellidoMatColaborador,
  });

  factory AvisoSeguimientoModel.fromJson(Map<String, dynamic> json) {
    return AvisoSeguimientoModel(
      idSeguimiento: json['id_seguimiento']?.toString() ?? '',
      idCalendario: json['id_calendario']?.toString() ?? '',
      segIdAlumno: json['seg_id_alumno']?.toString() ?? '0',
      segIdColaborador: json['seg_id_colaborador']?.toString() ?? '0',
      segLeido: (json['seg_leido']?.toString() ?? '0') == '1',
      segFechaLeido: json['seg_fecha_leido']?.toString() ?? '',
      segHoraLeido: json['seg_hora_leido']?.toString() ?? '',
      segAceptadoRechazado: json['seg_aceptado_rechazado']?.toString() ?? '',
      segIdPersona: json['seg_id_persona']?.toString() ?? '0',
      segRespuesta: json['seg_respuesta']?.toString() ?? '',
      primerNombre: json['primer_nombre']?.toString() ?? '',
      segundoNombre: json['segundo_nombre']?.toString() ?? '',
      apellidoPat: json['apellido_pat']?.toString() ?? '',
      apellidoMat: json['apellido_mat']?.toString() ?? '',
      salon: json['salon']?.toString() ?? '',
      nivelEducativo: json['nivel_educativo']?.toString() ?? '',
      nombrePersona: json['nombre_persona']?.toString(),
      apellidoPatPersona: json['apellido_pat_persona']?.toString(),
      apellidoMatPersona: json['apellido_mat_persona']?.toString(),
      nombreColaborador: json['nombre_colaborador']?.toString(),
      apellidoPatColaborador: json['apellido_pat_colaborador']?.toString(),
      apellidoMatColaborador: json['apellido_mat_colaborador']?.toString(),
    );
  }

  // ⭐️ Getters de conveniencia para la UI

  String get nombreAlumnoRelacionado {
    final partes = [primerNombre, segundoNombre, apellidoPat, apellidoMat]
        .where((p) => p.trim().isNotEmpty);
    return partes.join(' ').trim();
  }

  /// 'papa' si lo vio un padre/madre, 'colaborador' si lo vio un colaborador, 'desconocido' si no hay dato
  String get tipoUsuario {
    if (segIdPersona.isNotEmpty && segIdPersona != '0') return 'papa';
    if (segIdColaborador.isNotEmpty && segIdColaborador != '0') return 'colaborador';
    return 'desconocido';
  }

  /// Nombre de quien realmente vio el aviso (papá/madre o colaborador)
  String get nombreVe {
    if (tipoUsuario == 'papa') {
      final partes = [nombrePersona, apellidoPatPersona, apellidoMatPersona]
          .where((p) => p != null && p.trim().isNotEmpty)
          .map((p) => p!);
      final nombre = partes.join(' ').trim();
      return nombre.isNotEmpty ? nombre : 'Padre/Madre de familia';
    }
    if (tipoUsuario == 'colaborador') {
      final partes = [nombreColaborador, apellidoPatColaborador, apellidoMatColaborador]
          .where((p) => p != null && p.trim().isNotEmpty)
          .map((p) => p!);
      final nombre = partes.join(' ').trim();
      return nombre.isNotEmpty ? nombre : 'Colaborador';
    }
    return 'Sin identificar';
  }

  String get fechaHoraLegible {
    if (segFechaLeido.isEmpty) return 'No leído aún';
    try {
      final DateTime fecha = DateTime.parse(segFechaLeido);
      final String fechaFormateada = '${fecha.day}/${fecha.month}/${fecha.year}';
      final String horaCorta = segHoraLeido.length >= 5 ? segHoraLeido.substring(0, 5) : segHoraLeido;
      return horaCorta.isNotEmpty ? '$fechaFormateada · $horaCorta' : fechaFormateada;
    } catch (e) {
      return '$segFechaLeido  $segHoraLeido'.trim();
    }
  }

  String? get respuestaLegible {
    if (segRespuesta.trim().isNotEmpty) return segRespuesta;
    if (segAceptadoRechazado.isNotEmpty && segAceptadoRechazado != 'No Aplica') {
      return segAceptadoRechazado;
    }
    return null;
  }
}
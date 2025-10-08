import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';

class ColaboradorModel {
  // Propiedades de la respuesta principal
  final String status;
  final String message;
  
  // Propiedades de las listas: Siempre serán Listas vacías si no hay datos.
  final List<MateriaModel> materiasData;
  final List<ClubModel> materiasClubes;
   // ⭐️ NUEVA PROPIEDAD: Lista de estructuras de boleta
  final List<BoletaEncabezadoModel> encabezadosBoleta;

  // Propiedades de 'persona_data'
  final String idColaborador;
  final String nombre;
  final String apellidoPat;
  final String apellidoMat;
  final String celular;
  final String escolaridad;
  final String curp;
  final String email;
  final String foto;
  final String idCredencial;
  final String password;
  final double cafeteriaSaldo;
  final String afiliacion;
  final bool accesoActivo;
  final String rutaFoto;

  ColaboradorModel({
    required this.status,
    required this.message,
    required this.materiasData,
    required this.materiasClubes,
    required this.encabezadosBoleta,
    required this.idColaborador,
    required this.nombre,
    required this.apellidoPat,
    required this.apellidoMat,
    required this.celular,
    required this.escolaridad,
    required this.curp,
    required this.email,
    required this.foto,
    required this.idCredencial,
    required this.password,
    required this.cafeteriaSaldo,
    required this.afiliacion,
    required this.accesoActivo,
    required this.rutaFoto,
  });

  factory ColaboradorModel.fromJson(Map<String, dynamic> json) {
    final personaData = json['persona_data'] as Map<String, dynamic>? ?? {};

    return ColaboradorModel(
      // Campos de la respuesta principal
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String? ?? '',
      
      // ✅ IMPLEMENTACIÓN ROBUSTA: Solo procede si el valor es una Lista
      materiasData: (json['materias_data'] is List)
          ? (json['materias_data'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => MateriaModel.fromJson(e))
              .toList()
          : [], // Si es null, false, o cualquier otra cosa, devuelve []
      
      // ✅ IMPLEMENTACIÓN ROBUSTA: Solo procede si el valor es una Lista
      materiasClubes: (json['materias_clubes'] is List)
          ? (json['materias_clubes'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => ClubModel.fromJson(e))
              .toList()
          : [], // Si es null, false, o cualquier otra cosa, devuelve []

          encabezadosBoleta: (json['encabezados_boleta'] is List)
          ? (json['encabezados_boleta'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => BoletaEncabezadoModel.fromJson(e))
              .toList()
          : [],
          
      // Mapeo de campos de persona_data
      idColaborador: personaData['id_colaborador'] as String? ?? '',
      nombre: personaData['nombre'] as String? ?? '',
      apellidoPat: personaData['apellido_pat'] as String? ?? '',
      apellidoMat: personaData['apellido_mat'] as String? ?? '',
      celular: personaData['celular'] as String? ?? '',
      escolaridad: personaData['escolaridad'] as String? ?? '',
      curp: personaData['curp'] as String? ?? '',
      email: personaData['email'] as String? ?? '',
      foto: personaData['foto'] as String? ?? '',
      idCredencial: personaData['id_credencial'] as String? ?? '',
      password: personaData['password'] as String? ?? '',
      cafeteriaSaldo: double.tryParse(personaData['cafeteria_saldo'] as String? ?? '0.0') ?? 0.0,
      afiliacion: personaData['afiliacion'] as String? ?? '',
      accesoActivo: (personaData['acceso_activo'] as String? ?? '0') == '1',
      rutaFoto: personaData['ruta_foto_persona'] as String? ?? '',
    );
  }
  String get nombreCompleto => '$nombre $apellidoPat $apellidoMat'.trim();
}

class MateriaModel {
  final String idCurso;
  final String idMateria;
  final String idMateriaClase;
  final String materia;
  final String codigoPlan;
  final String planEstudio;
  final String nivelEducativo;
  final String codigoMateriaClase;
  final String claveModulo;
  final String clasePeriodo;

  MateriaModel({
    required this.idCurso,
    required this.idMateria,
    required this.idMateriaClase,
    required this.materia,
    required this.codigoPlan,
    required this.planEstudio,
    required this.nivelEducativo,
    required this.codigoMateriaClase,
    required this.claveModulo,
    required this.clasePeriodo,
  });

  factory MateriaModel.fromJson(Map<String, dynamic> json) {
    return MateriaModel(
      idCurso: json['id_curso'] as String? ?? '',
      idMateria: json['id_materia'] as String? ?? '',
      idMateriaClase: json['id_materia_clase'] as String? ?? '',
      materia: json['materia'] as String? ?? '',
      codigoPlan: json['codigo_plan'] as String? ?? '',
      planEstudio: json['plan_estudio'] as String? ?? '',
      nivelEducativo: json['nivel_educativo'] as String? ?? '',
      codigoMateriaClase: json['codigo_materia_clase'] as String? ?? '',
      claveModulo: json['clave_modulo'] as String? ?? '',
      clasePeriodo: json['clase_periodo'] as String? ?? '',
    );
  }
}

class ClubModel {
  final String idCurso;
  final String idClub;
  final String idMaestro;
  final String idAuxiliar;
  final String nombreCurso;
  final String fechaInicia;
  final String fechaTermino;
  final String horario;
  final String diasSemana;

  ClubModel({
    required this.idCurso,
    required this.idClub,
    required this.idMaestro,
    required this.idAuxiliar,
    required this.nombreCurso,
    required this.fechaInicia,
    required this.fechaTermino,
    required this.horario,
    required this.diasSemana,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      idCurso: json['id_curso'] as String? ?? '',
      idClub: json['id_club'] as String? ?? '',
      idMaestro: json['id_maestro'] as String? ?? '',
      idAuxiliar: json['id_auxiliar'] as String? ?? '',
      nombreCurso: json['nombre_curso'] as String? ?? '',
      fechaInicia: json['fecha_inicia'] as String? ?? '',
      fechaTermino: json['fecha_termino'] as String? ?? '',
      horario: json['horario'] as String? ?? '',
      diasSemana: json['dias_semana'] as String? ?? '',
    );
  }
}
import 'package:oficinaescolar_colaboradores/models/alumno_salon_model.dart';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';

class ColaboradorModel {
  // Propiedades de la respuesta principal
  final String status;
  final String message;
  
  // Propiedades de las listas existentes
  final List<MateriaModel> materiasData;
  final List<ClubModel> materiasClubes;
  final List<BoletaEncabezadoModel> encabezadosBoleta;
  final List<AlumnoSalonModel> alumnosSalon;

  // ⭐️ NUEVAS PROPIEDADES DE LISTA AÑADIDAS (de los campos "aviso_...")
  final List<AvisoNivelEducativoModel> avisoNivelesEducativos;
  final List<AvisoSalaModel> avisoSalones;
  final List<AvisoAlumnoModel> avisoAlumnos;
  final List<AvisoColaboradorModel> avisoColaboradores;


  // Propiedades de 'persona_data' (EXISTENTES)
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
  final bool accesoActivo; // Convertido de String "1" a bool
  final String rutaFoto;
  final String puesto;

  ColaboradorModel({
    required this.status,
    required this.message,
    required this.materiasData,
    required this.materiasClubes,
    required this.encabezadosBoleta,
    required this.alumnosSalon,
    // ⭐️ NUEVOS PARÁMETROS EN EL CONSTRUCTOR
    required this.avisoNivelesEducativos,
    required this.avisoSalones,
    required this.avisoAlumnos,
    required this.avisoColaboradores,
    // PROPIEDADES DE PERSONA_DATA
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
    required this.puesto,
  });

  factory ColaboradorModel.fromJson(Map<String, dynamic> json) {
    final personaData = json['persona_data'] as Map<String, dynamic>? ?? {};

    return ColaboradorModel(
      // Campos de la respuesta principal
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String? ?? '',
      
      // Mapeo de listas existentes (asumiendo que AlumnoSalonModel y BoletaEncabezadoModel
      // se definen o importan correctamente)
      materiasData: (json['materias_data'] is List)
          ? (json['materias_data'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => MateriaModel.fromJson(e))
              .toList()
          : [], 
      
      materiasClubes: (json['materias_clubes'] is List)
          ? (json['materias_clubes'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => ClubModel.fromJson(e))
              .toList()
          : [], 

      encabezadosBoleta: (json['encabezados_boleta'] is List)
          ? (json['encabezados_boleta'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              // NOTA: Reemplaza 'BoletaEncabezadoModel.fromJson' con el constructor real de tu clase.
              .map((e) => BoletaEncabezadoModel.fromJson(e)) 
              .toList()
          : [],

      alumnosSalon: (json['alumnos_salon'] is List)
          ? (json['alumnos_salon'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              // NOTA: Reemplaza 'AlumnoSalonModel.fromJson' con el constructor real de tu clase.
              .map((e) => AlumnoSalonModel.fromJson(e)) 
              .toList()
          : [],
          
      // ⭐️ MAPEO DE LAS NUEVAS LISTAS
      avisoNivelesEducativos: (json['aviso_niveles_educativos'] is List)
          ? (json['aviso_niveles_educativos'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => AvisoNivelEducativoModel.fromJson(e))
              .toList()
          : [], 

      avisoSalones: (json['aviso_salones'] is List)
          ? (json['aviso_salones'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => AvisoSalaModel.fromJson(e))
              .toList()
          : [], 

      avisoAlumnos: (json['aviso_alumnos'] is List)
          ? (json['aviso_alumnos'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => AvisoAlumnoModel.fromJson(e))
              .toList()
          : [], 

      avisoColaboradores: (json['aviso_colaboradores'] is List)
          ? (json['aviso_colaboradores'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((e) => AvisoColaboradorModel.fromJson(e))
              .toList()
          : [], 

      // Mapeo de campos de persona_data (EXISTENTES)
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
      puesto: personaData['puesto'] as String? ?? '',
      // Conversión segura de saldo
      cafeteriaSaldo: double.tryParse(personaData['cafeteria_saldo'] as String? ?? '0.0') ?? 0.0,
      afiliacion: personaData['afiliacion'] as String? ?? '',
      // Conversión de "1" a true, cualquier otra cosa a false
      accesoActivo: (personaData['acceso_activo'] as String? ?? '0') == '1',
      rutaFoto: personaData['ruta_foto_persona'] as String? ?? '',
    );
  }
  
  String get nombreCompleto => '$nombre $apellidoPat $apellidoMat'.trim();
}

// -----------------------------------------------------------------------------
// CLASES DE SOPORTE EXISTENTES (MateriaModel y ClubModel)
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// ⭐️ NUEVOS MODELOS DE SOPORTE (aviso_...)
// -----------------------------------------------------------------------------

class AvisoNivelEducativoModel {
  final String nivelEducativo;

  AvisoNivelEducativoModel({
    required this.nivelEducativo,
  });

  factory AvisoNivelEducativoModel.fromJson(Map<String, dynamic> json) {
    return AvisoNivelEducativoModel(
      nivelEducativo: json['nivel_educativo'] as String? ?? '',
    );
  }
}

class AvisoSalaModel {
  final String idSalon;
  final String idEmpresa;
  final String idCiclo;
  final String salon;
  final String capInstalada;
  final String nivelEducativo;
  final String autRvoe;
  final String idSalonOtroSistema;
  final bool activo;

  AvisoSalaModel({
    required this.idSalon,
    required this.idEmpresa,
    required this.idCiclo,
    required this.salon,
    required this.capInstalada,
    required this.nivelEducativo,
    required this.autRvoe,
    required this.idSalonOtroSistema,
    required this.activo,
  });

  factory AvisoSalaModel.fromJson(Map<String, dynamic> json) {
    final String activoStr = json['activo'] as String? ?? '0';

    return AvisoSalaModel(
      idSalon: json['id_salon'] as String? ?? '',
      idEmpresa: json['id_empresa'] as String? ?? '',
      idCiclo: json['id_ciclo'] as String? ?? '',
      salon: json['salon'] as String? ?? '',
      capInstalada: json['cap_instalada'] as String? ?? '',
      nivelEducativo: json['nivel_educativo'] as String? ?? '',
      autRvoe: json['aut_rvoe'] as String? ?? '',
      idSalonOtroSistema: json['id_salon_otro_sistema'] as String? ?? '',
      activo: activoStr == '1',
    );
  }
}

class AvisoAlumnoModel {
  final String idAlumno;
  final String primerNombre;
  final String segundoNombre;
  final String apellidoPat;
  final String apellidoMat;
  final String cicloFechaBaja;
  final String idCiclo;
  final String salon;
  final String nivelEducativo;
  final String idSalon;
  final String? nombreCurso; 
  final String? idCurso;     
  final String? fechaBajaCurso; 

  AvisoAlumnoModel({
    required this.idAlumno,
    required this.primerNombre,
    required this.segundoNombre,
    required this.apellidoPat,
    required this.apellidoMat,
    required this.cicloFechaBaja,
    required this.idCiclo,
    required this.salon,
    required this.nivelEducativo,
    required this.idSalon,
    this.nombreCurso,
    this.idCurso,
    this.fechaBajaCurso,
  });

  factory AvisoAlumnoModel.fromJson(Map<String, dynamic> json) {
    return AvisoAlumnoModel(
      idAlumno: json['id_alumno'] as String? ?? '',
      primerNombre: json['primer_nombre'] as String? ?? '',
      segundoNombre: json['segundo_nombre'] as String? ?? '',
      apellidoPat: json['apellido_pat'] as String? ?? '',
      apellidoMat: json['apellido_mat'] as String? ?? '',
      cicloFechaBaja: json['ciclo_fecha_baja'] as String? ?? '',
      idCiclo: json['id_ciclo'] as String? ?? '',
      salon: json['salon'] as String? ?? '',
      nivelEducativo: json['nivel_educativo'] as String? ?? '',
      idSalon: json['id_salon'] as String? ?? '',
      // Los campos que pueden ser null en el JSON se dejan como String?
      nombreCurso: json['nombre_curso'] as String?, 
      idCurso: json['id_curso'] as String?,         
      fechaBajaCurso: json['fecha_baja_curso'] as String?,
    );
  }
}

class AvisoColaboradorModel {
  final String idColaborador;
  final String nombre;
  final String apellidoPat;
  final String apellidoMat;
  final String area;
  final String departamento;

  AvisoColaboradorModel({
    required this.idColaborador,
    required this.nombre,
    required this.apellidoPat,
    required this.apellidoMat,
    required this.area,
    required this.departamento,
  });

  factory AvisoColaboradorModel.fromJson(Map<String, dynamic> json) {
    return AvisoColaboradorModel(
      idColaborador: json['id_colaborador'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellidoPat: json['apellido_pat'] as String? ?? '',
      apellidoMat: json['apellido_mat'] as String? ?? '',
      area: json['area'] as String? ?? '',
      departamento: json['departamento'] as String? ?? '',
    );
  }
  
  String get nombreCompleto => '$nombre $apellidoPat $apellidoMat'.trim();
}
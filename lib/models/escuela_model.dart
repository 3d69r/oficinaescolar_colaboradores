class Contacto {
  final String nombreCat;
  final String telefono;
  final String correo;
  final String adicional3;
  final String adicional4;
  final String adicional5;
  final String adicional6;
  final String adicional7;
  final String adicional8;
  final String adicional9;
  final String adicional10;
  final String adicional11;
  final String adicional12;
  final String adicional13;
  final String adicional14;

  Contacto({
    required this.nombreCat,
    required this.telefono,
    required this.correo,
    required this.adicional3,
    required this.adicional4,
    required this.adicional5,
    required this.adicional6,
    required this.adicional7,
    required this.adicional8,
    required this.adicional9,
    required this.adicional10,
    required this.adicional11,
    required this.adicional12,
    required this.adicional13,
    required this.adicional14,
  });

  factory Contacto.fromJson(Map<String, dynamic> json) {
    return Contacto(
      nombreCat: json['nombre_cat']?.toString() ?? '',
      telefono: json['adicional']?.toString() ?? '',
      correo: json['adicional_2']?.toString() ?? '',
      adicional3: json['adicional_3']?.toString() ?? '',
      adicional4: json['adicional_4']?.toString() ?? '',
      adicional5: json['adicional_5']?.toString() ?? '',
      adicional6: json['adicional_6']?.toString() ?? '',
      adicional7: json['adicional_7']?.toString() ?? '',
      adicional8: json['adicional_8']?.toString() ?? '',
      adicional9: json['adicional_9']?.toString() ?? '',
      adicional10: json['adicional_10']?.toString() ?? '',
      adicional11: json['adicional_11']?.toString() ?? '',
      adicional12: json['adicional_12']?.toString() ?? '',
      adicional13: json['adicional_13']?.toString() ?? '',
      adicional14: json['adicional_14']?.toString() ?? '',
    );
  }
}

class Domicilio {
  final String idEmpresa;
  final String idCatalogo;
  final String catalogo;
  final String nombreCat;
  final String adicional;
  final String adicional2;
  final String adicional3;
  final String adicional4;
  final String adicional5;
  final String adicional6;
  final String adicional7;
  final String adicional8;
  final String adicional9;
  final String adicional10;
  final String adicional11;
  final String adicional12;
  final String adicional13;
  final String adicional14;

  Domicilio({
    required this.idEmpresa,
    required this.idCatalogo,
    required this.catalogo,
    required this.nombreCat,
    required this.adicional,
    required this.adicional2,
    required this.adicional3,
    required this.adicional4,
    required this.adicional5,
    required this.adicional6,
    required this.adicional7,
    required this.adicional8,
    required this.adicional9,
    required this.adicional10,
    required this.adicional11,
    required this.adicional12,
    required this.adicional13,
    required this.adicional14,
  });

  factory Domicilio.fromJson(Map<String, dynamic> json) {
    return Domicilio(
      idEmpresa: json['id_empresa']?.toString() ?? '',
      idCatalogo: json['id_catalogo']?.toString() ?? '',
      catalogo: json['catalogo']?.toString() ?? '',
      nombreCat: json['nombre_cat']?.toString() ?? '',
      adicional: json['adicional']?.toString() ?? '',
      adicional2: json['adicional_2']?.toString() ?? '',
      adicional3: json['adicional_3']?.toString() ?? '',
      adicional4: json['adicional_4']?.toString() ?? '',
      adicional5: json['adicional_5']?.toString() ?? '',
      adicional6: json['adicional_6']?.toString() ?? '',
      adicional7: json['adicional_7']?.toString() ?? '',
      adicional8: json['adicional_8']?.toString() ?? '',
      adicional9: json['adicional_9']?.toString() ?? '',
      adicional10: json['adicional_10']?.toString() ?? '',
      adicional11: json['adicional_11']?.toString() ?? '',
      adicional12: json['adicional_12']?.toString() ?? '',
      adicional13: json['adicional_13']?.toString() ?? '',
      adicional14: json['adicional_14']?.toString() ?? '',
    );
  }
}

class WebInteres {
  final String idEmpresa;
  final String idCatalogo;
  final String catalogo;
  final String nombreCat;
  final String adicional;
  final String adicional2;
  final String adicional3;
  final String adicional4;
  final String adicional5;
  final String adicional6;
  final String adicional7;
  final String adicional8;
  final String adicional9;
  final String adicional10;
  final String adicional11;
  final String adicional12;
  final String adicional13;
  final String adicional14;

  WebInteres({
    required this.idEmpresa,
    required this.idCatalogo,
    required this.catalogo,
    required this.nombreCat,
    required this.adicional,
    required this.adicional2,
    required this.adicional3,
    required this.adicional4,
    required this.adicional5,
    required this.adicional6,
    required this.adicional7,
    required this.adicional8,
    required this.adicional9,
    required this.adicional10,
    required this.adicional11,
    required this.adicional12,
    required this.adicional13,
    required this.adicional14,
  });

  factory WebInteres.fromJson(Map<String, dynamic> json) {
    return WebInteres(
      idEmpresa: json['id_empresa']?.toString() ?? '',
      idCatalogo: json['id_catalogo']?.toString() ?? '',
      catalogo: json['catalogo']?.toString() ?? '',
      nombreCat: json['nombre_cat']?.toString() ?? '',
      adicional: json['adicional']?.toString() ?? '',
      adicional2: json['adicional_2']?.toString() ?? '',
      adicional3: json['adicional_3']?.toString() ?? '',
      adicional4: json['adicional_4']?.toString() ?? '',
      adicional5: json['adicional_5']?.toString() ?? '',
      adicional6: json['adicional_6']?.toString() ?? '',
      adicional7: json['adicional_7']?.toString() ?? '',
      adicional8: json['adicional_8']?.toString() ?? '',
      adicional9: json['adicional_9']?.toString() ?? '',
      adicional10: json['adicional_10']?.toString() ?? '',
      adicional11: json['adicional_11']?.toString() ?? '',
      adicional12: json['adicional_12']?.toString() ?? '',
      adicional13: json['adicional_13']?.toString() ?? '',
      adicional14: json['adicional_14']?.toString() ?? '',
    );
  }
}

class CicloEscolar {
  final String idEmpresa;
  final String idCiclo;
  final String fechaInicio;
  final String fechaTermino;
  final String periodo;

  CicloEscolar({
    required this.idEmpresa,
    required this.idCiclo,
    required this.fechaInicio,
    required this.fechaTermino,
    required this.periodo,
  });

  factory CicloEscolar.fromJson(Map<String, dynamic> json) {
    return CicloEscolar(
      idEmpresa: json['id_empresa']?.toString() ?? '',
      idCiclo: json['id_ciclo']?.toString() ?? '',
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaTermino: json['fecha_termino']?.toString() ?? '',
      periodo: json['periodo']?.toString() ?? '',
    );
  }
}

class CuentaBancaria {
  final String idBanco;
  final String banco;
  final String tipo;
  final String descripcion;
  final String beneficiario;
  final String cuenta;
  final String clabe;
  final String idEmpresa;

  CuentaBancaria({
    required this.idBanco,
    required this.banco,
    required this.tipo,
    required this.descripcion,
    required this.beneficiario,
    required this.cuenta,
    required this.clabe,
    required this.idEmpresa,
  });

  factory CuentaBancaria.fromJson(Map<String, dynamic> json) {
    return CuentaBancaria(
      idBanco: json['id_banco']?.toString() ?? '',
      banco: json['banco']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      beneficiario: json['beneficiario']?.toString() ?? '',
      cuenta: json['cuenta']?.toString() ?? '',
      clabe: json['clabe']?.toString() ?? '',
      idEmpresa: json['id_empresa']?.toString() ?? '',
    );
  }
}

class PeriodoCafeteria {
  final String idPeriodo;
  final String periodo;
  final String fechaInicio;
  final String fechaTermino;
  final String activo;
  final String tipoPeriodo;
  final String idEmpresa;
  final String idCiclo;

  PeriodoCafeteria({
    required this.idPeriodo,
    required this.periodo,
    required this.fechaInicio,
    required this.fechaTermino,
    required this.activo,
    required this.tipoPeriodo,
    required this.idEmpresa,
    required this.idCiclo,
  });

  factory PeriodoCafeteria.fromJson(Map<String, dynamic> json) {
    return PeriodoCafeteria(
      idPeriodo: json['id_periodo']?.toString() ?? '',
      periodo: json['periodo']?.toString() ?? '',
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaTermino: json['fecha_termino']?.toString() ?? '',
      activo: json['activo']?.toString() ?? '',
      tipoPeriodo: json['tipo_periodo']?.toString() ?? '',
      idEmpresa: json['id_empresa']?.toString() ?? '',
      idCiclo: json['id_ciclo']?.toString() ?? '',
    );
  }
}

class EscuelaModel {
  final String status;
  final String message;
  final String idEmpresa;
  final String nombreComercial;
  final String razonSocial;
  final String rfc;
  final String calle;
  final String numeroExterior;
  final String numeroInterior;
  final String colonia;
  final String codigoPostal;
  final String municipio;
  final String estado;
  final String rutaLogo;
  final String appPermisos;
  final String rutaFirma;
  String? logoLocalPath; 
  DateTime? logoCacheTimestamp; 

  final String empDirector;
  final String empDirectorPreesco;
  final String empDirectorPrim;
  final String empDirectorSec;
  final String empDirectorPrepa;

  final CicloEscolar cicloEscolar;
  final List<Contacto> contactos;
  final List<Domicilio>? dirDomicilios; 
  final List<WebInteres>? websDeInteres;
  final List<CuentaBancaria> cuentasBancarias;
  final List<CuentaBancaria> cuentasBancariasCaf;
  final List<PeriodoCafeteria> cafPeriodos;
  final String cafPeriodoActual;

  EscuelaModel({
    required this.status,
    required this.message,
    required this.idEmpresa,
    required this.nombreComercial,
    required this.razonSocial,
    required this.rfc,
    required this.calle,
    required this.numeroExterior,
    required this.numeroInterior,
    required this.colonia,
    required this.codigoPostal,
    required this.municipio,
    required this.estado,
    required this.rutaLogo,
    required this.appPermisos,
    required this.rutaFirma,
    this.logoLocalPath,
    this.logoCacheTimestamp,
    required this.empDirector,
    required this.empDirectorPreesco,
    required this.empDirectorPrim,
    required this.empDirectorSec,
    required this.empDirectorPrepa,
    required this.cicloEscolar,
    required this.contactos,
    required this.dirDomicilios,
    required this.websDeInteres,
    required this.cuentasBancarias,
    required this.cuentasBancariasCaf,
    required this.cafPeriodos,
    required this.cafPeriodoActual,
  });

  factory EscuelaModel.fromJson(Map<String, dynamic> json) {
    final schoolJson = json['school'] as Map<String, dynamic>? ?? {};
    final cicloEscolarJson = json['ciclo_esc'] as Map<String, dynamic>? ?? {};

    final contactosJson = (json['dir_contacto'] is List) ? json['dir_contacto'] as List<dynamic> : [];
    final dirDomiciliosJson = (json['dir_domicilios'] is List) ? json['dir_domicilios'] as List<dynamic> : null; 
    final websDeInteresJson = (json['webs_de_interes'] is List) ? json['webs_de_interes'] as List<dynamic> : null;

    final cuentasJson = (json['cuentas_bancarias'] is List) ? json['cuentas_bancarias'] as List<dynamic> : [];
    final cuentasCafJson = (json['cuentas_bancarias_caf'] is List) ? json['cuentas_bancarias_caf'] as List<dynamic> : [];
    final cafPeriodosJson = (json['caf_periodos'] is List) ? json['caf_periodos'] as List<dynamic> : [];

    return EscuelaModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      idEmpresa: schoolJson['id_empresa']?.toString() ?? '',
      nombreComercial: schoolJson['emp_nombre_com']?.toString() ?? '',
      razonSocial: schoolJson['emp_razon_social']?.toString() ?? '',
      rfc: schoolJson['emp_rfc']?.toString() ?? '',
      calle: schoolJson['emp_calle']?.toString() ?? '',
      numeroExterior: schoolJson['emp_num_ext']?.toString() ?? '',
      numeroInterior: schoolJson['emp_num_int']?.toString() ?? '',
      colonia: schoolJson['emp_colonia']?.toString() ?? '',
      codigoPostal: schoolJson['emp_cod_postal']?.toString() ?? '',
      municipio: schoolJson['municipio']?.toString() ?? '',
      estado: schoolJson['estado']?.toString() ?? '',
      empDirector: schoolJson['emp_director']?.toString() ?? '',
      empDirectorPreesco: schoolJson['emp_director_preesco']?.toString() ?? '',
      empDirectorPrim: schoolJson['emp_director_prim']?.toString() ?? '',
      empDirectorSec: schoolJson['emp_director_sec']?.toString() ?? '',
      empDirectorPrepa: schoolJson['emp_director_prepa']?.toString() ?? '',
      rutaLogo: schoolJson['ruta_logo']?.toString() ?? '',
      rutaFirma: schoolJson['ruta_credencial_firma']?.toString() ?? '',
      appPermisos: schoolJson['app_permisos']?.toString() ?? '',
      cicloEscolar: CicloEscolar.fromJson(cicloEscolarJson),
      contactos: contactosJson.map((e) => Contacto.fromJson(e as Map<String, dynamic>)).toList(),
       dirDomicilios: dirDomiciliosJson?.map((e) => Domicilio.fromJson(e as Map<String, dynamic>)).toList() ?? [], 
       websDeInteres: websDeInteresJson?.map((e) => WebInteres.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      cuentasBancarias: cuentasJson.map((e) => CuentaBancaria.fromJson(e as Map<String, dynamic>)).toList(),
      cuentasBancariasCaf: cuentasCafJson.map((e) => CuentaBancaria.fromJson(e as Map<String, dynamic>)).toList(),
      cafPeriodos: cafPeriodosJson.map((e) => PeriodoCafeteria.fromJson(e as Map<String, dynamic>)).toList(),
      cafPeriodoActual: json['caf_periodo_actual']?.toString() ?? '',
    );
  }
}
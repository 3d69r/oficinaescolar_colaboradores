// lib/models/aviso_model.dart

class AvisoModel {
  final String idCalendario;
  final String titulo;
  final String colorTitulo;
  final String comentario;
  final DateTime fecha;
  final DateTime fechaFin;
  final String? archivo;
  bool leido;

  // Nuevos campos de la API
  final String? seccion;
  final String? tipoRespuesta;
  final String? segRespuesta;
  final String? opcion1;
  final String? opcion2;
  final String? opcion3;
  final String? opcion4;
  final String? opcion5;


  // Nuevos campos para la lógica de caché
  String? imagenLocalPath;
  DateTime? imagenCacheTimestamp;



  AvisoModel({
    required this.idCalendario,
    required this.titulo,
    required this.colorTitulo,
    required this.comentario,
    required this.fecha,
    required this.fechaFin,
    this.archivo,
    this.leido = false,
    this.seccion,
    this.tipoRespuesta,
    this.segRespuesta,
    this.opcion1,
    this.opcion2,
    this.opcion3,
    this.opcion4,
    this.opcion5,
    //this.archivoPdf,
    this.imagenLocalPath,
    this.imagenCacheTimestamp,
    //this.archivoPdfLocalPath,
  });

  // Constructor para crear un AvisoModel desde la API
  factory AvisoModel.fromJson(Map<String, dynamic> json) {
    bool isRead = false;
    if (json.containsKey('seg_leido')) {
      isRead = json['seg_leido'].toString() == '1';
    } else if (json.containsKey('leido')) {
      isRead = json['leido'] == 1 || json['leido'] == true;
    }

    return AvisoModel(
      idCalendario: json['id_calendario'].toString(),
      titulo: json['titulo'].toString(),
      colorTitulo: json['color_titulo'].toString(),
      comentario: json['comentario'].toString(),
      fecha: DateTime.parse(json['fecha'].toString()),
      fechaFin: DateTime.parse(json['fecha_fin'].toString()),
      leido: isRead,
      archivo: json['archivo'] as String?,
      seccion: json['seccion'] as String?,
      tipoRespuesta: json['tipo_respuesta'] as String?,
      segRespuesta: json['seg_respuesta'] as String?,
      opcion1: json['opcion_1'] as String?,
      opcion2: json['opcion_2'] as String?,
      opcion3: json['opcion_3'] as String?,
      opcion4: json['opcion_4'] as String?,
      opcion5: json['opcion_5'] as String?,
    );
  }

  // Constructor para crear un AvisoModel desde la base de datos local
  factory AvisoModel.fromDatabaseJson(Map<String, dynamic> json) {
    return AvisoModel(
      idCalendario: json['id_calendario'].toString(),
      titulo: json['titulo'].toString(),
      colorTitulo: json['color_titulo'].toString(),
      comentario: json['comentario'].toString(),
      fecha: DateTime.parse(json['fecha'].toString()),
      fechaFin: DateTime.parse(json['fecha_fin'].toString()),
      leido: json['leido'] == 1,
      archivo: json['archivo'] as String?,
      seccion: json['seccion'] as String?,
      tipoRespuesta: json['tipo_respuesta'] as String?,
      segRespuesta: json['seg_respuesta'] as String?,
      opcion1: json['opcion_1'] as String?,
      opcion2: json['opcion_2'] as String?,
      opcion3: json['opcion_3'] as String?,
      opcion4: json['opcion_4'] as String?,
      opcion5: json['opcion_5'] as String?,
      imagenLocalPath: json['imagenLocalPath'] as String?,
      imagenCacheTimestamp: json['imagenCacheTimestamp'] != null
          ? DateTime.parse(json['imagenCacheTimestamp'] as String)
          : null,
    );
  }

  // Método para convertir el modelo a un mapa JSON para guardar en la base de datos
  Map<String, dynamic> toDatabaseJson() {
    return {
      'id_calendario': idCalendario,
      'titulo': titulo,
      'color_titulo': colorTitulo,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'archivo': archivo,
      'leido': leido ? 1 : 0,
      'seccion': seccion,
      'tipo_respuesta': tipoRespuesta,
      'seg_respuesta': segRespuesta,
      'opcion_1': opcion1,
      'opcion_2': opcion2,
      'opcion_3': opcion3,
      'opcion_4': opcion4,
      'opcion_5': opcion5,
      'imagenLocalPath': imagenLocalPath,
      'imagenCacheTimestamp': imagenCacheTimestamp?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id_calendario': idCalendario,
      'titulo': titulo,
      'color_titulo': colorTitulo,
      'comentario': comentario,
      'fecha': fecha.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'archivo': archivo,
      'leido': leido ? 1 : 0,
      'seccion': seccion,
      'tipo_respuesta': tipoRespuesta,
      'seg_respuesta': segRespuesta,
      'opcion_1': opcion1,
      'opcion_2': opcion2,
      'opcion_3': opcion3,
      'opcion_4': opcion4,
      'opcion_5': opcion5,
    };
  }
}
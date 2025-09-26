// Nuevo modelo para manejar la estructura de la boleta de calificaciones
class BoletaEncabezadoModel {
  final String nivelEducativo;
  final Map<String, String> encabezados; // { 'Parcial 1': 'enc_relacion_1', 'Trimestre 1': 'parcial_1' }
  final Map<String, String> relaciones;  // { 'enc_relacion_1': 'parcial_1', ... }
  final Map<String, String> comentarios; // { 'comentario_parcial_2': '', ... }
  final String? promedioKey; // Para planes con promedio

  BoletaEncabezadoModel({
    required this.nivelEducativo,
    required this.encabezados,
    required this.relaciones,
    required this.comentarios,
    this.promedioKey,
  });

  factory BoletaEncabezadoModel.fromJson(Map<String, dynamic> json) {
    final Map<String, String> headers = {};
    final Map<String, String> relations = {};
    final Map<String, String> comments = {};
    String? promedio = json.containsKey('promedio') ? json['promedio'] as String? : null;

    for (int i = 1; i <= 8; i++) {
      final headerKey = 'encabezado_$i';
      final relationKey = 'enc_relacion_$i';
      final commentKey = 'comentario_parcial_$i';
      
      if (json.containsKey(headerKey) && (json[headerKey] as String?)?.isNotEmpty == true) {
        final headerValue = json[headerKey] as String;
        headers[headerValue] = relationKey; // Almacena el nombre del encabezado y su clave de relación
        
        if (json.containsKey(relationKey)) {
          relations[relationKey] = json[relationKey] as String;
        }

        if (json.containsKey(commentKey)) {
           comments[commentKey] = json[commentKey] as String;
        }
      }
    }

    return BoletaEncabezadoModel(
      nivelEducativo: json['nivel_educativo'] as String? ?? '',
      encabezados: headers,
      relaciones: relations,
      comentarios: comments,
      promedioKey: promedio,
    );
  }
}
// datos_archivo_a_subir.dart

import 'dart:typed_data';

/// Modelo que encapsula los datos necesarios para subir un archivo.
/// Se usa para manejar de forma unificada la ruta local (Móvil) o los bytes (Web).
class DatosArchivoASubir {
  final String nombreCampoApi; // Ej: 'archivo_calif_1'
  final String? rutaLocal;      // Usado en Móvil/Desktop
  final Uint8List? bytesArchivo; // Usado en Web (bytes)
  final String? nombreArchivo;  // Nombre del archivo (necesario para Web)

  DatosArchivoASubir({
    required this.nombreCampoApi,
    this.rutaLocal,
    this.bytesArchivo,
    this.nombreArchivo,
  });
}
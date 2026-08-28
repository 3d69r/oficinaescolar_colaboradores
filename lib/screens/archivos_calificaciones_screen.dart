import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/models/datos_archivo_a_subir.dart';
import 'package:oficinaescolar_colaboradores/screens/pdf_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'dart:io'; 
import 'package:oficinaescolar_colaboradores/utils/log_util.dart';
import 'package:file_picker/file_picker.dart'; 
// import 'package:shared_preferences/shared_preferences.dart'; // ❌ Eliminada

import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/alumno_salon_model.dart'; 

class ArchivosCalificacionesScreen extends StatefulWidget {
  
  final String salonSeleccionado;
  final List<AlumnoSalonModel> alumnosSalon;

  const ArchivosCalificacionesScreen({
    super.key,
    required this.salonSeleccionado,
    required this.alumnosSalon,
  });

  @override
  State<ArchivosCalificacionesScreen> createState() => _ArchivosCalificacionesScreenState();
}

class _ArchivosCalificacionesScreenState extends State<ArchivosCalificacionesScreen> {
  
  List<AlumnoSalonModel> _alumnosDelSalon = [];
  final Map<String, String?> _selectedFilePaths = {};
  bool _isLoading = true;
  
  // static const String _persistenciaKey = 'archivos_calificaciones_urls'; // ❌ Eliminada

  @override
  void initState() {
    super.initState();
    appLog('DEBUG VISTA: initState - Cargando alumnos del salón.'); // ⭐️ DEBUG
    _cargarAlumnosDelSalon();
  }

  /// Asigna y ordena los alumnos proporcionados por la vista anterior.
  void _cargarAlumnosDelSalon() async { 
    List<AlumnoSalonModel> alumnos = widget.alumnosSalon;
    
    // ❌ Eliminada la llamada a _sincronizar_con_shared_preferences(alumnos);

    alumnos.sort((a, b) => a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));

    if (mounted) {
      setState(() {
        _alumnosDelSalon = alumnos;
        _isLoading = false;
        appLog('DEBUG VISTA: setState - Alumnos cargados y listos.'); // ⭐️ DEBUG
      });
    }
  }
  
  String _getFileNameFromPath(String? path) {
      if (path == null || path.isEmpty) return 'Archivo';
      final lastSeparator = path.lastIndexOf('/');
      if (lastSeparator == -1) return path;
      return path.substring(lastSeparator + 1);
  }

  // ⭐️ MODIFICACIÓN CLAVE: Subida instantánea al seleccionar ⭐️
/// Abre el selector de archivos (PDF), almacena la ruta local y llama a la subida inmediata.
Uint8List? bytesArchivoWeb; 
String? nombreArchivoWeb; 
// ------------------------------------------------------------------------

void _seleccionarArchivo(AlumnoSalonModel alumno, String campoArchivo) async {
  final key = '${alumno.idCicloAlumno}_$campoArchivo';
  appLog('DEBUG SELECCIONAR: Iniciando selección de archivo para campo: $campoArchivo'); // ⭐️ DEBUG

  FilePickerResult? result;

  // 🧩 INICIALIZACIÓN SEGURA DEL FILE PICKER EN WEB
  if (kIsWeb) {
    // 🔧 Forzar inicialización segura del FilePicker en web
    try {
      await FilePicker.platform.clearTemporaryFiles();
      appLog('DEBUG FILE_PICKER: Inicialización segura completada en Web ✅');
    } catch (e) {
      appLog('DEBUG FILE_PICKER: Error durante clearTemporaryFiles(): $e');
    }
  }

  // 🛑 BLOQUE TRY-CATCH AÑADIDO PARA DEPURACIÓN EN WEB
  try {
    // 🔑 MODIFICACIÓN: Pedir bytes (withData: true) solo si es Web
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: kIsWeb ? true : false, // 🛠️ CORRECCIÓN WEB
    );
  } catch (e) {
    // Muestra el error capturado en el log y al usuario (SnackBar).
    appLog('FILE_PICKER_CATCH_ERROR: Error al intentar seleccionar archivo: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error de selección (seguridad/web): ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
    return; // Detiene la ejecución si hay un error en la selección.
  }

  // Si la selección fue cancelada o fallida sin lanzar una excepción capturable
  if (result == null || result.files.isEmpty) {
    appLog('DEBUG SELECCIONAR: Selección de archivo cancelada o fallida.'); // ⭐️ DEBUG
    return;
  }

  final archivoSeleccionado = result.files.single;

  // --- LÓGICA MÓVIL/DESKTOP ---
  if (!kIsWeb) {
    final filePath = archivoSeleccionado.path;

    if (filePath != null) {
      // 1. Guardar la ruta seleccionada temporalmente
      if (mounted) {
        setState(() {
          _selectedFilePaths[key] = filePath;
          // Limpiar las variables Web
          bytesArchivoWeb = null;
          nombreArchivoWeb = null;
          appLog('DEBUG SELECCIONAR: [Móvil] Archivo seleccionado, llamando setState. path: $filePath'); // ⭐️ DEBUG
        });
      }

      // 2. Llamar inmediatamente a la función de subida (con la ruta)
      _enviarArchivos(alumno, campoArchivo, filePath);
    }

    // --- LÓGICA WEB ---
  } else {
    final bytes = archivoSeleccionado.bytes;
    final nombre = archivoSeleccionado.name;

    if (bytes != null) {
      // 1. Guardar los bytes y el nombre en variables de estado
      if (mounted) {
        setState(() {
          bytesArchivoWeb = bytes;
          nombreArchivoWeb = nombre;
          // Usar el nombre como referencia temporal en el mapa
          _selectedFilePaths[key] = nombre;
          appLog('DEBUG SELECCIONAR: [Web] Archivo seleccionado, llamando setState. Nombre: $nombre'); // ⭐️ DEBUG
        });
      }

      // 2. Llamar inmediatamente a la función de subida (con el nombre como referencia de path)
      _enviarArchivos(alumno, campoArchivo, nombre);
    } else {
      appLog('DEBUG SELECCIONAR: [Web] Error, bytes o nombre nulos.'); // ⭐️ DEBUG
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Datos del archivo Web no disponibles después de la selección.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  // 🔑 MODIFICACIÓN: La firma del método _enviarArchivos permanece igual, 
  // pero la lógica interna usa las variables globales (bytesArchivoWeb, nombreArchivoWeb) para la Web.

  void _enviarArchivos(
    AlumnoSalonModel alumno, 
    String campoArchivo, 
    String localPath
  ) async { 
      // ⚠️ ATENCIÓN: Se asume que bytesArchivoWeb y nombreArchivoWeb son variables de clase (estado)
      // llenadas por _seleccionarArchivo.

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final key = '${alumno.idCicloAlumno}_$campoArchivo';
      
      // 1. Crear el modelo de datos para la subida
      final DatosArchivoASubir archivoParaSubir;

      if (!kIsWeb) {
        // 💻 MÓVIL/DESKTOP: Usa localPath (y tu verificación de existencia)
        if (!await File(localPath).exists()) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Archivo local no encontrado.'), backgroundColor: Colors.red),
            );
            return;
        }
        archivoParaSubir = DatosArchivoASubir(
          nombreCampoApi: campoArchivo,
          rutaLocal: localPath,
        );
        appLog('DEBUG ENVIAR: [Móvil] Preparando subida. Ruta local: $localPath'); // ⭐️ DEBUG
      } else {
        // 🌐 WEB: Usa bytes y nombre
        // 🛠️ CORRECCIÓN WEB: Aquí se lee la data que _seleccionarArchivo acaba de guardar.
        if (bytesArchivoWeb == null || nombreArchivoWeb == null) {
            appLog('DEBUG ENVIAR: [Web] Fallo, bytes/nombre son nulos en _enviarArchivos.'); // ⭐️ DEBUG
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error Web: Archivo no cargado en memoria (bytes/nombre).'), backgroundColor: Colors.red),
            );
            return;
        }
        archivoParaSubir = DatosArchivoASubir(
          nombreCampoApi: campoArchivo,
          bytesArchivo: bytesArchivoWeb,
          nombreArchivo: nombreArchivoWeb,
        );
        appLog('DEBUG ENVIAR: [Web] Preparando subida. Nombre archivo: $nombreArchivoWeb, Bytes length: ${bytesArchivoWeb!.length}'); // ⭐️ DEBUG
      }
      
      // Crear la lista para la llamada al Provider
      final List<DatosArchivoASubir> archivosParaEnviar = [archivoParaSubir];
      
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subiendo ${_getFileNameFromPath(localPath)}...'), duration: const Duration(seconds: 20)),
      );

      try {
          // 🔑 CAMBIO DE ESTRUCTURA: Llamada al Provider con la nueva estructura
          appLog('DEBUG ENVIAR: Llamando a userProvider.uploadCalificacionesArchivos...'); // ⭐️ DEBUG
          final result = await userProvider.uploadCalificacionesArchivos(
              idAlumno: alumno.idAlumno,
              idSalon: alumno.idSalon, 
              archivosParaSubir: archivosParaEnviar, 
          );
          
          // Imprime el resultado completo de la API para depuración
          print('✅ Respuesta de la API para campo $campoArchivo: $result');
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
          
          // El status de éxito es ahora 'correcto', no 'success' (según tu log)
          final bool isSuccess = (result['status'] == 'correcto') || 
                                (result['message'] == 'Información enviada correctamente!!');
          
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(result['message'] as String),
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
              ),
          );
          
          if (isSuccess) {
              
              final String newUrlOrName;
              
              // Usamos 'nombre_archivo' si está disponible
              if (result.containsKey('nombre_archivo') && result['nombre_archivo'] is String) {
                newUrlOrName = result['nombre_archivo'] as String; 
              } else {
                // Fallback si la clave 'nombre_archivo' no se encuentra
                newUrlOrName = _getFileNameFromPath(localPath); 
              }
              
              // ❌ CÓDIGO ANTERIOR ELIMINADO: alumno.archivosCalificacion[campoArchivo] = newUrlOrName;
              
              // 🔑 CORRECCIÓN INMUTABILIDAD: Usar copyWith
              // 1. Copiar y modificar el mapa
              final Map<String, String> updatedArchivos = 
                  Map.from(alumno.archivosCalificacion);
              updatedArchivos[campoArchivo] = newUrlOrName;
              
              // 2. Crear una nueva instancia del modelo
              final AlumnoSalonModel updatedAlumno = alumno.copyWith(
                  archivosCalificacion: updatedArchivos,
              );

              // 3. Buscar y reemplazar el modelo en la lista de la vista
              final int index = _alumnosDelSalon.indexOf(alumno);
              if (index != -1) {
                  _alumnosDelSalon[index] = updatedAlumno;
              }

              setState(() {
                  appLog('DEBUG ENVIAR: Llamando a setState después de subida exitosa. Esto gatilla el build.'); // ⭐️ DEBUG
                  _selectedFilePaths.remove(key);
                  // Opcional: Limpiar los bytes y nombre después de la subida exitosa
                  bytesArchivoWeb = null;
                  nombreArchivoWeb = null;
              });
          }

      } catch (e) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
          print('❌ Error inesperado en _enviarArchivos: $e');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error inesperado al subir: $e'), backgroundColor: Colors.red),
          );
      }
  }

  // ⭐️ MÉTODO MODIFICADO: Quitar Archivo (Añadida llamada a la API de eliminación) ⭐️
  void _quitarArchivo(String idCicloAlumno, String campoArchivo) async {
    if (!mounted) return;
    appLog('DEBUG ELIMINAR: Iniciando eliminación para alumno: $idCicloAlumno, campo: $campoArchivo'); // ⭐️ DEBUG

    final alumno = _alumnosDelSalon.firstWhere(
      (a) => a.idCicloAlumno == idCicloAlumno,
      orElse: () => _alumnosDelSalon.first,
    );
    
    // El nombre del archivo que se va a eliminar es el que está guardado
    final String archivoAEliminar = alumno.archivosCalificacion[campoArchivo] ?? '';
    
    if (archivoAEliminar.isEmpty) {
        // Si no hay URL/Nombre, solo se limpia localmente si es necesario (ya debería estar limpio)
        if (mounted) {
            setState(() {
              alumno.archivosCalificacion[campoArchivo] = '';
              _alumnosDelSalon = List.from(_alumnosDelSalon);
            });
        }
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No hay archivo para eliminar.'), 
                backgroundColor: Colors.blueGrey,
                duration: Duration(seconds: 2),
            ),
        );
        return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Eliminando archivo: ${_getFileNameFromPath(archivoAEliminar)}...'), 
            duration: const Duration(seconds: 20),
        ),
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
        // 1. Llamada a la API de Eliminación
        final result = await userProvider.deleteCalificacionesArchivo(
            idAlumno: alumno.idAlumno,
            idSalon: alumno.idSalon, 
            campoAActualizar: campoArchivo,
            archivoAEliminar: archivoAEliminar,
            // 'escuela' y 'id_empresa' deben ser manejados dentro del UserProvider
        );
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); 

        // 2. Verificar éxito de la API
        final bool isSuccess = (result['status'] == 'success') || 
                               (result['status'] == 'correcto') || // Soporte para tu status
                               (result['message'] != null); // Asumiendo que cualquier respuesta con mensaje es éxito

        if (isSuccess && mounted) {
            // 3. Limpiar el estado local si la eliminación en el servidor fue exitosa
            alumno.archivosCalificacion[campoArchivo] = '';
            
            setState(() {
              appLog('DEBUG ELIMINAR: Llamando a setState después de eliminación exitosa. Esto gatilla el build.'); // ⭐️ DEBUG
              _alumnosDelSalon = List.from(_alumnosDelSalon);
            });

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(result['message'] ?? 'Archivo eliminado correctamente.'), 
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                ),
            );
        } else if (mounted) {
            // Error reportado por la API
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(result['message'] ?? 'Error al eliminar el archivo.'), 
                    backgroundColor: Colors.red,
                ),
            );
        }

    } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
        print('❌ Error al llamar a delete_file_calificacion: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error de conexión o inesperado al eliminar: $e'), 
                backgroundColor: Colors.red,
            ),
        );
    }
  }

  // ⭐️ MÉTODO MODIFICADO: Ahora acepta campoArchivo como segundo argumento ⭐️
  void _visualizarPDF(String url, String campoArchivo) async { 
    final String urlBaseServidor = ApiConstants.assetsBaseUrl;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    appLog('DEBUG VISUALIZAR: Intentando visualizar URL: $url'); // ⭐️ DEBUG
    
    if (url.isEmpty || urlBaseServidor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se puede obtener la ruta del archivo o la URL base del servidor.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
    }
    
    // Lógica para construir la URL completa
    final String baseLimpia = urlBaseServidor.endsWith('/') 
                              ? urlBaseServidor.substring(0, urlBaseServidor.length - 1) 
                              : urlBaseServidor;
    
    final String rutaLimpia = url.startsWith('/') ? url.substring(1) : url;

    final String urlCompleta = '$baseLimpia/$rutaLimpia'; 
    
    appLog('DEBUG VISUALIZAR: URL completa construida: $urlCompleta'); // ⭐️ DEBUG
    
    if (!urlCompleta.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al construir la URL. Resultado: $urlCompleta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
    }

    // 🛑 NUEVA LÓGICA: Navegar a la pantalla interna del visor de PDF
    if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PdfViewerScreen(
                    // 🛑 CAMBIO CLAVE: Usamos el nombre formateado (Ej: "Archivo 1")
                    title: _formatCampoArchivo(campoArchivo), 
                    url: urlCompleta, // URL completa del PDF a cargar
                    colores: userProvider.colores,
                ),
            ),
        );
    }
  }
  
  // ⭐️ NUEVO MÉTODO: Mostrar el Modal de Acciones ⭐️
  void _mostrarModalAcciones(AlumnoSalonModel alumno, String campoArchivo) {
    
    final String currentUrlOrName = alumno.archivosCalificacion[campoArchivo] ?? '';
    final bool isUploaded = currentUrlOrName.isNotEmpty;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    appLog('DEBUG MODAL: Mostrando modal de acciones para campo: $campoArchivo. isUploaded: $isUploaded'); // ⭐️ DEBUG
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AccionesArchivoModal(
          alumno: alumno,
          campoArchivo: campoArchivo,
          isUploaded: isUploaded,
          currentUrlOrName: currentUrlOrName,
          colores: userProvider.colores,
          
          // Callbacks que reusan la lógica existente
          onSeleccionarArchivo: () {
            Navigator.of(context).pop();
            _seleccionarArchivo(alumno, campoArchivo);
          },
          onVisualizar: () {
            Navigator.of(context).pop();
            _visualizarPDF(currentUrlOrName, campoArchivo);
          },
          onEliminar: () {
            Navigator.of(context).pop();
            _quitarArchivo(alumno.idCicloAlumno, campoArchivo);
          },
        );
      },
    );
  }


 @override
  Widget build(BuildContext context) {
    appLog('DEBUG BUILD: Inicia la reconstrucción (build) de ArchivosCalificacionesScreen.'); // ⭐️ DEBUG
    final userProvider = Provider.of<UserProvider>(context);
    
    // ⚠️ PUNTO CRÍTICO DE LECTURA DE COLORES ⚠️
    final Color headerColor = userProvider.colores.headerColor;
    
    final AlumnoSalonModel? firstAlumno = _alumnosDelSalon.isNotEmpty ? _alumnosDelSalon.first : null;
    final List<String> camposArchivo = firstAlumno?.archivosCalificacion.keys.toList() ?? [];

    // 🚀 CAMBIO: Envolvemos el Scaffold en un SafeArea
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.salonSeleccionado,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          foregroundColor: Colors.white,
          backgroundColor: headerColor,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alumnosDelSalon.isEmpty
                ? Center(
                    child: Text(
                      'No hay alumnos asignados a este salón para subir archivos de calificación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  )
                : _buildAlumnoList(userProvider, camposArchivo),
      ),
    );
  }

  // ⭐️ NUEVO MÉTODO: Formatea el nombre del campo ⭐️
  String _formatCampoArchivo(String campo) {
    // Ejemplo: convierte "archivo_calif_1" en "Archivo 1"
    // Esto es lo que se mostrará en la UI.
    return campo.replaceAll('archivo_calif_', 'Archivo ').replaceAll('_', ' ').trim();
  }
  
  // ✅ WIDGET MODIFICADO: Lógica para mostrar Subir Directo o Acciones (Compacto)
  Widget _buildAlumnoList(UserProvider userProvider, List<String> camposArchivo) {
    
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _alumnosDelSalon.length,
      itemBuilder: (context, index) {
        final alumno = _alumnosDelSalon[index];
        final int alumnoNumero = index + 1;
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alumnoNumero}. ${alumno.nombreCompleto} (${alumno.salon})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    // ⚠️ PUNTO CRÍTICO DE LECTURA DE COLORES ⚠️
                    color: userProvider.colores.headerColor, 
                  ),
                ),
                const Divider(),
                
                // ⭐️ Campos de Archivo Dinámicos ⭐️
                ...camposArchivo.map((campo) {
                  final String currentUrlOrName = alumno.archivosCalificacion[campo] ?? ''; 
                  final bool isUploaded = currentUrlOrName.isNotEmpty;
                  
                  // 🛑 OBTENEMOS EL NOMBRE DE DISPLAY (Ej: "Archivo 1") 🛑
                  final String campoDisplay = _formatCampoArchivo(campo);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        if (isUploaded) ...[
                            // Si ya está subido, muestra el estado y el botón de acciones
                            Expanded(
                              flex: 2, // Ocupa 3/5 partes del espacio para la etiqueta de cargado
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        // 🛑 CAMBIO CLAVE: Muestra el nombre formateado (Ej: "Archivo 1") 🛑
                                        campoDisplay,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 8),

                            // Botón de ACCIONES
                            Expanded(
                              flex: 2, // Ocupa 2/5 partes del espacio para el botón de acciones
                              child: ElevatedButton(
                                onPressed: () => _mostrarModalAcciones(alumno, campo),
                                child: const Text('Acciones', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                    // ⚠️ PUNTO CRÍTICO DE LECTURA DE COLORES ⚠️
                                    backgroundColor: userProvider.colores.botonesColor, 
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                    elevation: 2,
                                ),
                              ),
                            ),
                        ] else // Si NO está subido, muestra el botón de subir que ocupa todo el espacio
                        
                        Expanded(
                          flex: 1, // Toma todo el espacio disponible
                          child: ElevatedButton.icon(
                            onPressed: () => _seleccionarArchivo(alumno, campo),
                            icon: const Icon(Icons.cloud_upload, color: Colors.white),
                            // Muestra "Subir Archivo X"
                            label: Text('Subir $campoDisplay', style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              // ⚠️ PUNTO CRÍTICO DE LECTURA DE COLORES ⚠️
                              backgroundColor: userProvider.colores.botonesColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ====================================================================
// ⭐️ WIDGET DE MODAL ⭐️
// ====================================================================

class _AccionesArchivoModal extends StatelessWidget {
  
  final AlumnoSalonModel alumno;
  final String campoArchivo;
  final bool isUploaded;
  final String currentUrlOrName;
  final dynamic colores; 
  
  final VoidCallback onSeleccionarArchivo;
  final VoidCallback onVisualizar;
  final VoidCallback onEliminar;

  const _AccionesArchivoModal({
    required this.alumno,
    required this.campoArchivo,
    required this.isUploaded,
    required this.currentUrlOrName,
    required this.colores,
    required this.onSeleccionarArchivo,
    required this.onVisualizar,
    required this.onEliminar,
  });
  
  /*String _getFileNameForDisplay() {
    final lastSeparator = currentUrlOrName.lastIndexOf('/');
    if (lastSeparator == -1) return currentUrlOrName;
    return currentUrlOrName.substring(lastSeparator + 1);
  }*/

  @override
  Widget build(BuildContext context) {
    
    final String campoDisplay = campoArchivo.replaceAll('_', ' ').toUpperCase();
    
    // ⚠️ PUNTO CRÍTICO DE LECTURA DE COLORES ⚠️
    appLog('DEBUG MODAL BUILD: El modal se está construyendo/reconstruyendo.'); // ⭐️ DEBUG
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: colores.headerColor, // ⚠️ Lectura de color
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Text(
              'Acciones: $campoDisplay', 
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SELECCIONAR / REEMPLAZAR ARCHIVO
                ElevatedButton.icon(
                  onPressed: onSeleccionarArchivo,
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: Text(
                    isUploaded ? 'Reemplazar archivo' : 'Seleccionar archivo', 
                    style: const TextStyle(color: Colors.white)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colores.botonesColor, // ⚠️ Lectura de color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. VISUALIZAR PDF (Solo si ya está subido)
                if (isUploaded) ...[
                  ElevatedButton.icon(
                    onPressed: onVisualizar,
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: Text(
                      'Visualizar PDF', 
                      style: const TextStyle(color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colores.botonesColor, // ⚠️ Lectura de color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 3. ELIMINAR ARCHIVO (Solo si ya está subido)
                if (isUploaded)
                  ElevatedButton.icon(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete, color: Colors.white),                  
                    label: const Text('Eliminar archivo', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colores.botonesColor, // ⚠️ Lectura de color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
              ],
            ),
          ),
          
          // 4. Botón Cerrar
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 10.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colores.botonesColor, // ⚠️ Lectura de color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
// archivos_calificaciones_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'dart:async'; // Ya no es necesario
// import 'dart:io';   // Ya no es necesario

// ⭐️ IMPORTACIÓN REAL DE FILE_PICKER ⭐️
import 'package:file_picker/file_picker.dart'; 

import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
// import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart'; // Ya no es necesario
// import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; // Ya no es necesario
import 'package:oficinaescolar_colaboradores/models/alumno_salon_model.dart'; 
// Eliminada la referencia a MateriaModel si es que estaba importada

class ArchivosCalificacionesScreen extends StatefulWidget {
  
  // ⭐️ MODIFICACIÓN: ELIMINADA MateriaModel, ahora requiere Salón y Alumnos ⭐️
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
  
  // Lista que contendrá solo los alumnos que pertenecen al salón seleccionado
  List<AlumnoSalonModel> _alumnosDelSalon = [];
  
  // Mapa para rastrear los archivos PDF seleccionados localmente antes de subir
  final Map<String, String?> _selectedFilePaths = {};
  
  bool _isLoading = true;
  
  // String? _errorMessage; 

  @override
  void initState() {
    super.initState();
    // ⭐️ LÓGICA SIMPLIFICADA: Usar los alumnos que ya vienen ⭐️
    _cargarAlumnosDelSalon();
  }

  /// Asigna y ordena los alumnos proporcionados por la vista anterior.
  void _cargarAlumnosDelSalon() {
    
    // Usamos la lista de alumnos pasada en el constructor
    List<AlumnoSalonModel> alumnos = widget.alumnosSalon;
    
    // Ordenar por nombre
    alumnos.sort((a, b) => a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase()));

    if (mounted) {
      setState(() {
        _alumnosDelSalon = alumnos;
        _isLoading = false;
      });
    }
    // ⚠️ ELIMINADO: Método _filtrarAlumnosPorMateria ya no existe
  }
  
  // ⭐️ MODIFICACIÓN CLAVE: Implementación real de la selección de archivos ⭐️
  /// Abre el selector de archivos (PDF) y almacena la ruta local.
  void _seleccionarArchivo(String idCicloAlumno, String campoArchivo) async {
    final key = '${idCicloAlumno}_$campoArchivo';

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Solo permitir archivos PDF
        allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        
        if (mounted) {
            setState(() {
                _selectedFilePaths[key] = filePath;
            });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Archivo seleccionado: ${result.files.single.name}'), 
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
            ),
        );
    } else {
        // El usuario canceló la selección o la ruta es nula
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Selección de archivo cancelada.'), 
                backgroundColor: Colors.grey,
                duration: Duration(seconds: 2),
            ),
        );
    }
  }

  // ⭐️ MÉTODO AÑADIDO: Quitar el archivo seleccionado localmente ⭐️
  /// Quita la ruta local seleccionada para un campo específico, permitiendo al usuario volver a seleccionar.
  void _quitarArchivo(String idCicloAlumno, String campoArchivo) {
      final key = '${idCicloAlumno}_$campoArchivo';
      if (mounted) {
          setState(() {
              _selectedFilePaths.remove(key);
          });
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Archivo local eliminado. Seleccione uno nuevo.'),
              backgroundColor: Colors.blueGrey,
              duration: Duration(seconds: 2),
          ),
      );
  }

  // ⭐️ NUEVA FUNCIÓN: Extrae el nombre del archivo de la ruta completa ⭐️
  /// Extrae el nombre del archivo del path completo.
  String _getFileNameFromPath(String? path) {
      if (path == null || path.isEmpty) return 'Archivo';
      final lastSeparator = path.lastIndexOf('/');
      if (lastSeparator == -1) return path; // Si no hay '/', devuelve el path completo
      return path.substring(lastSeparator + 1);
  }
  
  /// Llama al provider para subir los archivos seleccionados de un alumno específico.
  void _enviarArchivos(AlumnoSalonModel alumno) async { 
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 1. Recopilar solo los archivos que tienen una ruta local seleccionada
      final Map<String, String?> filesToSend = {};
      final String alumnoIdCiclo = alumno.idCicloAlumno;
      
      for (final campo in alumno.archivosCalificacion.keys) {
          final key = '${alumnoIdCiclo}_$campo';
          if (_selectedFilePaths.containsKey(key)) {
              // Copiamos la ruta local seleccionada (el valor es String?)
              filesToSend[campo] = _selectedFilePaths[key]; 
          }
      }
      
      if (filesToSend.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay archivos seleccionados para subir.'), backgroundColor: Colors.orange),
          );
          return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo archivos, por favor espere...'), duration: Duration(seconds: 10)),
      );

      try {
          // 2. Llamada al provider para el Multipart upload
          final result = await userProvider.uploadCalificacionesArchivos(
              idAlumno: alumno.idAlumno,
              // ⚠️ Importante: Usamos el campo 'salon' como idSalon para la API
              idSalon: alumno.idSalon, 
              selectedFilePaths: filesToSend,
          );
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(result['message'] as String),
                  backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
              ),
          );
          
          // 3. Manejo de éxito
          if (result['status'] == 'success') {
              // Limpiar las rutas locales que se subieron con éxito
              setState(() {
                  filesToSend.keys.forEach((campo) {
                      _selectedFilePaths.remove('${alumnoIdCiclo}_$campo');
                  });
              });
              
              // ⚠️ Recargar datos del colaborador para que el ColaboradorModel se actualice con las nuevas URLs
              await userProvider.fetchAndLoadColaboradorData(forceRefresh: true);
          }

      } catch (e) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error inesperado al subir: $e'), backgroundColor: Colors.red),
          );
      }
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color headerColor = userProvider.colores.headerColor;
    
    // Obtener los nombres de los campos de archivo (ej: 'archivo_calif_1')
    final AlumnoSalonModel? firstAlumno = _alumnosDelSalon.isNotEmpty ? _alumnosDelSalon.first : null;
    final List<String> camposArchivo = firstAlumno?.archivosCalificacion.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          // ⭐️ TÍTULO MODIFICADO: Muestra el nombre del salón ⭐️
          widget.salonSeleccionado,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: headerColor,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alumnosDelSalon.isEmpty
              ? Center(
                  child: Text(
                    // ⭐️ MENSAJE MODIFICADO ⭐️
                    'No hay alumnos asignados a este salón para subir archivos de calificación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                )
              : _buildAlumnoList(userProvider, camposArchivo),
    );
  }
  
  // ✅ WIDGET: Construir la lista de alumnos con los campos dinámicos y la opción de subir
  Widget _buildAlumnoList(UserProvider userProvider, List<String> camposArchivo) {
    
    // ⚠️ Usamos _alumnosDelSalon en lugar de _alumnosFiltrados
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
                // Nombre y Salón del Alumno
                Text(
                  '${alumnoNumero}. ${alumno.nombreCompleto} (${alumno.salon})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: userProvider.colores.headerColor,
                  ),
                ),
                const Divider(),
                
                // ⭐️ Campos de Archivo Dinámicos ⭐️
                ...camposArchivo.map((campo) {
                  final String key = '${alumno.idCicloAlumno}_$campo';
                  final String? localPath = _selectedFilePaths[key];
                  // Obtener el estado actual (si existe una URL)
                  final String currentUrl = alumno.archivosCalificacion[campo] ?? ''; 
                  
                  // ⭐️ NUEVA LÓGICA PARA EL ESTADO DEL BOTÓN ⭐️
                  final bool isLocallySelected = localPath != null;
                  final bool isAlreadyUploaded = currentUrl.isNotEmpty && !isLocallySelected;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // Título del Campo (ej: Archivo Calif 1)
                        Expanded(
                          flex: 3,
                          child: Text(
                            campo.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Botón de Acción (Seleccionar/Ver/Reemplazar)
                        Expanded(
                          // ⭐️ AJUSTE DE FLEX ⭐️
                          flex: isLocallySelected ? 3 : 4,
                          child: ElevatedButton.icon(
                            onPressed: () => _seleccionarArchivo(alumno.idCicloAlumno, campo),
                            icon: isLocallySelected 
                                  ? const Icon(Icons.file_copy) // Icono verde para archivo cargado
                                  : isAlreadyUploaded
                                    ? const Icon(Icons.refresh) // Sugerir reemplazar
                                    : const Icon(Icons.attach_file),
                            label: Text(
                              // ⭐️ TEXTO MODIFICADO: Muestra el nombre real del archivo ⭐️
                              isLocallySelected 
                                ? _getFileNameFromPath(localPath) // <-- ¡CAMBIO AQUÍ!
                                : isAlreadyUploaded ? 'Ver/Cambiar' : 'Seleccionar PDF',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                                // ⭐️ COLOR MODIFICADO (Verde si está cargado localmente) ⭐️
                                backgroundColor: isLocallySelected 
                                    ? Colors.green 
                                    : userProvider.colores.botonesColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        
                        // ⭐️ Botón para QUITAR (Solo si localPath != null) ⭐️
                        if (isLocallySelected) 
                          SizedBox(
                            width: 40, 
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Quitar archivo seleccionado localmente',
                              onPressed: () => _quitarArchivo(alumno.idCicloAlumno, campo),
                            ),
                          ) 
                        else 
                          const SizedBox(width: 40), // Espacio para mantener la alineación
                        
                        // ⭐️ Icono de Estado MODIFICADO: Se elimina el warning amarillo ⭐️
                        /*SizedBox(
                          width: 40,
                          child: (currentUrl.isNotEmpty)
                              ? const Icon(Icons.cloud_done, color: Colors.green) // Ya subido
                              : const Icon(Icons.cloud_off, color: Colors.red), // Faltante (sin archivo subido, ni pendiente con warning)
                        ),*/
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 10),

                // Botón principal de SUBIDA por alumno
                Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                        onPressed: () => _enviarArchivos(alumno), // Llama al método con el alumno
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Subir Archivos de Alumno'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: userProvider.colores.headerColor,
                            foregroundColor: Colors.white,
                        ),
                    ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
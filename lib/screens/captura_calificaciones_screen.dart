import 'package:flutter/material.dart';
//import 'package:oficinaescolar_colaboradores/widgets/posgrado_table_wiget.dart';
import 'package:oficinaescolar_colaboradores/widgets/preescolar_table_widget.dart';
import 'package:oficinaescolar_colaboradores/widgets/preparatoria_table_widget.dart';
import 'package:oficinaescolar_colaboradores/widgets/primaria_table_widget.dart';
import 'package:oficinaescolar_colaboradores/widgets/secundaria_table_widget.dart';
import 'package:oficinaescolar_colaboradores/widgets/universidad_table_widget.dart';
import 'package:provider/provider.dart';

// Importa tus modelos y el provider
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart'; 
import 'package:oficinaescolar_colaboradores/utils/log_util.dart';



class CapturaCalificacionesScreen extends StatefulWidget {
  final MateriaModel materiaSeleccionada;


  const CapturaCalificacionesScreen({
    super.key,
    required this.materiaSeleccionada,

  });

  @override
  State<CapturaCalificacionesScreen> createState() => _CapturaCalificacionesScreenState();
}

class _CapturaCalificacionesScreenState extends State<CapturaCalificacionesScreen> {
  
  // Lista de alumnos con sus calificaciones (JSON crudo de la API - Estado mutable)
  List<Map<String, dynamic>> _alumnos = [];
  
  // Estructura de boleta obtenida del Provider local
  BoletaEncabezadoModel? _estructuraBoleta;
  
  // Claves que NO deben tener un TextFormField (ej: promedio_1, CF)
  List<String> _readonlyKeys = []; 
  
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LÓGICA DE CARGA DE DATOS ---

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final provider = Provider.of<UserProvider>(context, listen: false);
    final materia = widget.materiaSeleccionada;
    
    try {
      // 1. OBTENER LA ESTRUCTURA DE LA BOLETA
      final estructura = provider.boletaEncabezados.firstWhere(
        (e) => e.nivelEducativo == materia.nivelEducativo,
        orElse: () => throw Exception('No se encontró la estructura de boleta para el Plan: ${materia.planEstudio}'),
      );
      
      // 2. OBTENER LA LISTA DE ALUMNOS
      final alumnosData = await provider.fetchAlumnosParaCalificar(
        idCurso: materia.idMateriaClase, 
        tipoCurso: TipoCurso.materia, 
      );
      
      // 3. IDENTIFICAR CAMPOS DE SOLO LECTURA
      _identifyReadonlyKeys(estructura);

      // 4. ACTUALIZAR EL ESTADO
      setState(() {
        _estructuraBoleta = estructura;
        _alumnos = alumnosData;
        _isLoading = false;
      });

    } catch (e) {
      appLog('Error en la carga de calificaciones: $e');
      setState(() {
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // --- LÓGICA DE NEGOCIO ---

  // Identifica las claves que son promedios o calculadas (Promedio, CF, etc.)
    void _identifyReadonlyKeys(BoletaEncabezadoModel estructura) {
        Set<String> keys = {};
        
        estructura.relaciones.values.forEach((relationString) {
          relationString.split(',').forEach((key) {
            final lowerKey = key.trim().toLowerCase();
            
            // La condición principal de solo lectura (promedio, CF)
            if (lowerKey.contains('promedio') || lowerKey == 'Evaluación Final') { 
              keys.add(key.trim());
            }
            
            // 🚨 CAMBIO CLAVE AQUÍ
            // Si la clave anterior 'calificacion_final' sigue siendo un riesgo de ser read-only, 
            // mantenemos la exclusión o la eliminamos si ya no es relevante.
            
            if (lowerKey.contains('final') && lowerKey != 'calificacion_final') {
                keys.add(key.trim());
            }

          });
        });

        // Esta parte maneja comentarios o encabezados especiales (no afecta a 'calificacion'/'observaciones')
        estructura.comentarios.entries.forEach((entry) {
            final commentValue = entry.value.toLowerCase();
            if (commentValue.contains('promedio') || commentValue.contains('final')) {
                keys.add(entry.key);
            }
        });

        _readonlyKeys = keys.toList();
        // Revisa la consola: deberías ver una lista vacía o solo las claves que son *realmente* promedios.
        appLog('Claves de Solo Lectura: $_readonlyKeys'); 
    }
  // ✅ MÉTODO ACTUALIZADO: Permite la edición de celdas que ya tienen valor,
  // excepto aquellas marcadas como solo lectura (_readonlyKeys).
  DataCell _buildGradeCell(String alumnoId, String key) {
    // 1. Obtener el valor actual
    final alumnoIndex = _alumnos.indexWhere((a) => a['id_alumno'] == alumnoId);
    if (alumnoIndex == -1) {
      return const DataCell(Text('Error', style: TextStyle(color: Colors.red)));
    }
    
    // Obtiene el valor actual del estado local (_alumnos)
    final currentValue = _alumnos[alumnoIndex][key]?.toString().trim() ?? '';
    
    // 2. SEGURIDAD: Si es una clave de solo lectura (ej: promedio o calificación final calculada)
    if (_readonlyKeys.contains(key)) {
      // Muestra el valor si existe, si no, un guion.
      return DataCell(Text(
        currentValue.isNotEmpty ? currentValue : '-', 
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ));
    }
     
    // 3. Devolver la celda editable (TextFormField) - Permite la edición del valor actual
    return DataCell(
      TextFormField(
        initialValue: currentValue, // Muestra el valor existente de la API o la edición local
        textAlign: TextAlign.center,
        keyboardType: key.toLowerCase().contains('observa') 
            ? TextInputType.text 
            : TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (newValue) { 
          // 🚨 LÓGICA VITAL DE ACTUALIZACIÓN DEL ESTADO LOCAL
          // Actualizamos directamente la lista mutable:
          _alumnos[alumnoIndex][key] = newValue;
        }
      ),
    );
  }

  // --- LÓGICA DE RENDERIZADO DE WIDGETS (Sin cambios) ---

  Widget _buildContentWidget() {
    final estructura = _estructuraBoleta!;
    final nivel = estructura.nivelEducativo;

    // Utilizamos un switch para seleccionar el widget de tabla basado en el nivel
    switch (nivel) {
      case 'Preescolar':
    final relaciones = estructura.relaciones; 
    
    final List<String> obsKeys = relaciones.values
        .expand((r) => r.split(',')) 
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
        
    // Incluir comentarios finales de forma segura (si son opcionales en el modelo)
    if (estructura.comentarios.isNotEmpty) {
        obsKeys.addAll(estructura.comentarios.keys.toList());
    }

    if (obsKeys.isEmpty) {
        return const Center(
            child: Text(
                'Advertencia: No se encontraron campos de observación definidos para Preescolar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange, fontSize: 16),
            ),
        );
    }
    
    return PreescolarCalificacionesWidget(
        alumnos: _alumnos,
        estructura: estructura,
        buildGradeCell: _buildGradeCell,
        observationKeys: obsKeys,
    );

      case 'Primaria':
        return PrimariaCalificacionesWidget(
          alumnos: _alumnos,
          estructura: estructura,
          buildGradeCell: _buildGradeCell,
          readonlyKeys: _readonlyKeys,
        );

      case 'Secundaria':
        return SecundariaCalificacionesWidget(
          alumnos: _alumnos,
          estructura: estructura,
          buildGradeCell: _buildGradeCell,
          readonlyKeys: _readonlyKeys,
        );

      case 'Bachillerato o su equivalente':
        return PreparatoriaCalificacionesWidget(
          alumnos: _alumnos,
          estructura: estructura,
          buildGradeCell: _buildGradeCell,
          readonlyKeys: _readonlyKeys,
        );
        
      case 'Licenciatura':
        return UniversidadCalificacionesWidget(
          alumnos: _alumnos,
          estructura: estructura,
          buildGradeCell: _buildGradeCell,
          readonlyKeys: _readonlyKeys,
        );

      case 'Programas de posgrado':
        return UniversidadCalificacionesWidget(
          alumnos: _alumnos,
          estructura: estructura,
          buildGradeCell: _buildGradeCell,
          readonlyKeys: _readonlyKeys,
        );

      default:
        return Center(
          child: Text('Nivel educativo no soportado: $nivel', style: const TextStyle(color: Colors.orange)),
        );
    }
  }
  
  // ✅ NUEVO MÉTODO: Muestra el modal de éxito y recarga los datos al cerrarse
  Future<void> _mostrarModalExito(String mensaje) async {
    // Usamos el showDialog estándar de Flutter
    await showDialog(
      context: context,
      barrierDismissible: false, // Fuerza al usuario a presionar "Aceptar"
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Guardado Exitoso', style: TextStyle(color: Colors.green)),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el modal
              },
            ),
          ],
        );
      },
    );
    
    // 🚨 CLAVE: Al cerrar el modal, recargamos la data.
    // Esto asegura que las celdas muestren los datos actualizados de la API.
    await _loadData(); 
  }


  // --- LÓGICA DE GUARDADO ---
  
  // ✅ MÉTODO ACTUALIZADO: Maneja el guardado y el flujo del modal
  void _sendCalificaciones() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    
    // 1. Verificar si la estructura de la boleta está cargada
    if (_estructuraBoleta == null) {
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
               content: Text('Error: La estructura de la boleta no se ha cargado. Inténtalo de nuevo.'),
               backgroundColor: Colors.orange,
           ),
       );
       return;
    }

    // La lista _alumnos ya tiene todos los datos actualizados, incluyendo 'id_alumno' y las calificaciones
    final List<Map<String, dynamic>> jsonToSend = _alumnos.map((a) => a).toList(); 

    // Mostrar indicador de carga (usamos una variable para poder cerrarlo)
    final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardando calificaciones...'),
          duration: Duration(minutes: 1), // Larga duración para cerrarla manualmente
        ),
    );
    
    try {
      // 2. LLAMADA A LA API
      final result = await provider.saveCalificaciones(
        idCurso: widget.materiaSeleccionada.idMateriaClase,
        calificacionesLista: jsonToSend,
        estructuraBoleta: _estructuraBoleta!, 
      );

      // Ocultar el SnackBar de carga
      loadingSnackbar.close();
      
      final String message = result['message'] as String;

      // ✅ MANEJO DEL MODAL/ERROR
      if (result['status'] == 'success') {
          // Si es exitoso, mostramos el modal que se encargará de recargar los datos
          await _mostrarModalExito(message); 
      } else {
          // Si hay un error, mostramos un SnackBar de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $message'),
              backgroundColor: Colors.red,
            ),
          );
      }
      
    } catch (e) {
      // Ocultar el SnackBar de carga y mostrar error de conexión/app
      loadingSnackbar.close(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión o aplicación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ ACCESO AL PROVEEDOR DE COLOR ⭐️
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;

    // 🚀 INICIO del SafeArea
    if (_isLoading) {
      // Aplicar formato de título al AppBar de carga
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Cargando ${widget.materiaSeleccionada.materia}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            foregroundColor: Colors.white,
            backgroundColor: dynamicHeaderColor, // ⭐️ Color Dinámico ⭐️
            centerTitle: true,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _estructuraBoleta == null) {
      // Aplicar formato de título al AppBar de error
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.materiaSeleccionada.materia,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            foregroundColor: Colors.white,
            backgroundColor: dynamicHeaderColor, // ⭐️ Color Dinámico ⭐️
            centerTitle: true,
          ),
          body: Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))),
        ),
      );
    }
    // 🚀 FIN del SafeArea

    // 🚀 Scaffold principal (Datos cargados) dentro de SafeArea
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          // ⭐️ APLICACIÓN DEL FORMATO DE TÍTULO CONSISTENTE ⭐️
          title: Text(
            widget.materiaSeleccionada.materia,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          foregroundColor: Colors.white,
          backgroundColor: dynamicHeaderColor, // ⭐️ Color Dinámico ⭐️
          centerTitle: true,
          // ❌ Eliminamos el botón de guardar de aquí
          // actions: [...],
        ),
        
        // El widget de contenido maneja su propio SingleChildScrollView horizontal
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.all(8.0),
          child: _buildContentWidget(),
        ),
        
        // ✅ AÑADIMOS EL BOTÓN DE GUARDAR FIJO EN LA PARTE INFERIOR DERECHA
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _sendCalificaciones,
          label: const Text(
            'Guardar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          //icon: const Icon(Icons.save),
          backgroundColor: colores.botonesColor, // Usar el color dinámico del Provider
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
        ),
        
        // Aseguramos que el botón flotante esté centrado a la derecha (por defecto)
        // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
      ),
    );
  }
}
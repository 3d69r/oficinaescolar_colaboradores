import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/widgets/posgrado_table_wiget.dart';
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
        (e) => e.nivelEducativo == materia.planEstudio,
        orElse: () => throw Exception('No se encontró la estructura de boleta para el Plan: ${materia.planEstudio}'),
      );
      
      // 2. OBTENER LA LISTA DE ALUMNOS
      final alumnosData = await provider.fetchAlumnosParaCalificar(
        idCurso: materia.idMateriaClase, 
        tipoCurso: TipoCurso.materia, 
      );
      
      // 3. IDENTIFICAR CAMPOS DE SOLO LECTURA (PROMEDIOS)
      _identifyReadonlyKeys(estructura);

      // 4. ACTUALIZAR EL ESTADO
      setState(() {
        _estructuraBoleta = estructura;
        _alumnos = alumnosData;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error en la carga de calificaciones: $e');
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
    
    // Busca en las relaciones cualquier clave que contenga 'promedio' o 'final'
    estructura.relaciones.values.forEach((relationString) {
      relationString.split(',').forEach((key) {
        final lowerKey = key.trim().toLowerCase();
        if (lowerKey.contains('promedio') || lowerKey.contains('final') || lowerKey == 'cf') {
          keys.add(key.trim());
        }
      });
    });

    // Añade la clave de 'comentarios' si el encabezado es 'PROMEDIO FINAL'
    estructura.comentarios.entries.forEach((entry) {
        final commentValue = entry.value.toLowerCase();
        if (commentValue.contains('promedio') || commentValue.contains('final')) {
             keys.add(entry.key);
        }
    });

    _readonlyKeys = keys.toList();
    debugPrint('Claves de Solo Lectura: $_readonlyKeys');
  }

  // Genera la celda editable/de texto (Callback pasado a los widgets modulares)
  DataCell _buildGradeCell(String alumnoId, String key) {
    // 1. Obtener el valor actual
    final alumnoIndex = _alumnos.indexWhere((a) => a['id_alumno'] == alumnoId);
    if (alumnoIndex == -1) {
      return const DataCell(Text('Error', style: TextStyle(color: Colors.red)));
    }
    
    // Obtiene el valor actual del estado local (_alumnos)
    // ✅ MODIFICACIÓN: Usamos .trim() para asegurar que no haya espacios vacíos.
    final currentValue = _alumnos[alumnoIndex][key]?.toString()?.trim() ?? '';
    
    // 2. SEGURIDAD: Si es una clave de solo lectura (ej: promedio), devuelve un guion.
    if (_readonlyKeys.contains(key)) {
      // Muestra el valor si existe, si no, un guion.
      return DataCell(Text(
        currentValue.isNotEmpty ? currentValue : '-', 
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ));
    }
    
    // ✅ MODIFICACIÓN: LÓGICA DE INMUTABILIDAD POST-GUARDADO
    // Si ya tiene un valor, lo mostramos como texto estático no editable.
    if (currentValue.isNotEmpty) {
      return DataCell(
        Text(
          currentValue,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.black54, // Color para indicar que ya está fijo
          ),
        ),
      );
    }
    
    // 4. Devolver la celda editable (TextFormField) - Solo si está vacía
    return DataCell(
      TextFormField(
        initialValue: currentValue,
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
        return PosgradoCalificacionesWidget(
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

  @override
  Widget build(BuildContext context) {
    // ⭐️ ACCESO AL PROVEEDOR DE COLOR ⭐️
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;

    if (_isLoading) {
      // Aplicar formato de título al AppBar de carga
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Cargando ${widget.materiaSeleccionada.materia}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: dynamicHeaderColor, // ⭐️ Color Dinámico ⭐️
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty || _estructuraBoleta == null) {
      // Aplicar formato de título al AppBar de error
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.materiaSeleccionada.materia,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: dynamicHeaderColor, // ⭐️ Color Dinámico ⭐️
          centerTitle: true,
        ),
        body: Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // ⭐️ APLICACIÓN DEL FORMATO DE TÍTULO CONSISTENTE ⭐️
        title: Text(
          widget.materiaSeleccionada.materia,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: dynamicHeaderColor, // ⭐️ Color Dinámico ⭐️
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // 🚨 LLAMAR AL MÉTODO DE ENVÍO
              _sendCalificaciones();
            },
            color: Colors.white, // Asegurar que el ícono sea blanco
          ),
        ],
      ),
      // El widget de contenido maneja su propio SingleChildScrollView horizontal
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(8.0),
        child: _buildContentWidget(),
      ),
    );
  }

  // --- LÓGICA DE GUARDADO ---
  
  // --- LÓGICA DE GUARDADO ---
  
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

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardando calificaciones...')),
    );
    
    try {
      // 2. LLAMADA A LA API: Ahora requiere estructuraBoleta
      final result = await provider.saveCalificaciones(
        idCurso: widget.materiaSeleccionada.idMateriaClase,
        calificacionesLista: jsonToSend,
        estructuraBoleta: _estructuraBoleta!, // <-- ¡PARAMETRO ESENCIAL AGREGADO!
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // La API devuelve 'correcto', pero nuestro Provider lo traduce a 'success'
          content: Text(result['message'] as String),
          backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );
      
      // ✅ Si se guarda con éxito, recargamos la data para actualizar el estado visual
      if (result['status'] == 'success') {
          // Si _loadData está en progreso, mostrará un indicador de carga.
          await _loadData(); 
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
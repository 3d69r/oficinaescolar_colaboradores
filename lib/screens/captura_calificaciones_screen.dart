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

// Importa los widgets modulares que creamos


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
    // ... (Mantener la lógica de carga, sólo añadir la identificación de readonlyKeys)
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

    // NOTA: Si necesitas que una clave específica (ej: 'evalua_observaciones') sea editable,
    // puedes ajustar la lógica aquí. Por ahora, asumimos que 'observaciones' es editable.
    
    _readonlyKeys = keys.toList();
    debugPrint('Claves de Solo Lectura: $_readonlyKeys');
  }

  // Genera la celda editable/de texto (Callback pasado a los widgets modulares)
  DataCell _buildGradeCell(String alumnoId, String key) {
    // 1. SEGURIDAD: Si es una clave de solo lectura, devuelve una celda vacía o de texto estático.
    // Aunque el widget modular ya maneja el renderizado de solo lectura, esto evita inyectar un campo de texto.
    if (_readonlyKeys.contains(key)) {
      return const DataCell(Text('-', textAlign: TextAlign.center));
    }
    
    // 2. Obtener el valor actual
    final alumnoIndex = _alumnos.indexWhere((a) => a['id_alumno'] == alumnoId);
    if (alumnoIndex == -1) {
      return const DataCell(Text('Error', style: TextStyle(color: Colors.red)));
    }
    
    final currentValue = _alumnos[alumnoIndex][key]?.toString() ?? '';
    
    // 3. Devolver la celda editable (TextFormField)
    return DataCell(
      TextFormField(
        initialValue: currentValue,
        textAlign: TextAlign.center,
        // Usamos el mismo patrón para el tipo de teclado
        keyboardType: key.toLowerCase().contains('observa') ? TextInputType.text : TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (newValue) { 
          // 🚨 LÓGICA VITAL DE ACTUALIZACIÓN DEL ESTADO LOCAL
          // NO usamos setState aquí para evitar el re-renderizado total por cada tecla.
          // Actualizamos directamente la lista mutable:
          _alumnos[alumnoIndex][key] = newValue;
          
          // Opcional: Ejecutar lógica de promedio en el backend o aquí si es simple.
          // Por simplicidad, asumimos que el cálculo del promedio ocurre en el backend
          // y se recarga al guardar, o se maneja en un provider para actualizaciones en tiempo real.
        }
      ),
    );
  }

  // --- LÓGICA DE RENDERIZADO DE WIDGETS ---

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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Cargando ${widget.materiaSeleccionada.materia}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty || _estructuraBoleta == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.materiaSeleccionada.materia)),
        body: Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Captura: ${widget.materiaSeleccionada.materia}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // 🚨 LLAMAR AL MÉTODO DE ENVÍO
              _sendCalificaciones();
            },
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

  // --- LÓGICA DE GUARDADO (Placeholder) ---
  
  void _sendCalificaciones() {
    // 1. Prepara el JSON a enviar (la lista _alumnos tiene todos los datos actualizados)
    final jsonToSend = _alumnos.map((a) => a).toList(); 

    debugPrint('Datos a enviar: $jsonToSend');
    
    // 2. Llama a la API/Provider para guardar
    // final provider = Provider.of<UserProvider>(context, listen: false);
    // await provider.saveCalificaciones(jsonToSend);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Datos listos para ser enviados a la API!'), duration: Duration(seconds: 2)),
    );
    
    // Opcional: Volver a cargar los datos después del guardado si el backend recalcula promedios.
    // _loadData(); 
  }
}
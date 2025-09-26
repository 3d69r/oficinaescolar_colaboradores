import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Asegúrate de importar tus modelos y el provider
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; // Tu provider
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart'; // El enum TipoCurso

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
  // Lista de alumnos con sus calificaciones (JSON crudo de la API)
  List<Map<String, dynamic>> _alumnos = [];
  
  // Estructura de boleta obtenida del Provider local
  BoletaEncabezadoModel? _estructuraBoleta;
  
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final provider = Provider.of<UserProvider>(context, listen: false);
    final materia = widget.materiaSeleccionada;
    
    try {
      // 1. OBTENER LA ESTRUCTURA DE LA BOLETA (Del Provider/DB local)
      final estructura = provider.boletaEncabezados.firstWhere(
        // Usamos planEstudio de la materia como filtro
        (e) => e.nivelEducativo == materia.planEstudio,
        orElse: () => throw Exception('No se encontró la estructura de boleta para el Plan: ${materia.planEstudio}'),
      );
      
      // 2. OBTENER LA LISTA DE ALUMNOS (De la API, usando el método recién creado)
      final alumnosData = await provider.fetchAlumnosParaCalificar(
        idCurso: materia.idMateriaClase, // Usamos idMateriaClase como el identificador del curso
        tipoCurso: TipoCurso.materia, 
      );

      // 3. ACTUALIZAR EL ESTADO
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

  // Genera las columnas dinámicas para la cabecera de la tabla
  List<DataColumn> _buildDataColumns(BoletaEncabezadoModel estructura) {
    List<DataColumn> columns = [
      // Columna fija para el nombre
      const DataColumn(label: Text('Alumno')),
      
      // Columnas dinámicas de calificación
      ...estructura.encabezados.entries.map((entry) {
        return DataColumn(
          label: RotatedBox(
            quarterTurns: 3, // Rotar texto para ahorrar espacio horizontal
            child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          tooltip: entry.value,
        );
      }).toList(),
      
      // Columna para Observaciones/Comentarios (si existe)
      if (estructura.comentarios.isNotEmpty) 
        const DataColumn(label: Text('Obs.')),
    ];
    return columns;
  }
  
  // Genera la celda editable para la calificación/comentario
  DataCell _buildGradeCell(String alumnoId, String key) {
    // ⚠️ Esta es la lógica para obtener la calificación actual del alumno
    final alumnoData = _alumnos.firstWhere(
      (a) => a['id_alumno'] == alumnoId,
      orElse: () => {},
    );
    
    final currentValue = alumnoData[key]?.toString() ?? '';
    
    return DataCell(
      TextFormField(
        initialValue: currentValue,
        textAlign: TextAlign.center,
        // Asumiendo que las claves P1, P2, etc. son numéricas, y las otras son texto.
        keyboardType: key.toUpperCase().startsWith('P') ? TextInputType.number : TextInputType.text,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (newValue) { 
          // 🚨 LÓGICA DE ACTUALIZACIÓN LOCAL (NECESARIA ANTES DEL ENVÍO A LA API)
          // Implementa aquí la actualización del valor en la lista _alumnos 
          // para que el botón de guardar envíe el JSON correcto.
        }
      ),
    );
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

    final estructura = _estructuraBoleta!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Captura: ${widget.materiaSeleccionada.materia}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // 🚨 ESTE BOTÓN LLAMARÁ AL FUTURO sendCalificaciones()
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API de Guardado no implementada aún.')),
              );
            },
          ),
        ],
      ),
      // Usamos SingleChildScrollView doble para permitir scroll vertical y horizontal (para la tabla)
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _buildDataColumns(estructura),
            rows: _alumnos.map((alumno) {
              final alumnoId = alumno['id_alumno'] as String;
              
              return DataRow(
                cells: [
                  // Celda de Nombre del Alumno
                  DataCell(Text(alumno['nombre_alumno'] as String? ?? 'N/A')), 
                  
                  // Celdas de Calificaciones Dinámicas
                  ...estructura.encabezados.keys.map((key) {
                    return _buildGradeCell(alumnoId, key);
                  }).toList(),
                  
                  // Celda de Comentarios/Observaciones (si aplica)
                  if (estructura.comentarios.isNotEmpty) 
                    _buildGradeCell(alumnoId, estructura.comentarios.keys.first), 
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
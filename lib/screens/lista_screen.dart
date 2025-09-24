import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ Asegúrate de tener estas importaciones correctas
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 
import 'package:oficinaescolar_colaboradores/models/alumno_asistencia_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart'; // Tu enum TipoCurso

// ✅ 1. Enum SIN RETARDO
enum AttendanceStatus { presente, ausente, pendiente }


class ListaScreen extends StatefulWidget {
  final String idCurso;
  final TipoCurso tipoCurso;

  const ListaScreen({
    super.key,
    required this.idCurso,
    required this.tipoCurso,
  });

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  late Future<List<AlumnoAsistenciaModel>> _alumnosFuture;
  List<AlumnoAsistenciaModel> _alumnos = []; 
  
  final Map<String, AttendanceStatus> _attendanceState = {};

  @override
  void initState() {
    super.initState();
    _cargarAlumnos(); 
  }
  
  // ✅ MÉTODO: Cargar alumnos (MODIFICADO para iniciar en Ausente)
  void _cargarAlumnos() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    _alumnosFuture = userProvider.fetchAlumnosPorCurso(
      idCurso: widget.idCurso,
      tipoCurso: widget.tipoCurso,
    ).then((alumnos) {
      
      alumnos.sort((a, b) {
        return a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase());
      });
      
      _alumnos = alumnos; 
      
      // ✅ MODIFICACIÓN 1: Inicializar el estado de asistencia de todos los alumnos a 'ausente' (Falta)
      for (var alumno in _alumnos) {
        _attendanceState[alumno.idCursoAlumno] = AttendanceStatus.ausente;
      }
      return _alumnos;
    });
  }

  // ✅ MÉTODO: Marcar a todos como Presente
  void _marcarTodosPresentes() { 
    setState(() {
      for (var alumno in _alumnos) {
        _attendanceState[alumno.idCursoAlumno] = AttendanceStatus.presente;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos los alumnos marcados como Asistencia.')),
    );
  }

  // ✅ NUEVO MÉTODO: Marcar Falta a Todos (Reemplaza a Desmarcar)
  void _marcarTodosAusentes() { 
    setState(() {
      for (var alumno in _alumnos) {
        _attendanceState[alumno.idCursoAlumno] = AttendanceStatus.ausente;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos los alumnos marcados con Falta.')),
    );
  }

  // ✅ MÉTODO: Marcar asistencia individual
  void _marcarAsistencia(String idCursoAlumno, AttendanceStatus status) { 
    setState(() {
      if (_attendanceState[idCursoAlumno] == status) {
        _attendanceState[idCursoAlumno] = AttendanceStatus.pendiente;
      } else {
        _attendanceState[idCursoAlumno] = status;
      }
    });
  }

  // ✅ MÉTODO: Enviar datos de asistencia
  void _enviarAsistencia() { 
    debugPrint('Datos de asistencia a enviar: $_attendanceState');
    
    final int pendientes = _attendanceState.values.where((s) => s == AttendanceStatus.pendiente).length;
    
    if (pendientes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aún quedan $pendientes alumnos por marcar.')),
      );
      return;
    }
    
    // TODO: Implementación real de la API POST
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Asistencia guardada con éxito (Simulación).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.tipoCurso == TipoCurso.club 
        ? 'Asistencia Club' 
        : 'Asistencia Materia';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _enviarAsistencia, 
              tooltip: 'Guardar Asistencia',
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AlumnoAsistenciaModel>>(
        future: _alumnosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar la lista: ${snapshot.error}', textAlign: TextAlign.center),
            );
          }
          
          final List<AlumnoAsistenciaModel> alumnos = snapshot.data ?? [];
          
          if (alumnos.isEmpty) {
            return const Center(
              child: Text('No hay alumnos inscritos en este curso o club.', textAlign: TextAlign.center),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // ⭐️ BOTÓN 1: MARCAR ASISTENCIA A TODOS (PRESENTE)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _marcarTodosPresentes, 
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('Asistencia', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ⭐️ BOTÓN 2: MARCAR FALTA A TODOS (AUSENTE) - MODIFICADO
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _marcarTodosAusentes, // ✅ NUEVA LLAMADA
                        icon: const Icon(Icons.close, size: 20), // Icono de Falta
                        label: const Text('Falta a Todos', style: TextStyle(fontWeight: FontWeight.bold)), // Nuevo Texto
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600, // Color de Falta
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ListView.builder(
                    itemCount: alumnos.length,
                    itemBuilder: (context, index) {
                      final alumno = alumnos[index];
                      final currentStatus = _attendanceState[alumno.idCursoAlumno] ?? AttendanceStatus.ausente;
                      
                      return _construirTarjetaAlumno(context, alumno, currentStatus); 
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ WIDGET: Construir la tarjeta del alumno
  Widget _construirTarjetaAlumno(BuildContext context, AlumnoAsistenciaModel alumno, AttendanceStatus currentStatus) { 
    Color statusColor = _obtenerColorPorEstado(currentStatus); 

    return Card(
      elevation: 4, 
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.8), 
          width: currentStatus == AttendanceStatus.pendiente ? 1 : 2.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.2),
            child: Text(
              alumno.primerNombre[0].toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            alumno.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Estado: ${_obtenerEtiquetaPorEstado(currentStatus)}'), 
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirBotonEstado(alumno.idCursoAlumno, AttendanceStatus.presente, currentStatus, Icons.check, Colors.green), 
              _construirBotonEstado(alumno.idCursoAlumno, AttendanceStatus.ausente, currentStatus, Icons.close, Colors.red), 
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET: Construir el botón de estado
  Widget _construirBotonEstado( 
    String idCursoAlumno,
    AttendanceStatus status,
    AttendanceStatus currentStatus,
    IconData icon,
    Color color,
  ) {
    final bool isSelected = currentStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: InkWell(
        onTap: () => _marcarAsistencia(idCursoAlumno, status), 
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer( 
          duration: const Duration(milliseconds: 200),
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.9) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
            boxShadow: isSelected 
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.white : color.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO: Obtener color
  Color _obtenerColorPorEstado(AttendanceStatus status) { 
    switch (status) {
      case AttendanceStatus.presente:
        return Colors.green.shade600;
      case AttendanceStatus.ausente:
        return Colors.red.shade600;
      case AttendanceStatus.pendiente:
        return Colors.blueGrey.shade300;
    }
  }
  
  // ✅ MÉTODO: Obtener etiqueta
  String _obtenerEtiquetaPorEstado(AttendanceStatus status) { 
    switch (status) {
      case AttendanceStatus.presente:
        return 'Asistencia';
      case AttendanceStatus.ausente:
        return 'Falta';
      case AttendanceStatus.pendiente:
        return 'Pendiente';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ Asegúrate de tener estas importaciones correctas
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 
import 'package:oficinaescolar_colaboradores/models/alumno_asistencia_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart'; // Tu enum TipoCurso

// ⭐️ Enum con solo Presente y Ausente ⭐️
enum AttendanceStatus { presente, ausente }


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
  // ⭐️ Color estático para Presente/Asistencia ⭐️
  final Color _presenteColor = Colors.green.shade600;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos(); 
  }
  
  // ✅ MÉTODO: Cargar alumnos (YA CORREGIDO para usar el estado de la API)
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
      
      // ✅ Inicializar el estado de asistencia desde el modelo.
      for (var alumno in _alumnos) {
        final bool isPresente = alumno.asistencia; 
        
        _attendanceState[alumno.idCursoAlumno] = isPresente 
            ? AttendanceStatus.presente 
            : AttendanceStatus.ausente; 
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

  // ✅ MÉTODO: Marcar Falta a Todos
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

  // ⭐️ Lógica de marcado individual simple ⭐️
  void _marcarAsistencia(String idCursoAlumno, AttendanceStatus status) { 
    setState(() {
      final currentStatus = _attendanceState[idCursoAlumno];
      
      // Si el usuario presiona el botón del estado actual, se alterna al estado opuesto.
      if (currentStatus == status) {
        // Alternar: Si es Presente, pasa a Ausente; si es Ausente, pasa a Presente.
        _attendanceState[idCursoAlumno] = status == AttendanceStatus.presente 
            ? AttendanceStatus.ausente
            : AttendanceStatus.presente;
      } else {
        // Si presiona el botón opuesto, simplemente se establece ese estado.
        _attendanceState[idCursoAlumno] = status;
      }
    });
  }

  // ✅ MÉTODO: Enviar datos de asistencia (ACTUALIZADO)
  void _enviarAsistencia() async { 
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Deshabilitar la interfaz temporalmente (opcional) y mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviando asistencia, por favor espere...')),
    );

    try {
      final Map<String, dynamic> result = await userProvider.setAsistenciaClubesOMaterias(
        idCurso: widget.idCurso,
        tipoCurso: widget.tipoCurso,
        attendanceState: _attendanceState,
        alumnosLista: _alumnos, // <--- CLAVE: Se pasa la lista completa de alumnos
      );

      // Limpiar la barra de mensajes anterior
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 

      // Mostrar el resultado de la API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );

      // Si fue exitoso, puedes querer regresar a la pantalla anterior
      if (result['status'] == 'success') {
        // Simplemente cerramos la pantalla de lista después de un éxito
        Navigator.of(context).pop(); 
      }

    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de aplicación al enviar: $e'),
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
    // ------------------------------------
    
    final String title = widget.tipoCurso == TipoCurso.club 
        ? 'Asistencia Club' 
        : 'Asistencia Materia';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
        ),
        backgroundColor: dynamicHeaderColor,
        centerTitle: true,
        actions: [
          
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 5.0, bottom: 5.0), // Ajuste de padding
            child: InkWell(
              onTap: _enviarAsistencia, 
              borderRadius: BorderRadius.circular(8), // Ajuste del InkWell para coincidir
              child: Tooltip(
                message: 'Guardar Asistencia',
                child: AnimatedContainer( 
                  duration: const Duration(milliseconds: 200),
                  width: 45, // Mismo tamaño
                  height: 45,
                  decoration: BoxDecoration(
                    // ⭐️ CAMBIO A RECTANGLE ⭐️
                    shape: BoxShape.rectangle, 
                    borderRadius: BorderRadius.circular(8), // ⭐️ ESQUINAS REDONDEADAS ⭐️
                    // ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.9),
                    border: Border.all(color: Colors.green, width: 2),
                    boxShadow: [
                      // ignore: deprecated_member_use
                      BoxShadow(color: colores.botonesColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Icon(
                    Icons.save, 
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
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
                    // BOTÓN 1: MARCAR ASISTENCIA A TODOS (PRESENTE)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _marcarTodosPresentes, 
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('Asistencia a todos', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colores.botonesColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // BOTÓN 2: MARCAR FALTA A TODOS (AUSENTE)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _marcarTodosAusentes,
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Falta a Todos', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colores.botonesColor,
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
                      // El estado actual ahora se basa en el mapa _attendanceState, que fue inicializado con la API.
                      final currentStatus = _attendanceState[alumno.idCursoAlumno] ?? AttendanceStatus.ausente;
                      
                      // ✅ MODIFICACIÓN CLAVE: Pasamos el índice (index)
                      return _construirTarjetaAlumno(context, alumno, currentStatus, _presenteColor, index); 
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
  Widget _construirTarjetaAlumno(
    BuildContext context, 
    AlumnoAsistenciaModel alumno, 
    AttendanceStatus currentStatus,
    Color presenteColor,
    int index, // ✅ RECIBE EL ÍNDICE
  ) { 
    Color statusColor = _obtenerColorPorEstado(currentStatus, presenteColor); 
    final int alumnoNumero = index + 1; // Contador 1-based (1, 2, 3...)

    return Card(
      elevation: 4, 
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          // ⭐️ Borde basado solo en el estado Presente/Ausente ⭐️
          color: statusColor.withOpacity(0.8), 
          width: 2.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: ListTile(
          // ✅ Se mantiene el contador sin CircleAvatar
          leading: SizedBox(
            width: 40, // Damos un ancho fijo para que el número no se mueva
            child: Text(
              alumnoNumero.toString(), 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor, // Mantenemos el color basado en el estado
                fontWeight: FontWeight.bold,
                fontSize: 16, 
              ),
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
              _construirBotonEstado(alumno.idCursoAlumno, AttendanceStatus.presente, currentStatus, Icons.check, presenteColor), 
              _construirBotonEstado(alumno.idCursoAlumno, AttendanceStatus.ausente, currentStatus, Icons.close, Colors.red.shade600),
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

  // ⭐️ Obtener color sin Pendiente ⭐️
  Color _obtenerColorPorEstado(AttendanceStatus status, Color presenteColor) { 
    switch (status) {
      case AttendanceStatus.presente:
        return presenteColor;
      case AttendanceStatus.ausente:
        return Colors.red.shade600;
    }
  }
  
  // ⭐️ Obtener etiqueta sin Pendiente ⭐️
  String _obtenerEtiquetaPorEstado(AttendanceStatus status) { 
    switch (status) {
      case AttendanceStatus.presente:
        return 'Asistencia';
      case AttendanceStatus.ausente:
        return 'Falta';
    }
  }
}
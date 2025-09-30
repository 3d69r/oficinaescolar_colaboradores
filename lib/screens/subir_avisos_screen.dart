import 'package:flutter/material.dart';
import 'crear_aviso_screen.dart';

// Modelo de datos para el aviso
class Aviso {
  final String id;
  String titulo;
  String contenido;
  DateTime fechaCreacion;
  DateTime fechaInicioVisualizacion;
  DateTime fechaFinVisualizacion;
  
  Aviso({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaInicioVisualizacion,
    required this.fechaFinVisualizacion,
  });
}

// Clase principal que maneja el listado de avisos
class SubirAvisosScreen extends StatefulWidget {
  const SubirAvisosScreen({Key? key}) : super(key: key);

  @override
  State<SubirAvisosScreen> createState() => _SubirAvisosScreenState();
}

class _SubirAvisosScreenState extends State<SubirAvisosScreen> {
  // Datos de ejemplo para la lista de avisos
  final List<Aviso> _avisos = [
    Aviso(
      id: '1',
      titulo: 'Reunión de Padres',
      contenido: 'Se convoca a una reunión el próximo viernes para discutir los avances...',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 1)),
      fechaInicioVisualizacion: DateTime.now().subtract(const Duration(days: 1)),
      fechaFinVisualizacion: DateTime.now().add(const Duration(days: 5)),
    ),
    Aviso(
      id: '2',
      titulo: 'Evento Deportivo Anual',
      contenido: 'Se invita a todos los alumnos a participar en el evento deportivo...',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 3)),
      fechaInicioVisualizacion: DateTime.now().subtract(const Duration(days: 3)),
      fechaFinVisualizacion: DateTime.now().add(const Duration(days: 2)),
    ),
    Aviso(
      id: '3',
      titulo: 'Día del Libro',
      contenido: 'Celebraremos el día del libro con diversas actividades en la biblioteca...',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 10)),
      fechaInicioVisualizacion: DateTime.now().subtract(const Duration(days: 10)),
      fechaFinVisualizacion: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  DateTime? _fechaFiltroInicio;
  DateTime? _fechaFiltroFin;

  Future<void> _seleccionarRangoDeFechas(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _fechaFiltroInicio = picked.start;
        _fechaFiltroFin = picked.end;
      });
    }
  }

  // Lista filtrada de avisos
  List<Aviso> get _avisosFiltrados {
    if (_fechaFiltroInicio == null || _fechaFiltroFin == null) {
      return _avisos;
    }
    return _avisos.where((aviso) {
      return (aviso.fechaInicioVisualizacion.isAfter(_fechaFiltroInicio!) ||
              aviso.fechaInicioVisualizacion.isAtSameMomentAs(_fechaFiltroInicio!)) &&
          (aviso.fechaFinVisualizacion.isBefore(_fechaFiltroFin!) ||
              aviso.fechaFinVisualizacion.isAtSameMomentAs(_fechaFiltroFin!));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir Avisos'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CrearAvisoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Crear Nuevo', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Listado'),
                  ),
                ),
              ],
            ),
          ),
          // Nuevo botón para el filtro de fecha
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () => _seleccionarRangoDeFechas(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Filtro de Fecha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _fechaFiltroInicio == null
                      ? 'Seleccionar rango de fechas'
                      : '${_fechaFiltroInicio!.day}/${_fechaFiltroInicio!.month}/${_fechaFiltroInicio!.year} - ${_fechaFiltroFin!.day}/${_fechaFiltroFin!.month}/${_fechaFiltroFin!.year}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de avisos
          Expanded(
            child: ListView.builder(
              itemCount: _avisosFiltrados.length,
              itemBuilder: (context, index) {
                final aviso = _avisosFiltrados[index];
                return Dismissible(
                  key: Key(aviso.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white, size: 36),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _avisos.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${aviso.titulo} eliminado')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: () {
                        // Navegar a la vista de edición
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => _CrearEditarAvisoView(avisoParaEditar: aviso),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.campaign, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aviso.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    '${aviso.fechaInicioVisualizacion.day}/${aviso.fechaInicioVisualizacion.month}/${aviso.fechaInicioVisualizacion.year} - ${aviso.fechaFinVisualizacion.day}/${aviso.fechaFinVisualizacion.month}/${aviso.fechaFinVisualizacion.year}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    aviso.contenido,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Vista de creación y edición (sin cambios, ya que está en un archivo separado)
class _CrearEditarAvisoView extends StatelessWidget {
  final Aviso? avisoParaEditar;

  const _CrearEditarAvisoView({Key? key, this.avisoParaEditar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(avisoParaEditar == null ? 'Crear Aviso' : 'Editar Aviso'),
      ),
      body: const Center(
        child: Text('Aquí va el formulario de creación/edición de avisos.'),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (avisoParaEditar != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
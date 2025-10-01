import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importar Provider
import 'crear_aviso_screen.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; // 2. Importar UserProvider

// Modelo de datos para el aviso (Sin cambios)
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
  // Datos de ejemplo para la lista de avisos (Sin cambios)
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

  // Lista filtrada de avisos (Sin cambios)
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
    // ⭐️ ACCESO AL PROVEEDOR DE COLOR ⭐️
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicPrimaryColor = colores.footerColor;
    // ------------------------------------

    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Subir Avisos',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: colores.headerColor,
          centerTitle: true,
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
                      // Se asume que 'CrearAvisoScreen' es la vista correcta
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CrearAvisoScreen(), 
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dynamicPrimaryColor, // ⭐️ Color Dinámico ⭐️
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
                      foregroundColor: dynamicPrimaryColor, // ⭐️ Color Dinámico ⭐️
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: dynamicPrimaryColor, width: 1.5), // ⭐️ Color Dinámico ⭐️
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
                  labelStyle: TextStyle(color: dynamicPrimaryColor), // ⭐️ Color Dinámico ⭐️
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder( // Color de borde al enfocar
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0), // ⭐️ Color Dinámico ⭐️
                  ),
                  suffixIcon: Icon(Icons.calendar_today, color: dynamicPrimaryColor), // ⭐️ Color Dinámico ⭐️
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
                // ❌ ELIMINADO: El widget Dismissible ha sido removido
                return Card(
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
                          CircleAvatar(
                            backgroundColor: dynamicPrimaryColor, // ⭐️ Color Dinámico ⭐️
                            child: const Icon(Icons.campaign, color: Colors.white),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Vista de creación y edición (Sin cambios, se incluye para completar el código)
class _CrearEditarAvisoView extends StatelessWidget {
  final Aviso? avisoParaEditar;

  const _CrearEditarAvisoView({Key? key, this.avisoParaEditar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ⭐️ ACCESO AL PROVEEDOR DE COLOR ⭐️
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicPrimaryColor = colores.footerColor;
    final Color dynamicAccentColor = colores.headerColor; // Usamos un color de acento/secundario para "Guardar"
    // ------------------------------------
    
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
                  // Lógica para eliminar el aviso (se asume que se hace aquí)
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // Mantener el rojo para "Eliminar"
                child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              ),
            ElevatedButton(
              onPressed: () {
                // Lógica para guardar el aviso
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: dynamicAccentColor), // ⭐️ Color Dinámico ⭐️
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(foregroundColor: dynamicPrimaryColor), // ⭐️ Color Dinámico ⭐️
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
/*// Archivo: editar_aviso_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 

// Modelo de Aviso (debe estar disponible globalmente o importado)
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

class EditarAvisoScreen extends StatefulWidget {
  // ⭐️ La vista de edición SIEMPRE recibe un Aviso para editar ⭐️
  final Aviso avisoParaEditar; 

  const EditarAvisoScreen({Key? key, required this.avisoParaEditar}) : super(key: key);

  @override
  _EditarAvisoScreenState createState() => _EditarAvisoScreenState();
}

class _EditarAvisoScreenState extends State<EditarAvisoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado para los campos
  final _tituloController = TextEditingController();
  final _cuerpoController = TextEditingController();
  String _destinatarioSeleccionado = 'Todos';
  String? _seleccionEspecifica; 
  String _respuestaSeleccionada = 'Ninguna';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));

  // --- Listas de ejemplo (mantener consistencia) ---
  final Map<String, List<String>> _opcionesEspecificas = {
    'Alumno Específico': ['Juan Pérez (A1)', 'Maria Gómez (A2)', 'Pedro López (A3)'],
    'Salón': ['1A', '2B', '3C'],
    'Club': ['Club de Ajedrez', 'Club de Debate', 'Club de Música'],
  };
  
  void _resetSeleccionEspecifica() {
    if (_destinatarioSeleccionado != 'Todos' && _opcionesEspecificas.containsKey(_destinatarioSeleccionado)) {
      if (!_opcionesEspecificas[_destinatarioSeleccionado]!.contains(_seleccionEspecifica)) {
        _seleccionEspecifica = _opcionesEspecificas[_destinatarioSeleccionado]!.first;
      }
    } else {
      _seleccionEspecifica = null;
    }
  }

  @override
  void initState() {
    super.initState();
    // ⭐️ INICIALIZACIÓN DE CAMPOS con la información del Aviso ⭐️
    final aviso = widget.avisoParaEditar;
    _tituloController.text = aviso.titulo;
    _cuerpoController.text = aviso.contenido;
    
    // Se asumen valores predeterminados, ya que el modelo Aviso de ejemplo
    // no contiene los campos de destinatario y respuesta.
    // En producción, usarías: _destinatarioSeleccionado = aviso.destinatario;
    _destinatarioSeleccionado = 'Todos'; 
    _respuestaSeleccionada = 'Ninguna';
    _seleccionEspecifica = null;

    _fechaInicio = aviso.fechaInicioVisualizacion;
    _fechaFin = aviso.fechaFinVisualizacion;
    
    _resetSeleccionEspecifica(); 
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _cuerpoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        final Color dynamicPrimaryColor = Provider.of<UserProvider>(context, listen: false).colores.headerColor;
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: dynamicPrimaryColor, 
            colorScheme: ColorScheme.light(primary: dynamicPrimaryColor), 
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  void _actualizarAviso() { // ⭐️ Función renombrada ⭐️
    if (_formKey.currentState!.validate()) {
      // Lógica de EDICIÓN
      final dataAviso = {
        'id': widget.avisoParaEditar.id, // ⭐️ ID del aviso que se edita ⭐️
        'titulo': _tituloController.text,
        'cuerpo': _cuerpoController.text,
        'destinatario': _destinatarioSeleccionado,
        'seleccionEspecifica': _destinatarioSeleccionado != 'Todos' ? _seleccionEspecifica : null, 
        'respuesta': _respuestaSeleccionada,
        'fechaInicio': _fechaInicio,
        'fechaFin': _fechaFin,
      };
      
      // Aquí se llamaría al API para actualizar el aviso
      // ignore: avoid_print
      print('Aviso ACTUALIZADO (ID: ${widget.avisoParaEditar.id}): $dataAviso');
      
      Navigator.pop(context); 
    }
  }

  void _eliminarAviso() {
    // Lógica para eliminar el aviso
    // ignore: avoid_print
    print('Aviso ELIMINADO (ID: ${widget.avisoParaEditar.id})');
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicPrimaryColor = colores.footerColor;
    final Color dynamicHeaderColor = colores.headerColor;
    final bool mostrarComboEspecifico = _destinatarioSeleccionado != 'Todos';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Aviso'), // ⭐️ Título Fijo ⭐️
        backgroundColor: dynamicHeaderColor,
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [ // ⭐️ Icono de eliminar siempre presente en la vista de edición ⭐️
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _eliminarAviso,
            tooltip: 'Eliminar aviso',
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Primer Combo: Mostrar en Calendario de
              _buildFiltroDropdown(
                label: 'Mostrar en Calendario de',
                value: _destinatarioSeleccionado,
                items: const ['Todos', 'Alumno Específico', 'Salón', 'Club'],
                onChanged: (String? newValue) {
                  setState(() {
                    _destinatarioSeleccionado = newValue!;
                    _resetSeleccionEspecifica(); 
                  });
                },
                dynamicPrimaryColor: dynamicPrimaryColor, 
              ),
              
              // Segundo Combo Condicional
              if (mostrarComboEspecifico) ...[
                const SizedBox(height: 20),
                _buildFiltroDropdown(
                  label: 'Seleccionar $_destinatarioSeleccionado',
                  value: _seleccionEspecifica ?? _opcionesEspecificas[_destinatarioSeleccionado]!.first,
                  items: _opcionesEspecificas[_destinatarioSeleccionado]!,
                  onChanged: (String? newValue) {
                    setState(() {
                      _seleccionEspecifica = newValue!;
                    }
                  );
                },
                dynamicPrimaryColor: dynamicPrimaryColor,
              ),
              ],
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDateInput(
                      label: 'Visible desde',
                      date: _fechaInicio,
                      onTap: () => _selectDate(context, true),
                      dynamicPrimaryColor: dynamicPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInput(
                      label: 'Visible hasta',
                      date: _fechaFin,
                      onTap: () => _selectDate(context, false),
                      dynamicPrimaryColor: dynamicPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFiltroDropdown(
                label: 'Requiere respuesta',
                value: _respuestaSeleccionada,
                items: const ['Ninguna', 'Sí'],
                onChanged: (String? newValue) {
                  setState(() {
                    _respuestaSeleccionada = newValue!;
                  });
                },
                dynamicPrimaryColor: dynamicPrimaryColor,
              ),
              const SizedBox(height: 20),
              // Campos de texto
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título', 
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder( 
                    borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: dynamicPrimaryColor), 
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cuerpoController,
                decoration: InputDecoration(
                  labelText: 'Comentario', 
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder( 
                    borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: dynamicPrimaryColor), 
                ),
                maxLines: null,
                minLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),
              // Botón de guardar
              ElevatedButton(
                onPressed: _actualizarAviso, // ⭐️ Función de ACTUALIZAR ⭐️
                style: ElevatedButton.styleFrom(
                  backgroundColor: dynamicPrimaryColor, 
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Actualizar Aviso'), // ⭐️ Texto de Actualizar ⭐️
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos de ayuda (se mantienen para que la vista funcione)
  Widget _buildFiltroDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged, required Color dynamicPrimaryColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value, 
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
            ),
          ),
          isExpanded: true,
          items: items.map<DropdownMenuItem<String>>((String itemValue) {
            return DropdownMenuItem<String>(
              value: itemValue,
              child: Text(itemValue),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateInput({required String label, required DateTime date, required VoidCallback onTap, required Color dynamicPrimaryColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
              ),
              suffixIcon: Icon(Icons.calendar_today, color: dynamicPrimaryColor),
            ),
            child: Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}*/
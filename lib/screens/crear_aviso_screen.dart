import 'package:flutter/material.dart';

class CrearAvisoScreen extends StatefulWidget {
  final Map<String, dynamic>? avisoParaEditar; // Null si es un nuevo aviso

  const CrearAvisoScreen({Key? key, this.avisoParaEditar}) : super(key: key);

  @override
  _CrearAvisoScreenState createState() => _CrearAvisoScreenState();
}

class _CrearAvisoScreenState extends State<CrearAvisoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado para los campos
  final _tituloController = TextEditingController();
  final _cuerpoController = TextEditingController();
  String _destinatarioSeleccionado = 'Todos';
  String _respuestaSeleccionada = 'Ninguna';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    // Llenar los campos si se está editando un aviso
    if (widget.avisoParaEditar != null) {
      _tituloController.text = widget.avisoParaEditar!['titulo'];
      _cuerpoController.text = widget.avisoParaEditar!['cuerpo'];
      _destinatarioSeleccionado = widget.avisoParaEditar!['destinatario'];
      _respuestaSeleccionada = widget.avisoParaEditar!['respuesta'];
      _fechaInicio = widget.avisoParaEditar!['fechaInicio'];
      _fechaFin = widget.avisoParaEditar!['fechaFin'];
    }
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

  void _guardarAviso() {
    if (_formKey.currentState!.validate()) {
      // Lógica para guardar el aviso en la base de datos o API
      // Aquí se enviaría el objeto con los datos del formulario
      final nuevoAviso = {
        'titulo': _tituloController.text,
        'cuerpo': _cuerpoController.text,
        'destinatario': _destinatarioSeleccionado,
        'respuesta': _respuestaSeleccionada,
        'fechaInicio': _fechaInicio,
        'fechaFin': _fechaFin,
      };
      print('Aviso guardado: $nuevoAviso');
      Navigator.pop(context); // Regresar a la pantalla de lista
    }
  }

  void _eliminarAviso() {
    // Lógica para eliminar el aviso
    print('Aviso eliminado');
    Navigator.pop(context); // Regresar a la pantalla de lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.avisoParaEditar == null ? 'Crear Aviso' : 'Editar Aviso'),
        actions: widget.avisoParaEditar != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _eliminarAviso,
            tooltip: 'Eliminar aviso',
          ),
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Selectores de filtros
              _buildFiltroDropdown(
                label: 'Mostrar en Calendario de',
                value: _destinatarioSeleccionado,
                items: ['Todos', 'Alumno Específico', 'Salón', 'Club'],
                onChanged: (String? newValue) {
                  setState(() {
                    _destinatarioSeleccionado = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDateInput(
                      label: 'Visible desde',
                      date: _fechaInicio,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInput(
                      label: 'Visible hasta',
                      date: _fechaFin,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFiltroDropdown(
                label: 'Requiere respuesta',
                value: _respuestaSeleccionada,
                items: ['Ninguna', 'Sí'],
                onChanged: (String? newValue) {
                  setState(() {
                    _respuestaSeleccionada = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Campos de texto
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
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
                decoration: const InputDecoration(labelText: 'Comentario', border: OutlineInputBorder()),
                maxLines: null, // Permite múltiples líneas
                minLines: 5,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 30),
              // Botón de guardar
              ElevatedButton(
                onPressed: _guardarAviso,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Guardar Aviso'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          isExpanded: true,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateInput({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
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
}
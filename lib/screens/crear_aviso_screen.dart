import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';

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
  // ⭐️ NUEVO ESTADO: Almacena el valor seleccionado en el segundo combo. ⭐️
  String? _seleccionEspecifica; 
  
  String _respuestaSeleccionada = 'Ninguna';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));

  // --- Listas de ejemplo para el segundo combo (Reemplazar con datos reales) ---
  final Map<String, List<String>> _opcionesEspecificas = {
    'Alumno Específico': ['Juan Pérez (A1)', 'Maria Gómez (A2)', 'Pedro López (A3)'],
    'Salón': ['1A', '2B', '3C'],
    'Club': ['Club de Ajedrez', 'Club de Debate', 'Club de Música'],
  };
  // ----------------------------------------------------------------------------
  
  // Función para resetear la selección específica cuando cambia el destinatario principal
  void _resetSeleccionEspecifica() {
    // Si la nueva selección no es 'Todos', se inicializa el valor en el primer elemento de la lista
    if (_destinatarioSeleccionado != 'Todos' && _opcionesEspecificas.containsKey(_destinatarioSeleccionado)) {
      _seleccionEspecifica = _opcionesEspecificas[_destinatarioSeleccionado]!.first;
    } else {
      _seleccionEspecifica = null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Llenar los campos si se está editando un aviso
    if (widget.avisoParaEditar != null) {
      _tituloController.text = widget.avisoParaEditar!['titulo'] as String? ?? '';
      _cuerpoController.text = widget.avisoParaEditar!['cuerpo'] as String? ?? '';
      _destinatarioSeleccionado = widget.avisoParaEditar!['destinatario'] as String? ?? 'Todos';
      _respuestaSeleccionada = widget.avisoParaEditar!['respuesta'] as String? ?? 'Ninguna';
      _fechaInicio = widget.avisoParaEditar!['fechaInicio'] as DateTime? ?? DateTime.now();
      _fechaFin = widget.avisoParaEditar!['fechaFin'] as DateTime? ?? DateTime.now().add(const Duration(days: 7));
      
      // ⭐️ Inicializar el nuevo combo al editar ⭐️
      // Esto asume que el avisoParaEditar contiene el campo 'seleccionEspecifica'
      _seleccionEspecifica = widget.avisoParaEditar!['seleccionEspecifica'] as String? ?? null;
      _resetSeleccionEspecifica(); // Asegurar consistencia
    } else {
      _resetSeleccionEspecifica();
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
      // Aplicar color dinámico al DatePicker
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

  void _guardarAviso() {
    if (_formKey.currentState!.validate()) {
      // Lógica para guardar el aviso en la base de datos o API
      // Aquí se enviaría el objeto con los datos del formulario
      final nuevoAviso = {
        'titulo': _tituloController.text,
        'cuerpo': _cuerpoController.text,
        'destinatario': _destinatarioSeleccionado,
        // ⭐️ Incluir la selección específica solo si aplica ⭐️
        'seleccionEspecifica': _destinatarioSeleccionado != 'Todos' ? _seleccionEspecifica : null, 
        'respuesta': _respuestaSeleccionada,
        'fechaInicio': _fechaInicio,
        'fechaFin': _fechaFin,
      };
      // ignore: avoid_print
      print('Aviso guardado: $nuevoAviso');
      Navigator.pop(context); // Regresar a la pantalla de lista
    }
  }

  void _eliminarAviso() {
    // Lógica para eliminar el aviso
    // ignore: avoid_print
    print('Aviso eliminado');
    Navigator.pop(context); // Regresar a la pantalla de lista
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ ACCESO AL PROVEEDOR DE COLOR ⭐️
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicPrimaryColor = colores.footerColor;
    final Color dynamicHeaderColor = colores.headerColor;
    // ------------------------------------

    // ⭐️ DETERMINAR SI EL SEGUNDO COMBO DEBE MOSTRARSE ⭐️
    final bool mostrarComboEspecifico = _destinatarioSeleccionado != 'Todos';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.avisoParaEditar == null ? 'Crear Aviso' : 'Editar Aviso'),
        backgroundColor: dynamicHeaderColor,
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: widget.avisoParaEditar != null
            ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _eliminarAviso,
            tooltip: 'Eliminar aviso',
            color: Colors.white,
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
              // Primer Combo: Mostrar en Calendario de
              _buildFiltroDropdown(
                label: 'Mostrar en Calendario de',
                value: _destinatarioSeleccionado,
                items: const ['Todos', 'Alumno Específico', 'Salón', 'Club'],
                onChanged: (String? newValue) {
                  setState(() {
                    _destinatarioSeleccionado = newValue!;
                    _resetSeleccionEspecifica(); // ⭐️ Llamada para resetear/inicializar el segundo combo ⭐️
                  });
                },
                dynamicPrimaryColor: dynamicPrimaryColor,
              ),
              
              // ⭐️ NUEVO COMBO CONDICIONAL ⭐️
              if (mostrarComboEspecifico) ...[
                const SizedBox(height: 20),
                _buildFiltroDropdown(
                  // El label es dinámico según la selección
                  label: 'Seleccionar $_destinatarioSeleccionado',
                  // Usamos _seleccionEspecifica (ya inicializado en _resetSeleccionEspecifica)
                  value: _seleccionEspecifica ?? _opcionesEspecificas[_destinatarioSeleccionado]!.first,
                  items: _opcionesEspecificas[_destinatarioSeleccionado]!,
                  onChanged: (String? newValue) {
                    setState(() {
                      _seleccionEspecifica = newValue!;
                    });
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
                onPressed: _guardarAviso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: dynamicPrimaryColor,
                  foregroundColor: Colors.white,
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

  // Modificamos la firma para aceptar el color dinámico
  Widget _buildFiltroDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color dynamicPrimaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // Corregido: Usar el value proporcionado, el cual puede ser String o String?
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

  // Se mantiene sin cambios
  Widget _buildDateInput({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required Color dynamicPrimaryColor,
  }) {
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
}
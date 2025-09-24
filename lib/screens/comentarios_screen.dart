// lib/screens/comentarios_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/comentario_model.dart'; 

class ComentariosScreen extends StatefulWidget {
  const ComentariosScreen({super.key});

  @override
  State<ComentariosScreen> createState() => _ComentariosScreenState();
}

class _ComentariosScreenState extends State<ComentariosScreen> {
  // Controlador para el campo de texto.
  final TextEditingController _commentController = TextEditingController();
  
  // Clave global para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  // Variable de estado para controlar el indicador de carga del botón.
  bool _isLoading = false;
  
  // Variable de estado para la opción seleccionada del combo.
  TipoComentario? _selectedTipo;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Método para enviar el comentario.
  Future<void> _submitComment() async {
    // 1. Validar el formulario. Esto activa la validación del DropdownButtonFormField.
    if (!_formKey.currentState!.validate()) {
      // Si la validación falla, no hacemos nada y el mensaje de error se muestra debajo del combo.
      return;
    }

    // 2. Obtener el texto y validarlo manualmente (para el TextField).
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      _showSnackBar('Por favor, escribe un comentario antes de enviar.', Colors.red);
      return;
    }

    // 3. Si ambas validaciones pasan, procedemos con el envío.
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final comentario = Comentario(tipo: _selectedTipo!, texto: commentText);
      await userProvider.enviarComentario(comentario);
      
      _showSnackBar('¡Gracias por tu comentario! Lo valoramos mucho.', Colors.green);
      _commentController.clear();
      setState(() {
        _selectedTipo = null;
      });

    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), Colors.red);
      debugPrint('Error al enviar comentario: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método auxiliar para mostrar un SnackBar.
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comentarios y Sugerencias'),
          backgroundColor: colores.headerColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form( 
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    '¡Ayúdanos a mejorar!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Elige una categoría y dinos tu opinión sobre la app.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<TipoComentario>(
                    value: _selectedTipo,
                    hint: const Text('Selecciona una opción'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colores.headerColor,
                          width: 2.0,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TipoComentario.problema,
                        child: Text('Reportar un problema'),
                      ),
                      DropdownMenuItem(
                        value: TipoComentario.idea,
                        child: Text('Tengo una idea para mejorarla'),
                      ),
                      DropdownMenuItem(
                        value: TipoComentario.desacuerdo,
                        child: Text('No estoy de acuerdo con...'),
                      ),
                      DropdownMenuItem(
                        value: TipoComentario.felicitacion,
                        child: Text('Felicitaciones'),
                      ),
                      DropdownMenuItem(
                        value: TipoComentario.sugerencia,
                        child: Text('Otra sugerencia'),
                      ),
                    ],
                    onChanged: (TipoComentario? newValue) {
                      setState(() {
                        _selectedTipo = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecciona una categoría';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _commentController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Describe tu comentario aquí...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colores.headerColor,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submitComment,
                    style: FilledButton.styleFrom(
                      backgroundColor: colores.botonesColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enviar Comentario',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
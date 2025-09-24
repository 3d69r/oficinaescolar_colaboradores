import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/services/api_client.dart';
import 'package:oficinaescolar_colaboradores/widgets/input_decoration.dart';
import 'package:provider/provider.dart';

class CodeEscuelaScreen extends StatefulWidget {
  const CodeEscuelaScreen({super.key});

  @override
  State<CodeEscuelaScreen> createState() => _CodeEscuelaScreenState();
}

class _CodeEscuelaScreenState extends State<CodeEscuelaScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

   // ✅ [NUEVO] Método para llamar a la API de notificar_firebase
  Future<void> notificarFirebase() async {
  final apiClient = Provider.of<ApiClient>(context, listen: false);
  final url = ApiConstants.getNotificarFirebaseUrl();

  try {
    final response = await apiClient.get(url);

    // ✅ Imprimimos la respuesta completa para el debug
    print('Respuesta de notificar_firebase:');
    print('StatusCode: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      // ✅ [NUEVO] Decodificamos el cuerpo JSON de la respuesta
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? message = responseData['message'];

        if (message != null) {
          debugPrint('Mensaje de la API: $message');
        }

        debugPrint('Notificación a Firebase procesada exitosamente.');
      } on FormatException catch (e) {
        // Maneja el caso en que la respuesta no sea un JSON válido
        debugPrint('Error: La respuesta de la API no es un JSON válido: $e');
      }
    } else {
      debugPrint('Error en la llamada a la API. Código de estado: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Excepción al llamar a notificar_firebase: $e');
  }
}

  Future<Map<String, dynamic>?> validarCodigoEscuela(String codigo) async {
  final url = Uri.parse(
    'https://oficinaescolar.com/ws_oficinae/index.php/api/validate_escuela',
  );

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'escuela': codigo},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data;
      } else {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Escuela no encontrada'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return null;
      }
    } else {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en el servidor, intenta más tarde.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  } on SocketException {
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifica tu conexión a internet e inténtalo de nuevo.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  } catch (e) {
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocurrió un error inesperado: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  }
}
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(children: [_cajaAzul(size), _loginForm(context)]),
        ),
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 280),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Código de escuela',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _codigoController,
                      autocorrect: false,
                      decoration: InputDecorations.inputDecoration(
                        hintext: 'Ingresa el código escuela',
                        labeltext: 'Escuela',
                        icono: const Icon(Icons.key),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingrese un código de escuela';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : MaterialButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledColor: Colors.grey,
                          color: Colors.indigoAccent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 15,
                            ),
                            child: const Text(
                              'Ingresar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          onPressed: () async {
                            final codigo = _codigoController.text.trim();
                            if (codigo.isEmpty ||
                                !_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ingrese un código de escuela válido',
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                            });

                            await notificarFirebase();

                            final response = await validarCodigoEscuela(codigo);

                            // --- INICIO DE LA MODIFICACIÓN ---
                            if (response != null) {
                              // 1. Obtener una referencia al UserProvider.
                              //    Usamos listen: false porque solo queremos llamar a un método, no reconstruir el widget.
                              final userProvider = Provider.of<UserProvider>(
                                context,
                                listen: false,
                              );

                              // 2. Llamar al nuevo método para procesar y guardar los colores.
                              //    Aquí es donde verás los prints en la consola.
                              await userProvider.processAndSaveSchoolColors(
                                response,
                              );

                              // 3. Navegar a la pantalla de login, sabiendo que los colores ya están en el provider.
                              Navigator.pushReplacementNamed(
                                context,
                                'login',
                                arguments: {'codigo': codigo},
                              );
                            }
                            // --- FIN DE LA MODIFICACIÓN ---

                            setState(() {
                              _isLoading = false;
                            });
                          },
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _cajaAzul(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.indigoAccent,
      width: double.infinity,
      height: size.height * 0.4,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'OFICINA ESCOLAR',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Acceso Colaboradores',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'La app para administrar tu escuela',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
//MENSAJE BANDERA ESTE CODIGO ES FUNCIONAL
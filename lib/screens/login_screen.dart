import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oficinaescolar_colaboradores/widgets/input_decoration.dart';
//import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  String? _currentSchoolCode;
  
  // [NUEVO] Referencia al UserProvider y a los colores dinámicos
  // Se mantienen para referencia, aunque el provider se accede dentro de build()
  // late UserProvider userProvider; 
  // late Colores colores; 


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is Map<String, dynamic>) {
      _currentSchoolCode = args['codigo'] as String?;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String makeidPsw() {
    const String possible = "123456789abcdefghijklmnpqrstuvwxyz123456789";
    final Random random = Random();
    String text = "";
    for (int i = 0; i < 6; i++) {
      text += possible[random.nextInt(possible.length)];
    }
    return text;
  }

  Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
    String escuela,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.apiBaseUrl}${ApiConstants.validateUserEndpoint}',
    );
    final Map<String, String> requestBody = {
      'email': email,
      'password': password,
      'escuela': escuela,
      'seccion': 'Colaboradores',
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: requestBody,
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Error de autenticación');
    }
  }

  void onLoginPressed() async {
    if (!formKey.currentState!.validate()) {
      _showSnackBar('Por favor, ingresa tu correo y contraseña.');
      return;
    }

    setState(() => isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String? finalSchoolCode = _currentSchoolCode ?? userProvider.escuela;
    if (finalSchoolCode.isEmpty) {
      _showSnackBar('Código de escuela no disponible');
      setState(() => isLoading = false);
      return;
    }

    try {
      final String sessionFechaHora = userProvider.generateApiFechaHora();

      final responseData = await loginUser(
        emailController.text.trim(),
        passwordController.text.trim(),
        finalSchoolCode,
      );

      final String idColaborador = responseData['id_colaborador']?.toString() ?? ''; // ✅ [REF] Cambiado de idPersona a idColaborador
      final String idEmpresa = responseData['id_empresa']?.toString() ?? '';

      if (idColaborador.isEmpty || idEmpresa.isEmpty) {
        throw Exception('Datos incompletos devueltos por la API.');
      }

      await userProvider.setUserData(
        idColaborador: idColaborador, // ✅ [REF] Cambiado de idPersona
        idEmpresa: idEmpresa,
        email: emailController.text.trim(),
        escuela: finalSchoolCode,
        fechaHora: sessionFechaHora,
        idCiclo: '',
      );

      final tokenFirebase = await FirebaseMessaging.instance.getToken();

      await userProvider.actualizarInfoToken(
        escuela: finalSchoolCode,
        idColaborador: idColaborador, // ✅ [REF] Cambiado de idPersona
        tokenCelular: tokenFirebase ?? '',
        status: 'activo',
      );

      await userProvider.saveColaboradorSessionToPrefs(
        idColaborador: idColaborador,
        idEmpresa: idEmpresa,
        email: emailController.text.trim(),
        escuela: finalSchoolCode,
        fechaHora: sessionFechaHora,
        idCiclo: '',
        idToken: userProvider.idToken, // ¡Ahora tiene el token correcto!
        fcmToken: tokenFirebase,
      );

      

      if (mounted) {
        Navigator.pushReplacementNamed(context, 'home');
      }
    } on SocketException {
      _showSnackBar('Verifica tu conexión a internet e inténtalo de nuevo.');
    } catch (e) {
      _showSnackBar(
        'Error al iniciar sesión: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Modal para seleccionar opción de recuperación (Email/SMS) ---
  void _showForgotPasswordOptionsModal() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final dialogMaxHeight = screenHeight * 0.7;
        // [MODIFICACIÓN] Obtener los colores del provider dentro del builder
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final colores = userProvider.colores;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título con fondo azul y letras blancas y negritas
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                decoration: BoxDecoration(
                  color: colores.headerColor, // ✅ Se usa el color del provider
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: const Text(
                  'Recuperar Contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Contenido del modal envuelto en ConstrainedBox
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Selecciona la opción deseada:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      // Botones Email y SMS en una fila
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          // Botón Email con icono
                          SizedBox(
                            width: 100.0,
                            height: 50.0,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                 _showInputManualModal('email'); 
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colores.headerColor, // ✅ Se usa el color del provider
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.email, size: 20),
                                  SizedBox(width: 8),
                                  Text('Email', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          // Botón SMS con icono
                          SizedBox(
                            width: 100.0,
                            height: 50.0,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showInputManualModal('celular'); 
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colores.headerColor, // ✅ Se usa el color del provider
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sms, size: 20),
                                  SizedBox(width: 8),
                                  Text('SMS', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Botón de Cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                child: Center(
                  child: SizedBox(
                    width: 100.0,
                    height: 50.0,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colores.botonesColor, // ✅ Se usa el color del provider
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInputManualModal(String type) {
    final controller = TextEditingController();
    final isEmail = type == 'email';
    final label = isEmail ? 'Correo electrónico' : 'Número de celular';
    final titleText = isEmail ? 'Recuperar por Email' : 'Recuperar por SMS';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final dialogMaxHeight = screenHeight * 0.7;

        // [MODIFICACIÓN] Obtener los colores del provider dentro del builder
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final colores = userProvider.colores;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título con fondo azul y letras blancas y negritas
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                decoration: BoxDecoration(
                  color: colores.headerColor, // ✅ Se usa el color del provider
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Contenido del modal
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: dialogMaxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ingresa tu $label:',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: controller,
                        keyboardType:
                            isEmail
                                ? TextInputType.emailAddress
                                : TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      // Botón Enviar
                      Center(
                        child: SizedBox(
                          width: 100.0,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isEmpty) {
                                _showSnackBar('El campo no puede estar vacío.'); 
                                return;
                              }
                              Navigator.pop(dialogContext);
                              _sendForgotPasswordRequest(type, controller.text.trim()); 
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colores.botonesColor, // ✅ Se usa el color del provider
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            child: const Text(
                              'Enviar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Botón de Cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                child: Center(
                  child: SizedBox(
                    width: 100.0,
                    height: 50.0,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colores.botonesColor, // ✅ Se usa el color del provider
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendForgotPasswordRequest(String type, String value) async {
    String? finalSchoolCode =
        _currentSchoolCode ??
        Provider.of<UserProvider>(context, listen: false).escuela;
    if (finalSchoolCode.isEmpty) {
      _showSnackBar('Código de escuela no disponible');
      return;
    }

    final String newPassword = makeidPsw();
    // Modificación aquí: Usamos el nuevo método para obtener la URL
    final url = Uri.parse(ApiConstants.getForgotPasswordUrl());
    
    final body = {
      'escuela': finalSchoolCode,
      'seccion': 'Colaboradores',
      'tipo_envio': type,
      'psw': newPassword,
      'email': type == 'email' ? value : '',
      'numcelular': type == 'celular' ? value : '',
    };

    final encodedBody = body.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    debugPrint(
      'ForgotPassword - Cuerpo enviado (form-urlencoded): $encodedBody',
    );
    // Agregamos el print de la URL para depuración
    debugPrint('ForgotPassword - URL de la solicitud: $url');

    try {
      setState(() => isLoading = true);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      debugPrint(
        'ForgotPassword response (${response.statusCode}): ${response.body}',
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 &&
          (data['status'] == 'success' || data['status'] == 'correcto')) {
        _showSnackBar(
          'Instrucciones enviadas por ${type == 'email' ? 'email' : 'celular'}',
          backgroundColor: Colors.green,
        );
      } else {
        _showSnackBar('Error: ${data['message'] ?? 'Inténtalo de nuevo.'}');
      }
    } catch (e) {
      _showSnackBar(
        'Error al recuperar contraseña: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {

    // [MODIFICACIÓN] Obtener los colores del provider dentro del build
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;
    
    final size = MediaQuery.of(context).size;
    
    // ⚙️ DEFINICIÓN RESPONSIVA: Ancho máximo para el formulario en web/desktop.
    const double maxFormWidth = 450; 


    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: size.height * 0.4,
              decoration: BoxDecoration(
                color: colores.headerColor, // Se usa el color dinámico
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BIENVENIDOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Acceso Colaboradores', // ✅ [REF] Texto actualizado
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 250),
                  // 🚀 INICIO DE LA MODIFICACIÓN RESPONSIVA
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: maxFormWidth, // Límite el ancho en pantallas grandes
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        width: double.infinity, // Se ajustará al maxWidth o al ancho móvil.
                        height: 390,
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
                            key: formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                if (_currentSchoolCode != null)
                                  Text(
                                    '$_currentSchoolCode'.toUpperCase(),
                                    style: TextStyle(
                                      color: colores.headerColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecorations.inputDecoration(
                                    hintext: 'Ingresa tu correo electrónico',
                                    labeltext: 'Usuario',
                                    icono: const Icon(Icons.alternate_email_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty)
                                      return 'El correo es requerido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 30),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecorations.inputDecoration(
                                    hintext: 'Ingresa tu contraseña',
                                    labeltext: 'Contraseña',
                                    icono: const Icon(Icons.lock),
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscurePassword = !_obscurePassword,
                                          ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null || value.trim().length < 4
                                              ? 'Contraseña mínima de 4 caracteres'
                                              : null,
                                ),
                                const SizedBox(height: 20),
                                MaterialButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: colores.botonesColor,
                                  onPressed: isLoading ? null : onLoginPressed,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 80,
                                      vertical: 15,
                                    ),
                                    child:
                                        isLoading
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'Ingresar',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: _showForgotPasswordOptionsModal,
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colores.botonesColor,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 🛑 FIN DE LA MODIFICACIÓN RESPONSIVA
                  const SizedBox(height: 50),
                ],
              ), 
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
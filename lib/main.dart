import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oficinaescolar_colaboradores/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:oficinaescolar_colaboradores/screens/code_escuela_screen.dart';
import 'package:oficinaescolar_colaboradores/screens/home_screen.dart';
import 'package:oficinaescolar_colaboradores/screens/login_screen.dart';
import 'package:oficinaescolar_colaboradores/services/api_client.dart';
import 'package:oficinaescolar_colaboradores/services/aviso_navigation_signal.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oficinaescolar_colaboradores/utils/log_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _phoneBreakpoint = 600.0;

final StreamController<Map<String, dynamic>> _dataPushController =
    StreamController<Map<String, dynamic>>.broadcast();

/// Tipos de push que la app sabe manejar. Agregar aquí un tipo nuevo
/// es todo lo que se necesita en este archivo.
const Set<String> _knownPushTypes = {'aviso_nuevo'};

String? _sectionForTipo(String tipo) {
  switch (tipo) {
    case 'aviso_nuevo':
      return 'avisos';
    default:
      return null;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // La inicialización de Firebase es necesaria para handlers en segundo plano
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  appLog('📥 [BACKGROUND] Mensaje FCM recibido: ${message.messageId}');
  appLog('📥 [BACKGROUND] data completo: ${message.data}');

  // El isolate de background no tiene acceso al Provider ni al stream de la
  // app en primer plano, así que solo dejamos una bandera en disco.
  // main() la lee al arrancar (cuando el usuario toca la notificación).
  final String tipo = message.data['tipo']?.toString() ?? '';
  if (_knownPushTypes.contains(tipo)) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_push_tipo', tipo);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
      await initializeDateFormatting('es', null);
  } catch (e) {
      appLog('Error al inicializar formato de fecha: $e');
      await initializeDateFormatting();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
   
  final String? fcmTokenFromFirebase = await _initPushNotifications(); 

  final UserProvider tempUserProvider = UserProvider();
  // Conecta el stream de pushes (foreground / abierto desde background)
  // directamente al manejador del provider.
  _dataPushController.stream.listen(tempUserProvider.handleDataPush);
  await tempUserProvider.loadUserDataFromDb();
  
  if (fcmTokenFromFirebase != null) {
      tempUserProvider.setFcmTokenForWeb(fcmTokenFromFirebase); 
      appLog('main.dart: FCM Token asignado al UserProvider en memoria.');
  }

  // 🚀 ¿La app se abrió (cold start) tocando una notificación?
  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  final String initialTipo = initialMessage?.data['tipo']?.toString() ?? '';
  if (initialMessage != null && _knownPushTypes.contains(initialTipo)) {
    appLog('main.dart: App abierta desde notificación (terminada). tipo=$initialTipo');
    _dataPushController.add(initialMessage.data);
    pendingOpenSection.value = _sectionForTipo(initialTipo);
  }

  // 🚀 ¿Llegó un push mientras la app estaba en background (no terminada)?
  final prefs = await SharedPreferences.getInstance();
  final String? pendingTipo = prefs.getString('pending_push_tipo');
  if (pendingTipo != null && _knownPushTypes.contains(pendingTipo)) {
    await prefs.remove('pending_push_tipo');
    appLog('main.dart: Bandera de refresco pendiente detectada. tipo=$pendingTipo');
    pendingOpenSection.value = _sectionForTipo(pendingTipo);
    tempUserProvider.handleDataPush({'tipo': pendingTipo});
  }

  String initialRoute;
  if (tempUserProvider.idColaborador.isNotEmpty) {
    initialRoute = 'home';
    appLog('main.dart: Sesión de colaborador encontrada en DB. Ruta inicial: home');
  } else {
    initialRoute = '/';
    appLog('main.dart: No se encontró sesión en DB. Ruta inicial: /');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(
          value: tempUserProvider,
        ),
        ProxyProvider<UserProvider, ApiClient>(
          update: (_, userProvider, __) => ApiClient(userProvider),
        ),
      ],
      child: MyApp(
        initialRoute: initialRoute,
      ),
    ),
  );
}

Future<String?> _initPushNotifications() async {
   FirebaseMessaging messaging = FirebaseMessaging.instance;
   NotificationSettings settings = await messaging.requestPermission(
     alert: true,
     badge: true,
     sound: true,
     carPlay: false,
     criticalAlert: false,
     provisional: false,
     announcement: false,
   );
   appLog('🔔 Permisos de notificaciones: ${settings.authorizationStatus}');
   
   String? token = await messaging.getToken();
   appLog('📲 Token FCM: $token');
   
   // Foreground: la app está abierta y visible.
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     appLog('📥 [FOREGROUND] Mensaje FCM: ${message.notification?.title} - ${message.notification?.body}');
     appLog('📥 [FOREGROUND] data completo: ${message.data}');
     final String tipo = message.data['tipo']?.toString() ?? '';
     if (_knownPushTypes.contains(tipo)) {
       _dataPushController.add(message.data);
     }
   });

   // Background (no terminada) y el usuario toca la notificación.
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     appLog('🟢 [OPENED APP] App abierta desde notificación FCM: ${message.messageId}');
     appLog('🟢 [OPENED APP] data completo: ${message.data}');
     final String tipo = message.data['tipo']?.toString() ?? '';
     if (_knownPushTypes.contains(tipo)) {
       _dataPushController.add(message.data);
       pendingOpenSection.value = _sectionForTipo(tipo);
     }
   });

   RemoteMessage? initialMessage = await messaging.getInitialMessage();
   if (initialMessage != null) {
     appLog('🚀 [INITIAL MESSAGE] App iniciada desde notificación FCM terminada: ${initialMessage.messageId}');
   }
   
   return token;
 }

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationHandler(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OFICINA COLABORADORES',
        initialRoute: initialRoute,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'), 
        routes: {
          '/': (_) => const CodeEscuelaScreen(),
          'login': (context) => const LoginScreen(),
          'home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

class OrientationHandler extends StatelessWidget {
  final Widget child;
  const OrientationHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < _phoneBreakpoint) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    
    return child;
  }
}
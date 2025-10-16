// main.dart para la app de colaboradores
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
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';

const double _phoneBreakpoint = 600.0;

// ✅ TODO: Descomentar y habilitar cuando Firebase se configure para la app de colaboradores.
 @pragma('vm:entry-point')
 Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
   await Firebase.initializeApp();
   debugPrint('📥 [BACKGROUND] Mensaje FCM recibido: ${message.messageId}');
 }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
      await initializeDateFormatting('es', null);
  } catch (e) {
      // Manejo de error si la inicialización falla por alguna razón (poco probable)
      debugPrint('Error al inicializar formato de fecha: $e');
      await initializeDateFormatting(); // Intenta la inicialización por defecto
  }

  // ✅ TODO: Descomentar y habilitar la inicialización de Firebase cuando esté lista.
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );

  // ✅ TODO: Descomentar y habilitar los handlers de FCM cuando el servicio esté listo.
   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
   await _initPushNotifications();

  final UserProvider tempUserProvider = UserProvider();
  await tempUserProvider.loadUserDataFromDb();

  String initialRoute;
  if (tempUserProvider.idColaborador.isNotEmpty) {
    initialRoute = 'home';
    debugPrint('main.dart: Sesión de colaborador encontrada en DB. Ruta inicial: home');
  } else {
    initialRoute = '/';
    debugPrint('main.dart: No se encontró sesión en DB. Ruta inicial: /');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(
          value: tempUserProvider,
        ),
        ProxyProvider<UserProvider, ApiClient>(
          update: (_, userProvider, _) => ApiClient(userProvider),
        ),
      ],
      child: MyApp(
        initialRoute: initialRoute,
      ),
    ),
  );
}

// ✅ TODO: Descomentar y habilitar cuando Firebase se configure para la app de colaboradores.
 Future<void> _initPushNotifications() async {
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
   debugPrint('🔔 Permisos de notificaciones: ${settings.authorizationStatus}');
   String? token = await messaging.getToken();
   debugPrint('📲 Token FCM: $token');
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     debugPrint('📥 [FOREGROUND] Mensaje FCM: ${message.notification?.title} - ${message.notification?.body}');
   });
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     debugPrint('🟢 [OPENED APP] App abierta desde notificación FCM: ${message.messageId}');
   });
   RemoteMessage? initialMessage = await messaging.getInitialMessage();
   if (initialMessage != null) {
     debugPrint('🚀 [INITIAL MESSAGE] App iniciada desde notificación FCM terminada: ${initialMessage.messageId}');
   }
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
// CODIGO FUNCIONAL
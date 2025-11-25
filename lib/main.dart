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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oficinaescolar_colaboradores/utils/log_util.dart';

const double _phoneBreakpoint = 600.0;

// ✅ TODO: Descomentar y habilitar cuando Firebase se configure para la app de colaboradores.
 @pragma('vm:entry-point')
 Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
   // La inicialización de Firebase es necesaria para handlers en segundo plano
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   appLog('📥 [BACKGROUND] Mensaje FCM recibido: ${message.messageId}');
 }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
      await initializeDateFormatting('es', null);
  } catch (e) {
      // Manejo de error si la inicialización falla por alguna razón (poco probable)
      appLog('Error al inicializar formato de fecha: $e');
      await initializeDateFormatting(); // Intenta la inicialización por defecto
  }

  // ✅ Inicialización de Firebase.
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );

  // ✅ Habilitación de handlers de FCM.
   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
   
   // 🚀 CAMBIO 1: Capturamos el token devuelto.
   final String? fcmTokenFromFirebase = await _initPushNotifications(); 

  final UserProvider tempUserProvider = UserProvider();
  await tempUserProvider.loadUserDataFromDb();
  
  // 🚀 CAMBIO 2: Asignamos el token FCM al Provider en memoria antes de runApp().
  if (fcmTokenFromFirebase != null) {
      // NOTA: Debes implementar este método en UserProvider: setFcmTokenForWeb(String token)
      tempUserProvider.setFcmTokenForWeb(fcmTokenFromFirebase); 
      appLog('main.dart: FCM Token asignado al UserProvider en memoria.');
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
          update: (_, userProvider, __) => ApiClient(userProvider), // Corregido: '__' para el tercer argumento
        ),
      ],
      child: MyApp(
        initialRoute: initialRoute,
      ),
    ),
  );
}

// ✅ CAMBIO 3: La función ahora devuelve el token.
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
   
   String? token = await messaging.getToken(); // Token obtenido
   appLog('📲 Token FCM: $token');
   
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     appLog('📥 [FOREGROUND] Mensaje FCM: ${message.notification?.title} - ${message.notification?.body}');
   });
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     appLog('🟢 [OPENED APP] App abierta desde notificación FCM: ${message.messageId}');
   });
   RemoteMessage? initialMessage = await messaging.getInitialMessage();
   if (initialMessage != null) {
     appLog('🚀 [INITIAL MESSAGE] App iniciada desde notificación FCM terminada: ${initialMessage.messageId}');
   }
   
   return token; // 👈 Devolvemos el token
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
        // ⭐️ INICIO DE LA CONFIGURACIÓN DE LOCALIZACIÓN (ESPAÑOL) ⭐️
        localizationsDelegates: const [
          // Delegado de Material para textos de UI (botones, meses, días)
          GlobalMaterialLocalizations.delegate,
          // Delegado para widgets
          GlobalWidgetsLocalizations.delegate,
          // Delegado para widgets de iOS/Cupertino
          GlobalCupertinoLocalizations.delegate,
        ],
        // Definimos los idiomas que la app debe cargar
        supportedLocales: const [
          Locale('en', 'US'), // Inglés (generalmente se incluye por defecto)
          Locale('es', 'ES'), // Español de España/general
        ],
        // Definimos la localización por defecto si el sistema del usuario no es 'es'.
        // Ya tienes initializeDateFormatting('es', null) en main(), pero esto es más robusto.
        locale: const Locale('es', 'ES'), 
        // ⭐️ FIN DE LA CONFIGURACIÓN DE LOCALIZACIÓN ⭐️
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
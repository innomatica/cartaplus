import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'logic/cartabloc.dart';
import 'logic/cartaauth.dart';
import 'logic/screenconfig.dart';
import 'screens/settings/settings.dart';
import 'screens/settings/signin.dart';
import 'screens/catalog/catalog.dart';
import 'screens/wrapper.dart';
import 'service/audiohandler.dart';
import 'shared/apptheme.dart';
import 'shared/helpers.dart';
import 'shared/notfound.dart';
import 'shared/settings.dart';

void main() async {
  // flutter
  WidgetsFlutterBinding.ensureInitialized();

  // get screen size
  final size = MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first)
      .size;
  initialWindowWidth = size.width;
  initialWindowHeight = size.height;
  isScreenWide = initialWindowWidth > 600;

  // firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // use emulator during debug
  if (useEmulator && kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // audio handler
  final CartaAudioHandler handler = await createAudioHandler();

  // application documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  appDocDirPath = appDocDir.path;

  // start app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ScreenConfig>(
            create: (context) => ScreenConfig()),
        ChangeNotifierProvider<CartaAuth>(create: (_) => CartaAuth()),
        // TODO: proxyprovider
        // update: return old with set auth
        ChangeNotifierProvider<CartaBloc>(
          create: (context) => CartaBloc(auth: context.read<CartaAuth>()),
        ),
        Provider<CartaAudioHandler>(
            create: (context) {
              handler.setLogic(context.read<CartaBloc>());
              return handler;
            },
            dispose: (_, __) => handler.dispose()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp(
        title: "Carta",
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name != null) {
            final uri = Uri.parse(settings.name!);
            // debugPrint('path: ${uri.path}');
            // debugPrint('params: ${uri.queryParameters}');
            if (uri.path == '/') {
              return MaterialPageRoute(builder: (context) => const Wrapper());
            } else if (uri.path == '/selected') {
              return MaterialPageRoute(
                builder: (context) => const CatalogPage(),
              );
            } else if (uri.path == '/login') {
              return MaterialPageRoute(
                builder: (context) => const SignInPage(),
              );
            } else if (uri.path == '/settings') {
              return MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              );
            }
          }
          return MaterialPageRoute(builder: (context) => const NotFound());
        },
        theme: AppTheme.lightTheme(lightDynamic),
        darkTheme: AppTheme.darkTheme(darkDynamic),
        // home: const Home(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

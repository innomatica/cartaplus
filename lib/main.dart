import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'logic/cartabloc.dart';
import 'logic/authprovider.dart';
import 'logic/screenconfig.dart';
import 'model/cartaplayer.dart';
import 'screens/catalog/catalog.dart';
import 'screens/wrapper.dart';
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

  // just audio
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    // check https://github.com/ryanheise/just_audio/issues/619
    androidNotificationIcon: 'drawable/app_icon',
  );

  // application documents directory
  final appDocDir = await getApplicationDocumentsDirectory();
  appDocDirPath = appDocDir.path;

  // start app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ScreenConfig>(
            create: (context) => ScreenConfig()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<CartaBloc>(
          create: (context) => CartaBloc(auth: context.read<AuthProvider>()),
        ),
        Provider<CartaPlayer>(
            create: (context) => CartaPlayer(bloc: context.read<CartaBloc>()),
            dispose: (_, player) => player.dispose()),
      ],
      child: DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: "Carta",
          initialRoute: '/',
          onGenerateRoute: (settings) {
            if (settings.name != null) {
              final uri = Uri.parse(settings.name!);
              debugPrint('path: ${uri.path}');
              debugPrint('params: ${uri.queryParameters}');

              if (uri.path == '/') {
                return MaterialPageRoute(builder: (context) => const Wrapper());
              } else if (uri.path == '/selected') {
                return MaterialPageRoute(
                  builder: (context) => const CatalogPage(),
                );
                // } else if (uri.path == '/newbook') {
                //   // this is for the deeplink now broken in Android 12
                //   final bookUrl = uri.queryParameters[0];
                //   return MaterialPageRoute(
                //     builder: (context) => BookSitePage(
                //       url: bookUrl,
                //     ),
                //   );
              }
            }
            return MaterialPageRoute(builder: (context) => const NotFound());
          },
          theme: AppTheme.lightTheme(lightDynamic),
          darkTheme: AppTheme.darkTheme(darkDynamic),
          // home: const Home(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}

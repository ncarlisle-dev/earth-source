import 'package:flutter/material.dart';
import './pages/login_page.dart';


void main() 
{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArchaeoSight 2.0',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:Color.fromARGB(255, 84, 122, 149),
          onPrimary: Color.fromARGB(255, 44, 57, 71),
          primary: Color.fromARGB(255, 232, 237, 242),
          primaryContainer: Color.fromARGB(255, 44, 57, 71),
          onPrimaryContainer: Color.fromARGB(255, 194, 165, 109),
          secondary:Color.fromARGB(255, 44, 57, 71),
          onSecondary: Color.fromARGB(255, 232, 237, 242),
          secondaryContainer: Color.fromARGB(255, 44, 57, 71),
          onSecondaryContainer: Color.fromARGB(255, 194, 165, 109),
          tertiary:Color.fromARGB(255, 44, 57, 71),
          onTertiary: Color.fromARGB(255, 232, 237, 242),
          tertiaryContainer: Color.fromARGB(255, 44, 57, 71),
          onTertiaryContainer: Color.fromARGB(255, 194, 165, 109),
          surfaceContainer: Color.fromARGB(255, 84, 122, 149),
          surface: Color.fromARGB(255, 232, 237, 242),
          onSurface: Color.fromARGB(255, 44, 57, 71),
          surfaceDim: Color.fromARGB(255, 84, 122, 149),
          surfaceBright: Color.fromARGB(255, 84, 122, 149),
          //surfaceContainerLowest: Color.fromARGB(255, 84, 122, 149),
          surfaceContainerLow: Color.fromARGB(255, 84, 122, 149),
          surfaceContainerHigh: Color.fromARGB(255, 84, 122, 149),
          surfaceContainerHighest: Color.fromARGB(255, 84, 122, 149),
          onSurfaceVariant: Color.fromARGB(255, 84, 122, 149),
        ),
      ),
      initialRoute: '/',

      routes: {
        '/': (_) => const LoginPage(),
      }
    );
  }
}

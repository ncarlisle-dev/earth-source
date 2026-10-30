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
          seedColor: Colors.deepPurple
        ),
      ),
      initialRoute: '/',

      routes: {
        '/': (_) => const LoginPage(),
      }
    );
  }
}

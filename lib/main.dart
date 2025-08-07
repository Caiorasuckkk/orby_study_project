import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'Screens/Menu/StudyPlan.dart';
import 'TelasIniciais/AnimationFirstScreen.dart';
import 'TelasIniciais/RegisterScreen.dart';
import 'TelasIniciais/login_screen.dart'; // ou OnboardingScreen, conforme seu fluxo

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // <- INICIALIZAÇÃO IMPORTANTE
  await dotenv.load(fileName: ".env" );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbyt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D1A2B)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroScreen(),
        '/studyplan': (context) => const StudyPlanScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sakubijak/auth/loginScreen.dart';
import 'package:sakubijak/auth/pinLoginScreen.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'package:sakubijak/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await SharedPrefHelper.getToken();
  final isPinSetup = await SharedPrefHelper.isPinSetup();

  runApp(MyApp(isLoggedIn: token != null, isPinSetup: isPinSetup));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool isPinSetup;

  const MyApp({required this.isLoggedIn, required this.isPinSetup});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (!isLoggedIn) {
      // Belum login sama sekali - tampilkan splash screen
      return SplashScreen();
    } else if (isLoggedIn && isPinSetup) {
      // Sudah login dan PIN sudah diset - gunakan PIN login
      return PinLoginScreen();
    } else {
      // Sudah login tapi PIN belum diset - gunakan email login
      // Ini seharusnya tidak terjadi karena PIN setup dilakukan setelah first login
      return LoginScreen();
    }
  }
}

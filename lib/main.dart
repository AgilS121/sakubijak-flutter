import 'package:flutter/material.dart';
import 'package:sakubijak/auth/loginScreen.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'package:sakubijak/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await SharedPrefHelper.getToken();

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? SplashScreen() : LoginScreen(),
    );
  }
}

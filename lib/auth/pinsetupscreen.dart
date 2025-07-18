import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'package:sakubijak/screens/mainNavigationScreen.dart';
import 'package:sakubijak/screens/admin/admin_navigation.dart';
import 'package:sakubijak/services/apiService.dart';

class PinSetupScreen extends StatefulWidget {
  final String userRole;

  const PinSetupScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _PinSetupScreenState createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final ApiService apiService = ApiService();
  bool _isLoading = false;

  void _setupPin() async {
    if (_pinController.text.length != 6) {
      _showError('PIN harus 6 digit');
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      _showError('PIN tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Set PIN via API
      final response = await apiService.setPin(_pinController.text);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Simpan PIN ke local storage juga untuk offline verification
        await SharedPrefHelper.savePin(_pinController.text);
        await SharedPrefHelper.setPinSetup(true);

        // Navigate ke halaman utama
        if (widget.userRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminNavigationScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainNavigationScreen()),
          );
        }
      } else {
        _showError(data['message'] ?? 'Gagal menyimpan PIN');
      }
    } catch (e) {
      // Fallback: simpan PIN hanya di local storage
      await SharedPrefHelper.savePin(_pinController.text);
      await SharedPrefHelper.setPinSetup(true);

      // Navigate ke halaman utama
      if (widget.userRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminNavigationScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainNavigationScreen()),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00BFA5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Buat PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      Text(
                        'Buat PIN 6 digit untuk login cepat',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 30),

                      // PIN Input
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'PIN (6 digit)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF0F8F0),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Confirm PIN Input
                      TextField(
                        controller: _confirmPinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi PIN',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF0F8F0),
                        ),
                      ),
                      SizedBox(height: 40),

                      // Setup PIN Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _setupPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00BFA5),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                  'Buat PIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

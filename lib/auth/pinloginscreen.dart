import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'package:sakubijak/screens/mainNavigationScreen.dart';
import 'package:sakubijak/screens/admin/admin_navigation.dart';
import 'package:sakubijak/auth/loginScreen.dart';
import 'package:sakubijak/services/apiService.dart';

class PinLoginScreen extends StatefulWidget {
  @override
  _PinLoginScreenState createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  bool _isLoading = false;
  final ApiService apiService = ApiService();

  void _addNumber(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
      });

      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _removeNumber() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail =
          await SharedPrefHelper.getUserEmail(); // Perlu tambah fungsi ini

      if (userEmail != null) {
        // Verifikasi PIN via API
        final response = await apiService.loginWithPin(userEmail, _pin);
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['status'] == true) {
          // Update token baru
          final token = data['token'];
          final userRole = data['user']['role'];

          await SharedPrefHelper.saveToken(token);
          await SharedPrefHelper.saveUserRole(userRole);
          apiService.setToken(token);

          // Navigate ke halaman utama
          if (userRole == 'admin') {
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
          // API failed, fallback to local verification
          await _verifyPinLocally();
        }
      } else {
        // No email stored, fallback to local verification
        await _verifyPinLocally();
      }
    } catch (e) {
      // Network error, fallback to local verification
      await _verifyPinLocally();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _verifyPinLocally() async {
    try {
      final savedPin = await SharedPrefHelper.getPin();
      final userRole = await SharedPrefHelper.getUserRole();

      if (savedPin == _pin) {
        // PIN benar, navigasi ke halaman utama
        if (userRole == 'admin') {
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
        // PIN salah
        setState(() {
          _pin = '';
        });
        _showError('PIN salah');
      }
    } catch (e) {
      _showError('Terjadi kesalahan');
    }
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

  void _useEmailLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
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
                'Masukkan PIN',
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
                child: Column(
                  children: [
                    SizedBox(height: 60),

                    // PIN Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                index < _pin.length
                                    ? Color(0xFF00BFA5)
                                    : Colors.grey[300],
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 60),

                    // Number Pad
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 60),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          if (index == 9) {
                            return SizedBox(); // Empty space
                          } else if (index == 10) {
                            return _buildNumberButton('0');
                          } else if (index == 11) {
                            return _buildActionButton(
                              icon: Icons.backspace,
                              onPressed: _removeNumber,
                            );
                          } else {
                            return _buildNumberButton((index + 1).toString());
                          }
                        },
                      ),
                    ),

                    // Use Email Login Button
                    TextButton(
                      onPressed: _useEmailLogin,
                      child: Text(
                        'Gunakan Email/Password',
                        style: TextStyle(
                          color: Color(0xFF00BFA5),
                          fontSize: 16,
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _addNumber(number),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF0F8F0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF0F8F0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(child: Icon(icon, size: 24, color: Colors.grey[800])),
      ),
    );
  }
}

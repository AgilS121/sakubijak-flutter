import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Loading states
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // First, try to load from passed userData
      if (widget.userData != null) {
        _namaController.text =
            widget.userData!['nama'] ?? widget.userData!['name'] ?? '';
        _emailController.text = widget.userData!['email'] ?? '';
      }

      // Then, fetch fresh data from API
      await _apiService.loadToken();
      final response = await _apiService.getProfile();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userData = responseData['user'];

        setState(() {
          _namaController.text = userData['nama'] ?? userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _isLoadingProfile = false;
        });
      } else {
        // If API fails, try to load from SharedPreferences
        final userData = await SharedPrefHelper.getUserData();
        if (userData != null) {
          setState(() {
            _namaController.text = userData['nama'] ?? userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      // Fallback to SharedPreferences if API fails
      try {
        final userData = await SharedPrefHelper.getUserData();
        if (userData != null) {
          setState(() {
            _namaController.text = userData['nama'] ?? userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.loadToken();

      // Prepare data to update
      Map<String, dynamic> updateData = {
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Add password if provided
      if (_currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        updateData['current_password'] = _currentPasswordController.text;
        updateData['password'] = _newPasswordController.text;
      }

      // Call API to update profile
      final response = await _apiService.updateProfile(updateData);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Update stored user data
        await SharedPrefHelper.saveUserData(responseData['user']);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen with success flag
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Gagal memperbarui profile');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Buang Perubahan?'),
            content: const Text(
              'Perubahan yang belum disimpan akan hilang. Yakin ingin keluar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to profile
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
  }

  bool _hasChanges() {
    return _namaController.text !=
            (widget.userData?['nama'] ?? widget.userData?['name'] ?? '') ||
        _emailController.text != (widget.userData?['email'] ?? '') ||
        _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges()) {
          _showDiscardDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: const Color(0xFF00D4AA),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: Text(
                'Simpan',
                style: TextStyle(
                  color: _isLoading ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body:
            _isLoadingProfile
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
                )
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Avatar Section
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00D4AA),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      widget.userData?['avatar'] != null
                                          ? Image.network(
                                            widget.userData!['avatar'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return _buildDefaultAvatar();
                                            },
                                          )
                                          : _buildDefaultAvatar(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    // TODO: Implement image picker
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Fitur ganti foto akan segera tersedia',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00D4AA),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Personal Information Section
                        _buildSectionTitle('Informasi Pribadi'),
                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _namaController,
                          label: 'Nama Lengkap',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            if (value.length < 2) {
                              return 'Nama minimal 2 karakter';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Password Section
                        _buildSectionTitle('Ganti Password (Opsional)'),
                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _currentPasswordController,
                          label: 'Password Saat Ini',
                          icon: Icons.lock,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (_newPasswordController.text.isNotEmpty &&
                                (value == null || value.isEmpty)) {
                              return 'Password saat ini diperlukan untuk mengubah password';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _newPasswordController,
                          label: 'Password Baru',
                          icon: Icons.lock_outline,
                          obscureText: !_isNewPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (_currentPasswordController.text.isNotEmpty) {
                              if (value == null || value.isEmpty) {
                                return 'Password baru tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildTextFormField(
                          controller: _confirmPasswordController,
                          label: 'Konfirmasi Password Baru',
                          icon: Icons.lock_outline,
                          obscureText: !_isConfirmPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (_newPasswordController.text.isNotEmpty) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Password tidak cocok';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4AA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00D4AA)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

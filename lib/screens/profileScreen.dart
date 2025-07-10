import 'package:flutter/material.dart';
import 'package:sakubijak/auth/loginScreen.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'dart:convert';

import 'package:sakubijak/services/apiService.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _userName = 'Loading...';
  String _userEmail = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await _apiService.loadToken();

      // Load user data from SharedPreferences
      final userData = await SharedPrefHelper.getUserData();

      if (userData != null) {
        setState(() {
          _userData = userData;
          _userName = userData['nama'] ?? userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
          _userId = userData['id']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        // Fallback: try to get from any available endpoint
        // Since there's no user profile endpoint, we'll use stored data
        setState(() {
          _userName = 'User';
          _userEmail = '';
          _userId = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'User';
        _userEmail = '';
        _userId = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call logout API
      await _apiService.loadToken();
      final response = await _apiService.logout();

      // Close loading dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        // Clear stored data
        await SharedPrefHelper.clearUserData();

        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil logout'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Even if API fails, clear local data and logout
        await SharedPrefHelper.clearUserData();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout berhasil'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Force logout even if API fails
      await SharedPrefHelper.clearUserData();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editProfile() {
    // Navigate to edit profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh profile data if edited
        _loadUserData();
      }
    });
  }

  void _openSecurity() {
    // Navigate to security settings
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SecurityScreen()),
    );
  }

  void _openSettings() {
    // Navigate to app settings
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00D4AA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00D4AA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadUserData();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('About'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child:
                  _userData?['avatar'] != null
                      ? Image.network(
                        _userData!['avatar'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar();
                        },
                      )
                      : _buildDefaultAvatar(),
            ),
          ),
          const SizedBox(height: 16),

          // User Name
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                _userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

          // User Email
          if (_userEmail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _userEmail,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

          // User ID
          if (_userId.isNotEmpty)
            Text(
              'ID: $_userId',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),

          const SizedBox(height: 20),

          // Menu List
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileMenuItem(
                    icon: Icons.edit,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Edit Profile',
                    subtitle: 'Ubah informasi profil Anda',
                    onTap: _editProfile,
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.security,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Keamanan',
                    subtitle: 'Ubah password dan PIN',
                    onTap: _openSecurity,
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.settings,
                    iconColor: const Color(0xFF6B7280),
                    title: 'Pengaturan',
                    subtitle: 'Preferensi aplikasi',
                    onTap: _openSettings,
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF10B981),
                    title: 'Bantuan',
                    subtitle: 'FAQ dan dukungan',
                    onTap: () {
                      // Show help dialog or navigate to help page
                      _showHelpDialog();
                    },
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.logout,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Keluar',
                    subtitle: 'Logout dari aplikasi',
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tentang Aplikasi'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SakuBijak - Aplikasi Keuangan Pribadi'),
                SizedBox(height: 8),
                Text('Versi: 1.0.0'),
                SizedBox(height: 8),
                Text('Kelola keuangan pribadi dengan mudah dan bijak'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bantuan'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Butuh bantuan?'),
                SizedBox(height: 8),
                Text('• Email: support@sakubijak.com'),
                Text('• WhatsApp: +62 812 3456 7890'),
                Text('• Website: www.sakubijak.com'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

// Placeholder screens for navigation
class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({Key? key, this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Edit Profile Page - Coming Soon')),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keamanan'),
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Security Settings Page - Coming Soon')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Settings Page - Coming Soon')),
    );
  }
}

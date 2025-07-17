// admin_settings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers sesuai dengan response API sistem
  final _logoController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kontakResmiController = TextEditingController();
  final _alamatAplikasiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _deskripsiController.dispose();
    _kontakResmiController.dispose();
    _alamatAplikasiController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.getSistem();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // Sesuaikan dengan struktur response API
          _settings = data['data'] ?? {};
          _populateControllers();
          _isLoading = false;
        });
      } else {
        _showErrorMessage('Error loading settings: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorMessage('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    // Sesuaikan dengan field yang ada di controller Laravel
    _logoController.text = _settings['logo'] ?? '';
    _deskripsiController.text = _settings['deskripsi'] ?? '';
    _kontakResmiController.text = _settings['kontak_resmi'] ?? '';
    _alamatAplikasiController.text = _settings['alamat_aplikasi'] ?? '';
  }

  Future<void> _saveSettings() async {
    // Validasi input
    if (_logoController.text.isEmpty ||
        _deskripsiController.text.isEmpty ||
        _kontakResmiController.text.isEmpty ||
        _alamatAplikasiController.text.isEmpty) {
      _showErrorMessage('Semua field harus diisi');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.updateSistem(
        _logoController.text,
        _deskripsiController.text,
        _kontakResmiController.text,
        _alamatAplikasiController.text,
      );

      if (response.statusCode == 200) {
        _showSuccessMessage('Pengaturan berhasil disimpan');
        _loadSettings(); // Reload data
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorMessage(errorData['message'] ?? 'Gagal menyimpan pengaturan');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Sistem'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadSettings),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Information Section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Sistem',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _logoController,
                              decoration: InputDecoration(
                                labelText: 'Logo',
                                hintText: 'Masukkan URL atau path logo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.image),
                              ),
                              maxLines: 1,
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _deskripsiController,
                              decoration: InputDecoration(
                                labelText: 'Deskripsi',
                                hintText: 'Masukkan deskripsi aplikasi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _kontakResmiController,
                              decoration: InputDecoration(
                                labelText: 'Kontak Resmi',
                                hintText: 'Masukkan kontak resmi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.contact_phone),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _alamatAplikasiController,
                              decoration: InputDecoration(
                                labelText: 'Alamat Aplikasi',
                                hintText: 'Masukkan alamat web aplikasi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.web),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isSaving
                                    ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Menyimpan...'),
                                      ],
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save),
                                        SizedBox(width: 8),
                                        Text('Simpan Pengaturan'),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Reset Button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _resetForm,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restore),
                                SizedBox(width: 8),
                                Text('Reset Form'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Information Card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Informasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pengaturan ini akan mempengaruhi tampilan dan informasi yang ditampilkan di seluruh aplikasi. Pastikan semua informasi yang dimasukkan sudah benar.',
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  void _resetForm() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reset Form'),
            content: Text('Apakah Anda yakin ingin mereset semua perubahan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _populateControllers(); // Reset ke data asli
                  _showSuccessMessage('Form berhasil direset');
                },
                child: Text('Reset'),
              ),
            ],
          ),
    );
  }
}

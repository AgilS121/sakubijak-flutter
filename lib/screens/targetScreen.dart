import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakubijak/services/apiService.dart';

class TargetScreen extends StatefulWidget {
  @override
  _TargetScreenState createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;
  double _saldoSaatIni = 0.0;
  double _totalPengeluaran = 0.0;
  List<Map<String, dynamic>> _existingTargets = [];
  DateTime _selectedDate = DateTime.now().add(Duration(days: 30));
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
    // Tambahkan delay untuk memastikan widget sudah ter-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoadingData = true;
        _errorMessage = '';
      });

      final api = ApiService();
      await api.loadToken();

      // Load transactions dengan error handling yang lebih baik
      try {
        final transactionResponse = await api.getTransaksi();
        double saldo = 0.0;
        double pengeluaran = 0.0;

        if (transactionResponse.statusCode == 200) {
          final transactionData = jsonDecode(transactionResponse.body);
          List<dynamic> transaksi = [];

          if (transactionData is Map<String, dynamic>) {
            transaksi = transactionData['data'] ?? [];
          } else if (transactionData is List) {
            transaksi = transactionData;
          }

          for (var tx in transaksi) {
            try {
              final kategori = tx['kategori'] as Map<String, dynamic>? ?? {};

              double jumlah = 0.0;
              if (tx['jumlah'] is String) {
                jumlah = double.tryParse(tx['jumlah'] as String) ?? 0.0;
              } else if (tx['jumlah'] is num) {
                jumlah = (tx['jumlah'] as num).toDouble();
              }

              bool isPemasukan = kategori['jenis'] == 'pemasukan';
              saldo += isPemasukan ? jumlah : -jumlah;
              if (!isPemasukan) {
                pengeluaran += jumlah;
              }
            } catch (e) {
              print('Error processing transaction: $e');
            }
          }
        }

        // Update saldo
        if (mounted) {
          setState(() {
            _saldoSaatIni = saldo;
            _totalPengeluaran = pengeluaran;
          });
        }
      } catch (e) {
        print('Error loading transactions: $e');
        // Lanjutkan tanpa crash
      }

      // Load existing targets dengan error handling
      try {
        final targetResponse = await api.getTujuan();
        List<Map<String, dynamic>> targets = [];

        if (targetResponse.statusCode == 200) {
          final targetData = jsonDecode(targetResponse.body);

          if (targetData is Map<String, dynamic>) {
            targets = List<Map<String, dynamic>>.from(targetData['data'] ?? []);
          } else if (targetData is List) {
            targets = List<Map<String, dynamic>>.from(targetData);
          }
        }

        if (mounted) {
          setState(() {
            _existingTargets = targets;
          });
        }
      } catch (e) {
        print('Error loading targets: $e');
        // Lanjutkan tanpa crash
      }

      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error in _loadData: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _errorMessage = 'Terjadi kesalahan saat memuat data';
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 365 * 5)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF00BFA5),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
          _dateController.text = _formatDate(picked);
        });
      }
    } catch (e) {
      print('Error selecting date: $e');
    }
  }

  Future<void> _saveTarget() async {
    if (_targetController.text.trim().isEmpty) {
      _showSnackBar('Nama target tidak boleh kosong');
      return;
    }

    if (_nominalController.text.trim().isEmpty) {
      _showSnackBar('Nominal target tidak boleh kosong');
      return;
    }

    final nominalText = _nominalController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final nominal = int.tryParse(nominalText);

    if (nominal == null || nominal <= 0) {
      _showSnackBar('Nominal target harus berupa angka yang valid');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService();
      await api.loadToken();

      final response = await api.createTujuan(
        _targetController.text.trim(),
        nominal,
        0, // uang terkumpul awal = 0
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar('Target berhasil ditambahkan!', isSuccess: true);
        await _loadData(); // Refresh data target & saldo
        _targetController.clear();
        _nominalController.clear();
        _deskripsiController.clear();
        _dateController.text = _formatDate(
          DateTime.now().add(Duration(days: 30)),
        );
        _selectedDate = DateTime.now().add(Duration(days: 30));
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal menambahkan target';

        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }

        _showSnackBar(errorMessage);
      }
    } catch (e) {
      print('Error saving target: $e');
      _showSnackBar('Terjadi kesalahan saat menyimpan target');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildTargetField(
    String label,
    String hint, {
    TextEditingController? controller,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF00BFA5),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 50,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF00BFA5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              suffixIcon:
                  onTap != null
                      ? Icon(Icons.calendar_today, color: Colors.grey[400])
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingTargets() {
    if (_existingTargets.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Keuangan Aktif',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF00BFA5),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingTargets.length,
            itemBuilder: (context, index) {
              final target = _existingTargets[index];
              final targetUang =
                  double.tryParse(target['target_uang'].toString()) ?? 0.0;
              final uangTerkumpul =
                  double.tryParse(target['uang_terkumpul'].toString()) ?? 0.0;
              final progress =
                  targetUang > 0 ? (uangTerkumpul / targetUang) : 0.0;

              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 15),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF00BFA5).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target['judul'] ?? 'Target',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Rp ${_formatCurrency(targetUang)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00BFA5),
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BFA5),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% tercapai',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00BFA5),
      body: SafeArea(
        child:
            _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : Column(
                  children: [
                    // Header
                    _buildHeader(),
                    // Balance Display
                    _buildBalanceDisplay(),
                    SizedBox(height: 30),
                    // Content
                    _buildContent(),
                  ],
                ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.white),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF00BFA5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          SizedBox(width: 15),
          Text(
            'Target Keuangan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child:
          _isLoadingData
              ? Container(
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Saat Ini',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_saldoSaatIni)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pengeluaran',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_totalPengeluaran)}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child:
            _isLoadingData
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00BFA5),
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      _buildExistingTargets(),
                      Text(
                        'Tambah Target Baru',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF00BFA5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTargetField(
                        'Tanggal Target',
                        'Pilih tanggal target',
                        controller: _dateController,
                        readOnly: true,
                        onTap: _selectDate,
                      ),
                      SizedBox(height: 15),
                      _buildTargetField(
                        'Target',
                        'Masukkan nama target',
                        controller: _targetController,
                      ),
                      SizedBox(height: 15),
                      _buildTargetField(
                        'Nominal',
                        'Rp 0',
                        controller: _nominalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) return newValue;
                            final number = int.tryParse(newValue.text) ?? 0;
                            final formatted = _formatCurrency(
                              number.toDouble(),
                            );
                            return TextEditingValue(
                              text: 'Rp $formatted',
                              selection: TextSelection.collapsed(
                                offset: formatted.length + 3,
                              ),
                            );
                          }),
                        ],
                      ),
                      SizedBox(height: 15),
                      _buildDescriptionField(),
                      SizedBox(height: 30),
                      _buildSubmitButton(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi (Opsional)',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF00BFA5),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 100,
          child: TextField(
            controller: _deskripsiController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Masukkan deskripsi target...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF00BFA5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveTarget,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00BFA5),
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 0,
      ),
      child:
          _isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
              : Text(
                'Tambah Target',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _nominalController.dispose();
    _deskripsiController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}

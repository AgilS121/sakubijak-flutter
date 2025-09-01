import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakubijak/screens/tambahtabungan.dart';
import 'package:sakubijak/services/apiService.dart';

class TargetScreen extends StatefulWidget {
  @override
  _TargetScreenState createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _targetUangController = TextEditingController();
  final TextEditingController _uangAwalController = TextEditingController();
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
    // Set nilai awal untuk uang terkumpul
    _uangAwalController.text = 'Rp 0';

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

  double _parseCurrency(String text) {
    // Menghapus "Rp", spasi, dan titik dari teks
    final cleanText = text.replaceAll(RegExp(r'[Rp\s\.]'), '');
    return double.tryParse(cleanText) ?? 0.0;
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
    // Validasi judul tujuan
    if (_judulController.text.trim().isEmpty) {
      _showSnackBar('Judul tujuan tidak boleh kosong');
      return;
    }

    // Validasi target uang
    if (_targetUangController.text.trim().isEmpty) {
      _showSnackBar('Target uang tidak boleh kosong');
      return;
    }

    final targetUang = _parseCurrency(_targetUangController.text);
    if (targetUang <= 0) {
      _showSnackBar('Target uang harus lebih dari 0');
      return;
    }

    // Validasi uang awal (opsional, default 0)
    final uangAwal = _parseCurrency(_uangAwalController.text);
    if (uangAwal < 0) {
      _showSnackBar('Uang awal tidak boleh negatif');
      return;
    }

    // Validasi uang awal tidak boleh lebih dari target
    if (uangAwal > targetUang) {
      _showSnackBar('Uang awal tidak boleh lebih dari target');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService();
      await api.loadToken();

      final response = await api.createTujuan(
        _judulController.text.trim(),
        targetUang.toInt(),
        uangAwal.toInt(), // Menggunakan uang awal yang diinput user
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackBar(
          'Tujuan finansial berhasil ditambahkan!',
          isSuccess: true,
        );
        await _loadData(); // Refresh data target & saldo

        // Reset form
        _judulController.clear();
        _targetUangController.clear();
        _uangAwalController.text = 'Rp 0';
        _deskripsiController.clear();
        _dateController.text = _formatDate(
          DateTime.now().add(Duration(days: 30)),
        );
        _selectedDate = DateTime.now().add(Duration(days: 30));
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal menambahkan tujuan finansial';

        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }

        _showSnackBar(errorMessage);
      }
    } catch (e) {
      print('Error saving target: $e');
      _showSnackBar('Terjadi kesalahan saat menyimpan tujuan finansial');
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
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
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

  void _showTambahTabunganDialog(Map<String, dynamic> target) {
    showDialog(
      context: context,
      builder:
          (context) => TambahTabunganDialog(
            tujuan: target,
            onSuccess: () {
              _loadData(); // Refresh data setelah berhasil
            },
          ),
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
          'Tujuan Finansial Aktif',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF00BFA5),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 320, // Diperbesar untuk menampung riwayat terakhir
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
              final isCompleted = progress >= 1.0;

              // Parse tanggal target
              String tanggalTarget = 'Belum ditentukan';
              if (target['tanggal_target'] != null) {
                try {
                  final DateTime targetDate = DateTime.parse(
                    target['tanggal_target'],
                  );
                  tanggalTarget = _formatDate(targetDate);
                } catch (e) {
                  tanggalTarget = target['tanggal_target'].toString();
                }
              }

              // Ambil riwayat tabungan
              List<dynamic> riwayatTabungan = target['riwayat_tabungan'] ?? [];

              // Ambil riwayat terakhir
              Map<String, dynamic>? riwayatTerakhir;
              if (riwayatTabungan.isNotEmpty) {
                riwayatTerakhir = riwayatTabungan.last;
              }

              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 15),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isCompleted ? Color(0xFFE8F5E8) : Color(0xFFF0F8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isCompleted
                            ? Color(0xFF4CAF50).withOpacity(0.5)
                            : Color(0xFF00BFA5).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            target['judul'] ?? 'Tujuan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Tanggal Target
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF00BFA5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Color(0xFF00BFA5),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Target: $tanggalTarget',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF00BFA5),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),

                    Text(
                      'Target: Rp ${_formatCurrency(targetUang)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      'Terkumpul: Rp ${_formatCurrency(uangTerkumpul)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isCompleted ? Color(0xFF4CAF50) : Color(0xFF00BFA5),
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Color(0xFF4CAF50) : Color(0xFF00BFA5),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      isCompleted
                          ? 'Target tercapai!'
                          : '${(progress * 100).toStringAsFixed(1)}% tercapai',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isCompleted ? Color(0xFF4CAF50) : Colors.grey[600],
                        fontWeight:
                            isCompleted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Riwayat Tabungan
                    if (riwayatTabungan.isNotEmpty) ...[
                      Text(
                        'Riwayat Tabungan:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        height: 60, // Tinggi untuk menampilkan 2-3 item riwayat
                        child: ListView.builder(
                          itemCount:
                              riwayatTabungan.length > 3
                                  ? 3
                                  : riwayatTabungan.length,
                          itemBuilder: (context, idx) {
                            final riwayat = riwayatTabungan[idx];
                            final jumlah =
                                double.tryParse(riwayat['jumlah'].toString()) ??
                                0.0;

                            String tanggal = '';
                            if (riwayat['tanggal'] != null) {
                              try {
                                final DateTime date = DateTime.parse(
                                  riwayat['tanggal'],
                                );
                                tanggal =
                                    '${date.day}/${date.month}/${date.year}';
                              } catch (e) {
                                tanggal = riwayat['tanggal']
                                    .toString()
                                    .substring(0, 10);
                              }
                            }

                            return Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle,
                                    size: 10,
                                    color: Color(0xFF00BFA5),
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$tanggal: +Rp ${_formatCurrency(jumlah)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (riwayatTabungan.length > 3)
                        Text(
                          '+ ${riwayatTabungan.length - 3} lainnya',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      SizedBox(height: 8),
                    ],

                    // Button Tambah Tabungan
                    if (!isCompleted)
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => _showTambahTabunganDialog(target),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFA5),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            shadowColor: Color(0xFF00BFA5).withOpacity(0.3),
                          ),
                          child: Text(
                            'Tambah Tabungan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // Riwayat Tambah Tabungan Terakhir
                    if (!isCompleted && riwayatTerakhir != null) ...[
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF00BFA5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFF00BFA5).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 12,
                                  color: Color(0xFF00BFA5),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tabungan Terakhir:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00BFA5),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    () {
                                      final jumlah =
                                          double.tryParse(
                                            riwayatTerakhir!['jumlah']
                                                .toString(),
                                          ) ??
                                          0.0;
                                      String tanggal = '';
                                      if (riwayatTerakhir['tanggal'] != null) {
                                        try {
                                          final DateTime date = DateTime.parse(
                                            riwayatTerakhir['tanggal'],
                                          );
                                          tanggal =
                                              '${date.day}/${date.month}/${date.year}';
                                        } catch (e) {
                                          tanggal = riwayatTerakhir['tanggal']
                                              .toString()
                                              .substring(0, 10);
                                        }
                                      }
                                      return '+Rp ${_formatCurrency(jumlah)} ($tanggal)';
                                    }(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (riwayatTerakhir!['keterangan'] != null &&
                                riwayatTerakhir!['keterangan']
                                    .toString()
                                    .isNotEmpty) ...[
                              SizedBox(height: 2),
                              Text(
                                'Ket: ${riwayatTerakhir!['keterangan']}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF00BFA5),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Coba Lagi',
              style: TextStyle(fontWeight: FontWeight.w600),
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
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          SizedBox(width: 15),
          Text(
            'Tujuan Finansial',
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
            child: Icon(Icons.savings_outlined, color: Colors.white),
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
                        'Tambah Tujuan Finansial Baru',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF00BFA5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTargetField(
                        'Judul Tujuan',
                        'Contoh: Beli Laptop, Liburan ke Bali',
                        controller: _judulController,
                        isRequired: true,
                      ),
                      SizedBox(height: 15),
                      _buildTargetField(
                        'Target Uang',
                        'Rp 0',
                        controller: _targetUangController,
                        keyboardType: TextInputType.number,
                        isRequired: true,
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
                      _buildTargetField(
                        'Uang Awal Terkumpul',
                        'Rp 0',
                        controller: _uangAwalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            if (newValue.text.isEmpty) {
                              return TextEditingValue(
                                text: 'Rp 0',
                                selection: TextSelection.collapsed(offset: 3),
                              );
                            }
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
                      _buildTargetField(
                        'Tanggal Target',
                        'Pilih tanggal target pencapaian',
                        controller: _dateController,
                        readOnly: true,
                        onTap: _selectDate,
                        isRequired: true,
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
              hintText:
                  'Masukkan deskripsi atau alasan tujuan finansial ini...',
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
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTarget,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF00BFA5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF00BFA5).withOpacity(0.6),
          disabledForegroundColor: Colors.white.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
          shadowColor: Color(0xFF00BFA5).withOpacity(0.3),
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
                  'Tambah Tujuan Finansial',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _targetUangController.dispose();
    _uangAwalController.dispose();
    _deskripsiController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}

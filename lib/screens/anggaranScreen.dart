import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sakubijak/services/apiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetPage extends StatefulWidget {
  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Map<String, dynamic>> _anggaranList = [];
  List<dynamic> _kategoriPengeluaran = [];
  bool _isLoading = true;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  // Set untuk menyimpan ID anggaran yang sudah digunakan
  Set<String> _usedAnggaranIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsedAnggaran();
    _loadData();
  }

  // Menyimpan anggaran yang sudah digunakan ke SharedPreferences
  Future<void> _saveUsedAnggaran(String anggaranId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usedList = prefs.getStringList('used_anggaran_ids') ?? [];
    if (!usedList.contains(anggaranId)) {
      usedList.add(anggaranId);
      await prefs.setStringList('used_anggaran_ids', usedList);
    }
  }

  // Memuat anggaran yang sudah digunakan dari SharedPreferences
  Future<void> _loadUsedAnggaran() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usedList = prefs.getStringList('used_anggaran_ids') ?? [];
    setState(() {
      _usedAnggaranIds = usedList.toSet();
    });
  }

  // Menghapus anggaran dari daftar yang sudah digunakan
  Future<void> _removeUsedAnggaran(String anggaranId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usedList = prefs.getStringList('used_anggaran_ids') ?? [];
    usedList.remove(anggaranId);
    await prefs.setStringList('used_anggaran_ids', usedList);
    setState(() {
      _usedAnggaranIds.remove(anggaranId);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final api = ApiService();
    await api.loadToken();

    try {
      // Load kategori terlebih dahulu
      await _loadKategoriPengeluaran(api);
      // Kemudian load anggaran
      await _loadAnggaran(api);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnggaran(ApiService api) async {
    try {
      final response = await api.getAnggaran();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Map<String, dynamic>> anggaranList = [];
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          anggaranList = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          anggaranList = List<Map<String, dynamic>>.from(data);
        }

        setState(() {
          _anggaranList = anggaranList;
        });
      }
    } catch (e) {
      print('Error loading anggaran: $e');
    }
  }

  Future<void> _loadKategoriPengeluaran(ApiService api) async {
    try {
      final response = await api.getKategori();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List kategori = [];
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is List) {
            kategori = data['data'] as List;
          }
        } else if (data is List) {
          kategori = data;
        }

        final kategoriPengeluaran =
            kategori
                .where(
                  (e) =>
                      e != null &&
                      e is Map<String, dynamic> &&
                      e['jenis'] == 'pengeluaran',
                )
                .toList();

        setState(() {
          _kategoriPengeluaran = kategoriPengeluaran;
        });
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }

  // ==========================
  // ADD DIALOG (with tanggal)
  // ==========================
  void _showAddAnggaranDialog() {
    if (_kategoriPengeluaran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada kategori pengeluaran yang tersedia')),
      );
      return;
    }

    String? selectedKategoriId;
    final TextEditingController batasController = TextEditingController();
    final TextEditingController tanggalController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    int selectedMonth = _currentMonth;
    int selectedYear = _currentYear;

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Tambah Anggaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kategori Pengeluaran',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedKategoriId,
                      hint: Text('Pilih Kategori'),
                      items:
                          _kategoriPengeluaran.isEmpty
                              ? [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Tidak ada kategori pengeluaran'),
                                ),
                              ]
                              : _kategoriPengeluaran
                                  .map<DropdownMenuItem<String>>((kategori) {
                                    return DropdownMenuItem<String>(
                                      value: kategori['id']?.toString(),
                                      child: Text(
                                        kategori['nama_kategori']?.toString() ??
                                            'Kategori',
                                      ),
                                    );
                                  })
                                  .toList(),
                      onChanged:
                          _kategoriPengeluaran.isEmpty
                              ? null
                              : (String? value) {
                                setDialogState(() {
                                  selectedKategoriId = value;
                                });
                              },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: batasController,
                      decoration: InputDecoration(
                        labelText: 'Batas Pengeluaran (Rp)',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    // Tanggal Anggaran (string)
                    TextFormField(
                      controller: tanggalController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Anggaran',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: pickDate,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Bulan',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedMonth,
                            items: List.generate(12, (index) {
                              int month = index + 1;
                              return DropdownMenuItem<int>(
                                value: month,
                                child: Text(_getMonthName(month)),
                              );
                            }),
                            onChanged: (int? value) {
                              setDialogState(() {
                                selectedMonth = value ?? _currentMonth;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Tahun',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedYear,
                            items: List.generate(5, (index) {
                              int year = DateTime.now().year + index;
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (int? value) {
                              setDialogState(() {
                                selectedYear = value ?? _currentYear;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedKategoriId != null &&
                        batasController.text.isNotEmpty &&
                        _kategoriPengeluaran.isNotEmpty) {
                      await _addAnggaran(
                        selectedKategoriId!,
                        double.tryParse(
                              batasController.text
                                      .replaceAll('.', '')
                                      .replaceAll(',', '') ??
                                  '',
                            ) ??
                            0,
                        selectedMonth,
                        selectedYear,
                        tanggalController.text, // <-- kirim tanggal
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mohon lengkapi semua field')),
                      );
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addAnggaran(
    String idKategori,
    double batasPengeluaran,
    int bulan,
    int tahun,
    String tanggalAnggaran,
  ) async {
    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.createAnggaran({
        'id_kategori': idKategori,
        'batas_pengeluaran': batasPengeluaran,
        'bulan': bulan,
        'tahun': tahun,
        'tanggal_anggaran': tanggalAnggaran, // <-- kirim tanggal
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anggaran berhasil ditambahkan')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambahkan anggaran')));
      }
    } catch (e) {
      print('Error adding anggaran: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteAnggaran(String id) async {
    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.deleteAnggaran(id);

      if (response.statusCode == 200) {
        await _removeUsedAnggaran(id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Anggaran berhasil dihapus')));
        _loadData();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus anggaran')));
      }
    } catch (e) {
      print('Error deleting anggaran: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _useAnggaran(
    String anggaranId,
    double amount,
    String kategoriNama,
    String kategoriId,
  ) async {
    try {
      final api = ApiService();
      await api.loadToken();

      final response = await api.createTransaksi(
        int.parse(kategoriId),
        amount.toInt(),
        'Penggunaan anggaran: $kategoriNama',
        DateTime.now().toIso8601String().split('T')[0],
      );

      if (response.statusCode == 201) {
        await _saveUsedAnggaran(anggaranId);
        setState(() {
          _usedAnggaranIds.add(anggaranId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Anggaran telah digunakan dan saldo dikurangi Rp ${_formatCurrency(amount)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('API Response: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menggunakan anggaran: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error using anggaran: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================
  // EDIT DIALOG (with tanggal)
  // ==========================
  void _showEditAnggaranDialog(Map<String, dynamic> anggaran) {
    final kategori = anggaran['kategori'] as Map<String, dynamic>? ?? {};
    String? selectedKategoriId = kategori['id']?.toString();

    final TextEditingController batasController = TextEditingController(
      text: (anggaran['batas_pengeluaran'] ?? '').toString(),
    );

    final String initialTanggal =
        (anggaran['tanggal_anggaran'] ??
                DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .toString();

    final TextEditingController tanggalController = TextEditingController(
      text: initialTanggal,
    );

    int selectedMonth = (anggaran['bulan'] ?? _currentMonth) as int;
    int selectedYear = (anggaran['tahun'] ?? _currentYear) as int;

    Future<void> pickDate() async {
      DateTime base;
      try {
        base = DateTime.parse(tanggalController.text);
      } catch (_) {
        base = DateTime.now();
      }
      final picked = await showDatePicker(
        context: context,
        initialDate: base,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Ubah Anggaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kategori Pengeluaran',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedKategoriId,
                      hint: Text('Pilih Kategori'),
                      items:
                          _kategoriPengeluaran.map<DropdownMenuItem<String>>((
                            kategori,
                          ) {
                            return DropdownMenuItem<String>(
                              value: kategori['id']?.toString(),
                              child: Text(
                                kategori['nama_kategori']?.toString() ??
                                    'Kategori',
                              ),
                            );
                          }).toList(),
                      onChanged: (String? value) {
                        setDialogState(() {
                          selectedKategoriId = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: batasController,
                      decoration: InputDecoration(
                        labelText: 'Batas Pengeluaran (Rp)',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: tanggalController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Anggaran',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: pickDate,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Bulan',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedMonth,
                            items: List.generate(12, (index) {
                              int month = index + 1;
                              return DropdownMenuItem<int>(
                                value: month,
                                child: Text(_getMonthName(month)),
                              );
                            }),
                            onChanged: (int? value) {
                              setDialogState(() {
                                selectedMonth = value ?? _currentMonth;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Tahun',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedYear,
                            items: List.generate(5, (index) {
                              int year = DateTime.now().year + index;
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (int? value) {
                              setDialogState(() {
                                selectedYear = value ?? _currentYear;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final id = anggaran['id'].toString();
                    final api = ApiService();
                    await api.loadToken();

                    final payload = {
                      if (selectedKategoriId != null)
                        'id_kategori': selectedKategoriId,
                      'batas_pengeluaran':
                          double.tryParse(
                            batasController.text
                                .replaceAll('.', '')
                                .replaceAll(',', ''),
                          ) ??
                          0,
                      'bulan': selectedMonth,
                      'tahun': selectedYear,
                      'tanggal_anggaran':
                          tanggalController.text, // <-- update tanggal
                    };

                    try {
                      final resp = await api.updateAnggaran(id, payload);
                      if (resp.statusCode == 200) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Anggaran berhasil diperbarui'),
                          ),
                        );
                        _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal memperbarui anggaran')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUseAnggaranConfirmation(Map<String, dynamic> anggaran) {
    final kategori = anggaran['kategori'] as Map<String, dynamic>? ?? {};
    final namaKategori = kategori['nama_kategori'] ?? 'Kategori';
    final kategoriId = kategori['id']?.toString() ?? '';
    final batasPengeluaran =
        double.tryParse(anggaran['batas_pengeluaran'].toString()) ?? 0.0;
    final anggaranId = anggaran['id'].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gunakan Anggaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Apakah Anda yakin ingin menggunakan anggaran ini?'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategori: $namaKategori',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Jumlah: Rp ${_formatCurrency(batasPengeluaran)}'),
                    SizedBox(height: 8),
                    Text(
                      'Saldo Anda akan dikurangi sebesar jumlah di atas',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _useAnggaran(
                  anggaranId,
                  batasPengeluaran,
                  namaKategori,
                  kategoriId,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Gunakan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnggaranCard(Map<String, dynamic> anggaran) {
    final kategori = anggaran['kategori'] as Map<String, dynamic>? ?? {};
    final namaKategori = kategori['nama_kategori'] ?? 'Kategori';
    final batasPengeluaran =
        double.tryParse(anggaran['batas_pengeluaran'].toString()) ?? 0.0;
    final bulan = anggaran['bulan'] ?? 1;
    final tahun = anggaran['tahun'] ?? DateTime.now().year;
    final tanggalAnggaran = (anggaran['tanggal_anggaran'] ?? '-') as String;
    final anggaranId = anggaran['id'].toString();

    final isUsed = _usedAnggaranIds.contains(anggaranId);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUsed ? Colors.grey.shade200 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: isUsed ? Colors.grey.shade600 : Colors.red.shade700,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaKategori,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isUsed ? Colors.grey.shade700 : Colors.black,
                        ),
                      ),
                      Text(
                        '${_getMonthName(bulan)} $tahun',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      // TAMPILKAN TANGGAL ANGGARAN
                      if (tanggalAnggaran.isNotEmpty && tanggalAnggaran != '-')
                        Text(
                          'Tanggal: $tanggalAnggaran',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Checkbox untuk menggunakan anggaran
                Checkbox(
                  value: isUsed,
                  onChanged:
                      isUsed
                          ? null
                          : (bool? value) {
                            if (value == true) {
                              _showUseAnggaranConfirmation(anggaran);
                            }
                          },
                  activeColor: Colors.red,
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(anggaran['id'].toString());
                    } else if (value == 'reset' && isUsed) {
                      _showResetConfirmation(anggaran['id'].toString());
                    } else if (value == 'edit') {
                      _showEditAnggaranDialog(anggaran);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Ubah'),
                            ],
                          ),
                        ),
                        if (isUsed)
                          PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.refresh, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Reset Status'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUsed ? Colors.grey.shade100 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUsed ? Colors.grey.shade300 : Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Batas Pengeluaran',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (isUsed)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'TERPAKAI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Rp ${_formatCurrency(batasPengeluaran)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isUsed ? Colors.grey.shade700 : Colors.red.shade700,
                    ),
                  ),
                  if (isUsed)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Anggaran telah digunakan dan saldo sudah dikurangi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Status Anggaran'),
          content: Text(
            'Apakah Anda yakin ingin mereset status anggaran ini? Status akan kembali menjadi belum digunakan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _removeUsedAnggaran(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status anggaran berhasil direset')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Reset', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Anggaran'),
          content: Text('Apakah Anda yakin ingin menghapus anggaran ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAnggaran(id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Color(0xFF00BFA5),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
          SizedBox(height: 12),
          Text(
            'Kelola Anggaran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Atur batas pengeluaran untuk setiap kategori',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Centang checkbox untuk menggunakan anggaran',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anggaran'),
        backgroundColor: Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 16),
                    if (_anggaranList.isEmpty)
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada anggaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Mulai kelola anggaran dengan menambahkan batas pengeluaran untuk setiap kategori',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._anggaranList.map(
                        (anggaran) => _buildAnggaranCard(anggaran),
                      ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAnggaranDialog,
        backgroundColor: Color(0xFF00BFA5),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Anggaran', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

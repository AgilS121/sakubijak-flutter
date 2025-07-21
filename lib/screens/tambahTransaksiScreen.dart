import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sakubijak/services/apiService.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isIncome = true;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  int? selectedCategoryId;
  DateTime selectedDate = DateTime.now();
  bool isSubmitting = false;

  bool isLoadingKategori = false;
  List<Map<String, dynamic>> kategoriList = [];
  bool isCustomCategory = false;

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    setState(() => isLoadingKategori = true);

    try {
      final api = ApiService();
      await api.loadToken();
      final response = await api.getKategori();

      print("Status Kategori: ${response.statusCode}");
      print("Body Kategori: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List<dynamic> allKategoriRaw = jsonData['data'];

        final allKategori =
            allKategoriRaw
                .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item),
                )
                .toList();

        setState(() {
          kategoriList =
              allKategori
                  .where(
                    (k) =>
                        k['jenis'] == (isIncome ? 'pemasukan' : 'pengeluaran'),
                  )
                  .toList();
        });

        print("Filtered kategoriList: $kategoriList");
      }
    } catch (e) {
      print("Error kategori: $e");
    } finally {
      setState(() => isLoadingKategori = false);
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<int?> _createCustomCategory() async {
    if (_customCategoryController.text.trim().isEmpty) return null;

    try {
      final api = ApiService();
      await api.loadToken();

      // Asumsi ada method createKategori di ApiService
      // Sesuaikan dengan API endpoint Anda
      final response = await api.createKategori(
        _customCategoryController.text.trim(),
        isIncome ? 'pemasukan' : 'pengeluaran',
      );

      print("Create kategori response: ${response.statusCode}");
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return jsonData['data']['id']; // Sesuaikan dengan struktur response API
      }
    } catch (e) {
      print("Create kategori error: $e");
    }
    return null;
  }

  void _submitTransaction() async {
    if (_amountController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        (selectedCategoryId == null && !isCustomCategory) ||
        (isCustomCategory && _customCategoryController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi semua data terlebih dahulu.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      int? categoryId = selectedCategoryId;

      // Jika menggunakan kategori custom, buat kategori baru terlebih dahulu
      if (isCustomCategory) {
        categoryId = await _createCustomCategory();
        if (categoryId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat kategori baru.')),
          );
          setState(() => isSubmitting = false);
          return;
        }
      }

      final api = ApiService();
      await api.loadToken();

      final response = await api.createTransaksi(
        categoryId!,
        int.parse(_amountController.text),
        _descriptionController.text,
        DateFormat('yyyy-MM-dd').format(selectedDate),
      );

      print("Create transaksi response: ${response.statusCode}");
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi.')));
      }
    } catch (e) {
      print("Submit error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan.')));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00BFA5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Tambah Transaksi',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Toggle
                        Row(
                          children: [
                            _buildToggleButton('Pemasukan', true),
                            SizedBox(width: 10),
                            _buildToggleButton('Pengeluaran', false),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Tanggal
                        _buildDateField(),

                        // Kategori
                        _buildDropdownKategori(),

                        // Custom Category Field (muncul jika isCustomCategory = true)
                        if (isCustomCategory) ...[
                          SizedBox(height: 20),
                          TextField(
                            controller: _customCategoryController,
                            decoration: InputDecoration(
                              labelText: 'Nama Kategori Baru',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFF00BFA5),
                                ),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 20),

                        // Nominal
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nominal',
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Deskripsi
                        TextField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        ElevatedButton(
                          onPressed: isSubmitting ? null : _submitTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFA5),
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child:
                              isSubmitting
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Simpan',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool value) {
    bool selected = isIncome == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isIncome != value) {
            setState(() {
              isIncome = value;
              selectedCategoryId = null;
              isCustomCategory = false;
              _customCategoryController.clear();
            });
            _loadKategori();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? (value ? Colors.green : Colors.red)
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: Color(0xFFF0F8F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey),
            SizedBox(width: 10),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownKategori() {
    if (isLoadingKategori) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (kategoriList.isEmpty && !isCustomCategory) {
      return Column(
        children: [
          Text('Kategori tidak tersedia.'),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isCustomCategory = true;
              });
            },
            child: Text('Buat Kategori Baru'),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    // Buat list dropdown items dengan opsi "Tambah Kategori Baru"
    List<DropdownMenuItem<String>> dropdownItems = [];

    // Tambahkan kategori yang sudah ada
    dropdownItems.addAll(
      kategoriList.map((kategori) {
        return DropdownMenuItem<String>(
          value: 'existing_${kategori['id']}',
          child: Text(kategori['nama_kategori']),
        );
      }),
    );

    // Tambahkan opsi "Tambah Kategori Baru"
    dropdownItems.add(
      DropdownMenuItem<String>(
        value: 'add_new',
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: Color(0xFF00BFA5)),
            SizedBox(width: 8),
            Text(
              'Tambah Kategori Baru',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    String? currentValue;
    if (isCustomCategory) {
      currentValue = 'add_new';
    } else if (selectedCategoryId != null) {
      currentValue = 'existing_$selectedCategoryId';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF0F8F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: currentValue,
          items: dropdownItems,
          onChanged: (value) {
            setState(() {
              if (value == 'add_new') {
                isCustomCategory = true;
                selectedCategoryId = null;
              } else if (value != null && value.startsWith('existing_')) {
                isCustomCategory = false;
                selectedCategoryId = int.parse(value.substring(9));
                _customCategoryController.clear();
              }
            });
          },
          decoration: InputDecoration(
            labelText: 'Kategori',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

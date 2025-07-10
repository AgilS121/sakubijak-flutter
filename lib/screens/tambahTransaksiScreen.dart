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
  int? selectedCategoryId;
  DateTime selectedDate = DateTime.now();
  bool isSubmitting = false;

  bool isLoadingKategori = false;
  List<Map<String, dynamic>> kategoriList = [];

  @override
  void initState() {
    super.initState();
    _loadKategori();
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
        final List<dynamic> jsonData = jsonDecode(response.body);
        final allKategori =
            jsonData
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

  void _submitTransaction() async {
    if (_amountController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi semua data terlebih dahulu.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final api = ApiService();
      await api.loadToken();

      final response = await api.createTransaksi(
        selectedCategoryId!,
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

                        // Nominal
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nominal',
                            prefixIcon: Icon(Icons.attach_money),
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

    if (kategoriList.isEmpty) {
      return Text('Kategori tidak tersedia.');
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
        child: DropdownButtonFormField<int>(
          isExpanded: true,
          value: selectedCategoryId,
          items:
              kategoriList.map((kategori) {
                return DropdownMenuItem<int>(
                  value: kategori['id'],
                  child: Text(kategori['nama_kategori']),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategoryId = value;
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

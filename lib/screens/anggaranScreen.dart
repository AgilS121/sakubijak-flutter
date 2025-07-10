import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sakubijak/helper/shared_preferences.dart';

class BudgetPage extends StatefulWidget {
  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<dynamic> _kategoriList = [];
  bool _isLoading = true;

  double _saldo = 0.0;
  double _totalPengeluaran = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final token = await SharedPrefHelper.getToken();

    try {
      // Ambil kategori
      final kategoriResponse = await http.get(
        Uri.parse(
          'https://sakubijak.adservices.site/api/kategori-with-pengeluaran',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Ambil transaksi
      final transaksiResponse = await http.get(
        Uri.parse('https://sakubijak.adservices.site/api/transaksi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (kategoriResponse.statusCode == 200 &&
          transaksiResponse.statusCode == 200) {
        final kategoriData = json.decode(kategoriResponse.body);
        final transaksiData = json.decode(transaksiResponse.body);

        List<dynamic> transaksiList = [];

        if (transaksiData is Map<String, dynamic> &&
            transaksiData.containsKey('data')) {
          transaksiList = transaksiData['data'];
        } else if (transaksiData is List) {
          transaksiList = transaksiData;
        }

        double saldo = 0.0;
        double totalPengeluaran = 0.0;

        for (var tx in transaksiList) {
          final kategori = tx['kategori'] as Map<String, dynamic>? ?? {};
          double jumlah = 0.0;

          if (tx['jumlah'] is String) {
            jumlah = double.tryParse(tx['jumlah']) ?? 0.0;
          } else if (tx['jumlah'] is num) {
            jumlah = (tx['jumlah'] as num).toDouble();
          }

          bool isPemasukan = kategori['jenis'] == 'pemasukan';
          if (isPemasukan) {
            saldo += jumlah;
          } else {
            saldo -= jumlah;
            totalPengeluaran += jumlah;
          }
        }

        setState(() {
          _kategoriList = kategoriData;
          _saldo = saldo;
          _totalPengeluaran = totalPengeluaran;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
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
                    'Anggaran',
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
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Saldo dan Pengeluaran
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
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
                        'Rp ${_formatCurrency(_saldo)}',
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
            ),

            SizedBox(height: 30),

            // Kategori Grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child:
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 3,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                children: [
                                  ..._kategoriList.take(5).map((item) {
                                    return GestureDetector(
                                      onTap: () {
                                        _showDetailDialog(item);
                                      },
                                      child: _buildCategoryItem(
                                        item['nama_kategori'],
                                        Icons.category,
                                        Colors.blue,
                                      ),
                                    );
                                  }).toList(),
                                  if (_kategoriList.length > 5)
                                    _buildCategoryItem(
                                      'More',
                                      Icons.add,
                                      Colors.blue,
                                    ),
                                ],
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

  Widget _buildCategoryItem(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(dynamic kategori) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(kategori['nama_kategori']),
            content: Text(
              'Total pengeluaran: Rp ${_formatCurrency((kategori['total_pengeluaran'] ?? 0).toDouble())}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
    );
  }
}

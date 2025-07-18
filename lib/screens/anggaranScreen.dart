import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';

class BudgetPage extends StatefulWidget {
  @override
  _BudgetPageState createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  double _saldo = 0.0;
  double _totalPengeluaran = 0.0;
  double _totalPemasukan = 0.0;
  List<Map<String, dynamic>> _transaksi = [];
  List<dynamic> _pemasukan = [];
  List<dynamic> _pengeluaran = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final api = ApiService();
    await api.loadToken();

    try {
      // Load transactions (same as dashboard)
      final response = await api.getTransaksi();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Map<String, dynamic>> transaksi = [];

        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is List) {
            transaksi = List<Map<String, dynamic>>.from(data['data']);
          }
        } else if (data is List) {
          transaksi = List<Map<String, dynamic>>.from(data);
        }

        // Calculate totals (same logic as dashboard)
        double saldo = 0.0;
        double totalPemasukan = 0.0;
        double totalPengeluaran = 0.0;

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
            if (isPemasukan) {
              totalPemasukan += jumlah;
              saldo += jumlah;
            } else {
              totalPengeluaran += jumlah;
              saldo -= jumlah;
            }
          } catch (e) {
            print('Error processing transaction: $e');
          }
        }

        // Load categories for display
        await _loadKategori(api);

        setState(() {
          _saldo = saldo;
          _totalPemasukan = totalPemasukan;
          _totalPengeluaran = totalPengeluaran;
          _transaksi = transaksi;
          _isLoading = false;
        });
      } else {
        print('Error loading transactions: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadKategori(ApiService api) async {
    try {
      final response = await api.getKategori();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List kategori = [];
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          kategori = data['data'] as List? ?? [];
        } else if (data is List) {
          kategori = data;
        }

        setState(() {
          _pemasukan =
              kategori.where((e) => e['jenis'] == 'pemasukan').toList();
          _pengeluaran =
              kategori.where((e) => e['jenis'] == 'pengeluaran').toList();
        });
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

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Color(0xFF00BFA5), // Same color as dashboard
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Saldo Saat Ini',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Rp ${_formatCurrency(_saldo)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Pemasukan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp ${_formatCurrency(_totalPemasukan)}',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Pengeluaran',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp ${_formatCurrency(_totalPengeluaran)}',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildKategoriList(String title, List<dynamic> list, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          list.isEmpty
              ? Container(
                height: 60,
                child: Center(
                  child: Text(
                    "Belum ada data kategori",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              )
              : Column(
                children:
                    list.map((item) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.category,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_kategori'] ?? 'Kategori',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    item['jenis']?.toString().toUpperCase() ??
                                        '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anggaran'),
        backgroundColor: Color(0xFF00BFA5), // Same color as dashboard
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  children: [
                    buildHeader(),
                    SizedBox(height: 16),
                    buildKategoriList(
                      "Daftar Pemasukan",
                      _pemasukan,
                      Colors.green,
                    ),
                    buildKategoriList(
                      "Daftar Pengeluaran",
                      _pengeluaran,
                      Colors.red,
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }
}

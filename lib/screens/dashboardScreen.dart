import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/screens/tambahTransaksiScreen.dart';
import 'package:sakubijak/screens/targetScreen.dart';
import 'package:sakubijak/screens/notifikasiScreen.dart';
import 'package:sakubijak/services/apiService.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _namaUser = '...';
  double _saldo = 0.0;
  double _targetKeuangan = 0.0;
  List<Map<String, dynamic>> _transaksi = [];
  int _unreadNotifCount = 0;
  bool _isLoading = true;

  final ApiService _notifikasiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    await api.loadToken();

    try {
      // Load transactions
      final response = await api.getTransaksi();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle the response structure properly
        List<Map<String, dynamic>> transaksi = [];

        if (data is Map<String, dynamic>) {
          // If response has 'data' field containing the array
          if (data.containsKey('data') && data['data'] is List) {
            transaksi = List<Map<String, dynamic>>.from(data['data']);
          }
          // If response has 'user' field for user info
          if (data.containsKey('user') && data['user'] is Map) {
            _namaUser = data['user']['nama'] ?? 'User';
          }
        } else if (data is List) {
          // If response is directly an array
          transaksi = List<Map<String, dynamic>>.from(data);
        }

        // Calculate balance
        double saldo = 0.0;
        for (var tx in transaksi) {
          try {
            final kategori = tx['kategori'] as Map<String, dynamic>? ?? {};

            // Handle jumlah as string or number
            double jumlah = 0.0;
            if (tx['jumlah'] is String) {
              jumlah = double.tryParse(tx['jumlah'] as String) ?? 0.0;
            } else if (tx['jumlah'] is num) {
              jumlah = (tx['jumlah'] as num).toDouble();
            }

            bool isPemasukan = kategori['jenis'] == 'pemasukan';
            saldo += isPemasukan ? jumlah : -jumlah;
          } catch (e) {
            print('Error processing transaction: $e');
          }
        }

        // Load target keuangan
        await _loadTargetKeuangan(api);

        // Load notification count
        await _loadNotificationCount();

        setState(() {
          _saldo = saldo;
          _transaksi = transaksi;
          _isLoading = false;
        });
      } else {
        print('Error loading transactions: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTargetKeuangan(ApiService api) async {
    try {
      final response = await api.getTujuan();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        double totalTarget = 0.0;
        List<dynamic> tujuan = [];

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          tujuan = data['data'] as List<dynamic>? ?? [];
        } else if (data is List) {
          tujuan = data;
        }

        for (var item in tujuan) {
          if (item is Map<String, dynamic>) {
            double targetUang = 0.0;
            if (item['target_uang'] is String) {
              targetUang =
                  double.tryParse(item['target_uang'] as String) ?? 0.0;
            } else if (item['target_uang'] is num) {
              targetUang = (item['target_uang'] as num).toDouble();
            }
            totalTarget += targetUang;
          }
        }

        setState(() {
          _targetKeuangan = totalTarget;
        });
      }
    } catch (e) {
      print('Error loading target keuangan: $e');
      setState(() {
        _targetKeuangan = 0.0;
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final response = await _notifikasiService.getUnreadCount();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _unreadNotifCount = data['unread_count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
      setState(() {
        _unreadNotifCount = 0;
      });
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hai, Selamat Datang',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        _namaUser,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotifikasiScreen()),
                      );
                      if (result == true) {
                        _loadNotificationCount();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                            ),
                          ),
                          if (_unreadNotifCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _unreadNotifCount > 9
                                      ? '9+'
                                      : _unreadNotifCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      // Saldo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rp ${_formatCurrency(_saldo)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TargetScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFF00BFA5),
                                      width: 1.5,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Target Bulanan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF00BFA5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatCurrency(_targetKeuangan)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      // Tombol aksi
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AddTransactionScreen(
                                          initialJenis: 'pemasukan',
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00BFA5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Pemasukan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AddTransactionScreen(
                                          initialJenis: 'pengeluaran',
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Pengeluaran',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // List transaksi
                      Expanded(
                        child:
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : RefreshIndicator(
                                  onRefresh: _loadData,
                                  child:
                                      _transaksi.isEmpty
                                          ? ListView(
                                            physics:
                                                AlwaysScrollableScrollPhysics(),
                                            children: [
                                              Container(
                                                height: 200,
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.receipt_long,
                                                        size: 48,
                                                        color: Colors.grey[400],
                                                      ),
                                                      SizedBox(height: 16),
                                                      Text(
                                                        'Tidak ada transaksi',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Tarik ke bawah untuk refresh',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[400],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                          : ListView.builder(
                                            physics:
                                                AlwaysScrollableScrollPhysics(),
                                            itemCount: _transaksi.length,
                                            itemBuilder: (context, index) {
                                              final tx = _transaksi[index];
                                              final kategori =
                                                  tx['kategori']
                                                      as Map<
                                                        String,
                                                        dynamic
                                                      >? ??
                                                  {};
                                              final isPemasukan =
                                                  kategori['jenis'] ==
                                                  'pemasukan';
                                              final namaKategori =
                                                  kategori['nama_kategori'] ??
                                                  'Tidak diketahui';

                                              // Handle jumlah display
                                              String jumlahDisplay = '0';
                                              if (tx['jumlah'] is String) {
                                                double jumlah =
                                                    double.tryParse(
                                                      tx['jumlah'] as String,
                                                    ) ??
                                                    0.0;
                                                jumlahDisplay = _formatCurrency(
                                                  jumlah,
                                                );
                                              } else if (tx['jumlah'] is num) {
                                                jumlahDisplay = _formatCurrency(
                                                  (tx['jumlah'] as num)
                                                      .toDouble(),
                                                );
                                              }

                                              return Container(
                                                margin: EdgeInsets.only(
                                                  bottom: 15,
                                                ),
                                                padding: EdgeInsets.all(15),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFF0F8F0),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isPemasukan
                                                                ? Colors.green
                                                                : Colors.red,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        isPemasukan
                                                            ? Icons
                                                                .arrow_downward
                                                            : Icons
                                                                .arrow_upward,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(width: 15),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            namaKategori,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            tx['tanggal'] ?? '',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          if (tx['deskripsi'] !=
                                                                  null &&
                                                              tx['deskripsi']
                                                                  .toString()
                                                                  .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                    top: 2,
                                                                  ),
                                                              child: Text(
                                                                tx['deskripsi']
                                                                    .toString(),
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey[500],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Text(
                                                      '${isPemasukan ? '+' : '-'}Rp $jumlahDisplay',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            isPemasukan
                                                                ? Colors.green
                                                                : Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                ),
                      ),
                      SizedBox(height: 10),

                      // Tombol tambah transaksi
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AddTransactionScreen(
                                    initialJenis: 'pengeluaran',
                                  ),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF00BFA5),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF00BFA5).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: 30),
                        ),
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
}

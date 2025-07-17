import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/auth/loginScreen.dart';
import 'package:sakubijak/services/apiService.dart';
import 'package:sakubijak/helper/shared_preferences.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalTransaksi = 0;
  int _totalKategori = 0;
  double _totalSaldo = 0.0;
  bool _isLoading = true;

  final ApiService api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    await api.loadToken();

    try {
      final userRes = await api.getTotalUsers();
      final kategoriRes = await api.getTotalKategori();

      print('User status: ${userRes.statusCode}');
      print('User body: ${userRes.body}');
      print('Kategori status: ${kategoriRes.statusCode}');
      print('Kategori body: ${kategoriRes.body}');

      if (userRes.statusCode == 200 && kategoriRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        final kategoriData = jsonDecode(kategoriRes.body);

        setState(() {
          _totalUsers = userData['total'] ?? 0;
          _totalKategori = kategoriData['total'] ?? 0;

          // Dummy data lainnya
          _totalTransaksi = 1250;
          _totalSaldo = 25000000;
          _isLoading = false;
        });
      } else {
        print('Gagal memuat data dari server.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Terjadi error saat load data dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await api.logout();
    } catch (_) {}
    await SharedPrefHelper.clearToken(); // Hapus token
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
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
                        'Admin Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        'SakuBijak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _logout,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.logout, color: Colors.white),
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
                child:
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: _loadDashboardData,
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                Text(
                                  'Statistik Sistem',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 15),
                                GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                  childAspectRatio: 1.2,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildStatCard(
                                      title: 'Total Users',
                                      value: _totalUsers.toString(),
                                      icon: Icons.people,
                                      color: Colors.blue,
                                    ),
                                    _buildStatCard(
                                      title: 'Total Kategori',
                                      value: _totalKategori.toString(),
                                      icon: Icons.category,
                                      color: Colors.orange,
                                    ),
                                    // _buildStatCard(
                                    //   title: 'Total Transaksi',
                                    //   value: _totalTransaksi.toString(),
                                    //   icon: Icons.swap_horiz,
                                    //   color: Colors.green,
                                    // ),
                                    // _buildStatCard(
                                    //   title: 'Total Saldo',
                                    //   value:
                                    //       'Rp ${_formatCurrency(_totalSaldo)}',
                                    //   icon: Icons.account_balance_wallet,
                                    //   color: Colors.purple,
                                    // ),
                                  ],
                                ),
                                SizedBox(height: 30),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

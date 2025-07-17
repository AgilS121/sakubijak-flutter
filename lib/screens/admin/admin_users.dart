import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.getAllUsers();
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(json['data']);
          _isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data user');
      }
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user['nama'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user['email'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatCurrency(dynamic amount) {
    double value = (amount is int) ? amount.toDouble() : amount ?? 0.0;
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Detail User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Nama', user['nama']),
                _buildDetailRow('Email', user['email']),
                _buildDetailRow('Tanggal Daftar', user['created_at']),
                _buildDetailRow(
                  'Total Transaksi',
                  '${user['total_transaksi']} transaksi',
                ),
                _buildDetailRow(
                  'Saldo',
                  'Rp ${_formatCurrency(user['saldo'])}',
                ),
                _buildDetailRow('Status', user['status']),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manajemen Users',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Kelola data pengguna aplikasi',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.people, color: Colors.white, size: 40),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari user...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // User List
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
                          onRefresh: _loadUsers,
                          child:
                              _filteredUsers.isEmpty
                                  ? ListView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(height: 150),
                                      Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Tidak ada user ditemukan',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  : ListView.builder(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.all(20),
                                    itemCount: _filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _filteredUsers[index];
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 15),
                                        padding: EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF00BFA5),
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  user['nama'][0].toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 15),

                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user['nama'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    user['email'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        size: 8,
                                                        color:
                                                            user['status'] ==
                                                                    'aktif'
                                                                ? Colors.green
                                                                : Colors.red,
                                                      ),
                                                      SizedBox(width: 5),
                                                      Text(
                                                        user['status'],
                                                        style: TextStyle(
                                                          color:
                                                              user['status'] ==
                                                                      'aktif'
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Right stats
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Rp ${_formatCurrency(user['saldo'])}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF00BFA5),
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  '${user['total_transaksi']} transaksi',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Detail button
                                            SizedBox(width: 10),
                                            GestureDetector(
                                              onTap:
                                                  () => _showUserDetails(user),
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.info_outline,
                                                  size: 20,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';

class NotifikasiScreen extends StatefulWidget {
  @override
  _NotifikasiScreenState createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<Map<String, dynamic>> _notifikasi = [];
  bool _isLoading = true;
  final ApiService _notifikasiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  Future<void> _loadNotifikasi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _notifikasiService.getNotifikasi();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifikasi = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _isLoading = false;
        });
      } else {
        print('Error loading notifikasi: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading notifikasi: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final response = await _notifikasiService.markAsRead(id);
      if (response.statusCode == 200) {
        _loadNotifikasi(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tagihan ditandai sebagai sudah dibayar')),
        );
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'tagihan_terlambat':
        return Icons.warning;
      case 'tagihan_hari_ini':
        return Icons.today;
      case 'tagihan_segera':
        return Icons.schedule;
      case 'tagihan_minggu_ini':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  String _formatCurrency(dynamic amount) {
    double value = 0.0;
    if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    }

    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        backgroundColor: Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadNotifikasi),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadNotifikasi,
                child:
                    _notifikasi.isEmpty
                        ? ListView(
                          physics: AlwaysScrollableScrollPhysics(),
                          children: [
                            Container(
                              height: 400,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada notifikasi',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Semua tagihan Anda up to date!',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16),
                          itemCount: _notifikasi.length,
                          itemBuilder: (context, index) {
                            final notif = _notifikasi[index];
                            final priority = notif['priority'] ?? 'low';
                            final type = notif['type'] ?? 'notification';

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: _getPriorityColor(
                                    priority,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      priority,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    _getTypeIcon(type),
                                    color: _getPriorityColor(priority),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  notif['title'] ?? 'Notifikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      notif['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Rp ${_formatCurrency(notif['jumlah'])}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getPriorityColor(priority),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          notif['tanggal'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing:
                                    priority == 'high'
                                        ? IconButton(
                                          icon: Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            _showMarkAsReadDialog(notif['id']);
                                          },
                                        )
                                        : Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey[400],
                                        ),
                                onTap: () {
                                  _showDetailDialog(notif);
                                },
                              ),
                            );
                          },
                        ),
              ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> notif) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(notif['title'] ?? 'Detail Notifikasi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif['message'] ?? '', style: TextStyle(fontSize: 16)),
                SizedBox(height: 12),
                Text(
                  'Jumlah: Rp ${_formatCurrency(notif['jumlah'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _getPriorityColor(notif['priority'] ?? 'low'),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tanggal: ${notif['tanggal'] ?? ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
              if (notif['priority'] == 'high')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _markAsRead(notif['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    'Tandai Lunas',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
    );
  }

  void _showMarkAsReadDialog(int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi'),
            content: Text('Apakah Anda yakin tagihan ini sudah dibayar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _markAsRead(id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  'Ya, Sudah Dibayar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

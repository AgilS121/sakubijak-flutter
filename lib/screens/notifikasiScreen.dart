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
      // Mengambil data anggaran dari API
      final response = await _notifikasiService.getAnggaran();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final anggaranList = List<Map<String, dynamic>>.from(
          data['data'] ?? [],
        );

        // Filter dan convert data anggaran menjadi notifikasi
        final filteredNotifikasi = _filterAndConvertAnggaran(anggaranList);

        setState(() {
          _notifikasi = filteredNotifikasi;
          _isLoading = false;
        });
      } else {
        print('Error loading anggaran: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading anggaran: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _filterAndConvertAnggaran(
    List<Map<String, dynamic>> anggaranList,
  ) {
    final now = DateTime.now();
    final h3Before = now.subtract(Duration(days: 3));
    final h7After = now.add(
      Duration(days: 7),
    ); // Contoh H+7, bisa diubah sesuai kebutuhan

    List<Map<String, dynamic>> notifikasiList = [];

    for (var anggaran in anggaranList) {
      try {
        final createdAtStr = anggaran['created_at'] as String?;
        if (createdAtStr == null) continue;

        final createdAt = DateTime.parse(createdAtStr);

        // Filter berdasarkan rentang H-3 sampai H+7
        if (createdAt.isAfter(h3Before) && createdAt.isBefore(h7After)) {
          // Hitung selisih hari dari hari ini
          final daysDifference = createdAt.difference(now).inDays;

          // Tentukan prioritas dan tipe berdasarkan selisih hari
          String priority;
          String type;
          String title;
          String message;

          if (daysDifference < -1) {
            priority = 'high';
            type = 'anggaran_terlambat';
            title = 'Anggaran Sudah Lewat';
            message =
                'Anggaran ${anggaran['kategori']?['nama_kategori'] ?? 'Unknown'} sudah lewat ${daysDifference.abs()} hari';
          } else if (daysDifference == -1) {
            priority = 'high';
            type = 'anggaran_kemarin';
            title = 'Anggaran Kemarin';
            message =
                'Anggaran ${anggaran['kategori']?['nama_kategori'] ?? 'Unknown'} dibuat kemarin';
          } else if (daysDifference == 0) {
            priority = 'high';
            type = 'anggaran_hari_ini';
            title = 'Anggaran Hari Ini';
            message =
                'Anggaran ${anggaran['kategori']?['nama_kategori'] ?? 'Unknown'} dibuat hari ini';
          } else if (daysDifference <= 3) {
            priority = 'medium';
            type = 'anggaran_segera';
            title = 'Anggaran Baru';
            message =
                'Anggaran ${anggaran['kategori']?['nama_kategori'] ?? 'Unknown'} dibuat $daysDifference hari lagi';
          } else {
            priority = 'low';
            type = 'anggaran_minggu_ini';
            title = 'Anggaran Mendatang';
            message =
                'Anggaran ${anggaran['kategori']?['nama_kategori'] ?? 'Unknown'} dibuat $daysDifference hari lagi';
          }

          // Format tanggal untuk ditampilkan
          final formattedDate =
              '${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}';

          notifikasiList.add({
            'id': anggaran['id'],
            'title': title,
            'message': message,
            'jumlah': anggaran['batas_pengeluaran'],
            'tanggal': formattedDate,
            'priority': priority,
            'type': type,
            'kategori': anggaran['kategori']?['nama_kategori'] ?? 'Unknown',
            'tahun': anggaran['tahun'],
            'bulan': anggaran['bulan'],
            'created_at': createdAtStr,
          });
        }
      } catch (e) {
        print('Error parsing anggaran item: $e');
        continue;
      }
    }

    // Sort berdasarkan prioritas dan tanggal
    notifikasiList.sort((a, b) {
      // Priority order: high > medium > low
      const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      final priorityComparison = (priorityOrder[a['priority']] ?? 3).compareTo(
        priorityOrder[b['priority']] ?? 3,
      );

      if (priorityComparison != 0) return priorityComparison;

      // Sort by date (newest first)
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });

    return notifikasiList;
  }

  Future<void> _markAsRead(int id) async {
    try {
      // Untuk anggaran, kita bisa membuat endpoint khusus atau menggunakan update
      // Sementara ini kita refresh data saja
      _loadNotifikasi();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anggaran telah ditandai sebagai telah dilihat'),
        ),
      );
    } catch (e) {
      print('Error marking as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai sebagai sudah dilihat')),
      );
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
      case 'anggaran_terlambat':
        return Icons.warning;
      case 'anggaran_kemarin':
        return Icons.history;
      case 'anggaran_hari_ini':
        return Icons.today;
      case 'anggaran_segera':
        return Icons.schedule;
      case 'anggaran_minggu_ini':
        return Icons.calendar_today;
      default:
        return Icons.account_balance_wallet;
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

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi Anggaran'),
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
                                      Icons.account_balance_wallet_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada notifikasi anggaran',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Semua anggaran Anda dalam rentang waktu yang ditentukan!',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
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
                                  notif['title'] ?? 'Notifikasi Anggaran',
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
            title: Text(notif['title'] ?? 'Detail Notifikasi Anggaran'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif['message'] ?? '', style: TextStyle(fontSize: 16)),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(notif['kategori'] ?? '-'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Periode:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_getMonthName(notif['bulan'] ?? 1)} ${notif['tahun'] ?? 2025}',
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Batas Pengeluaran:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp ${_formatCurrency(notif['jumlah'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(
                                notif['priority'] ?? 'low',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Dibuat: ${notif['tanggal'] ?? ''}',
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
                    'Tandai Sudah Dilihat',
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
            content: Text(
              'Apakah Anda yakin sudah melihat notifikasi anggaran ini?',
            ),
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
                  'Ya, Sudah Dilihat',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

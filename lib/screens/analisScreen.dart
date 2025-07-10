import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakubijak/services/apiService.dart';
import 'dart:ui' as ui;

class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final List<String> months = [
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
  String selectedMonth = 'Januari';
  double totalSaldo = 0;
  double totalPengeluaran = 0;
  double totalPemasukan = 0;
  List<ChartData> chartData = [];
  List<TransactionItem> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocaleAndFetchData();
  }

  Future<void> _initializeLocaleAndFetchData() async {
    await initializeDateFormatting('id_ID', null);
    final now = DateTime.now();
    setState(() {
      selectedMonth = DateFormat.MMMM('id_ID').format(now);
    });
    await fetchAnalysisData(now);
  }

  Future<void> fetchAnalysisData(DateTime monthDate) async {
    setState(() {
      isLoading = true;
    });

    final api = ApiService();
    await api.loadToken();

    final mulai = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(monthDate.year, monthDate.month, 1));
    final sampai = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(monthDate.year, monthDate.month + 1, 0));

    try {
      final response = await api.getLaporan(mulai, sampai);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        // Parse transactions
        List<TransactionItem> transactionList =
            jsonData.map((item) {
              return TransactionItem(
                id: item['id'] as int,
                jumlah: double.tryParse(item['jumlah'].toString()) ?? 0.0,
                deskripsi: item['deskripsi'] as String,
                tanggal: item['tanggal'] as String,
                kategori: item['kategori']['nama_kategori'] as String,
                jenis: item['kategori']['jenis'] as String,
              );
            }).toList();

        // Calculate totals
        double pemasukan = 0.0;
        double pengeluaran = 0.0;

        for (var transaction in transactionList) {
          if (transaction.jenis == 'pemasukan') {
            pemasukan += transaction.jumlah;
          } else if (transaction.jenis == 'pengeluaran') {
            pengeluaran += transaction.jumlah;
          }
        }

        // Group by weeks for chart
        Map<String, double> weeklyData = {};
        for (var transaction in transactionList) {
          DateTime date = DateTime.parse(transaction.tanggal);
          int weekOfMonth = ((date.day - 1) / 7).floor() + 1;
          String weekKey = 'Minggu $weekOfMonth';

          if (transaction.jenis == 'pengeluaran') {
            weeklyData[weekKey] =
                (weeklyData[weekKey] ?? 0.0) + transaction.jumlah;
          }
        }

        // Convert to chart data
        List<ChartData> chartDataList = [];
        for (int i = 1; i <= 4; i++) {
          String weekKey = 'Minggu $i';
          double value =
              (weeklyData[weekKey] ?? 0.0) / 1000000; // Convert to millions
          chartDataList.add(ChartData(label: weekKey, value: value));
        }

        setState(() {
          transactions = transactionList;
          totalPemasukan = pemasukan;
          totalPengeluaran = pengeluaran;
          totalSaldo = pemasukan - pengeluaran;
          chartData = chartDataList;
        });
      } else {
        print("Gagal mengambil data laporan: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching laporan: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showMonthSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 250,
          child: ListView.builder(
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              return ListTile(
                title: Text(month),
                trailing:
                    selectedMonth == month
                        ? Icon(Icons.check, color: Color(0xFF00BFA5))
                        : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedMonth = month;
                  });
                  // Use current year for selected month
                  final now = DateTime.now();
                  final selectedDate = DateTime(now.year, index + 1, 1);
                  fetchAnalysisData(selectedDate);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _downloadReport() async {
    final api = ApiService();
    await api.loadToken();

    // Get the current selected month index
    int monthIndex = months.indexOf(selectedMonth);
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, monthIndex + 1, 1);

    final mulai = DateFormat('yyyy-MM-dd').format(selectedDate);
    final sampai = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(selectedDate.year, selectedDate.month + 1, 0));

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Mengunduh laporan $selectedMonth...'),
                ],
              ),
            ),
      );

      final response = await api.eksporData('pdf', mulai, sampai);
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan $selectedMonth berhasil diunduh'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh laporan $selectedMonth'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        child:
            isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
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
                            'Analisis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: _downloadReport,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(Icons.download, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Summary
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo Total',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(totalSaldo)}',
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(totalPengeluaran)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total Pemasukan: Rp ${_formatCurrency(totalPemasukan)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Chart Section
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Month Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _showMonthSelector,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          selectedMonth,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 5),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Chart Title
                            Text(
                              'Pengeluaran Mingguan (dalam juta)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 10),

                            // Chart
                            Expanded(
                              child: CustomPaint(
                                painter: BarChartPainter(chartData),
                                child: Container(),
                              ),
                            ),
                            SizedBox(height: 10),

                            // Chart Labels
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children:
                                    chartData
                                        .map(
                                          (e) => Expanded(
                                            child: Text(
                                              e.label,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

// Transaction Item Model
class TransactionItem {
  final int id;
  final double jumlah;
  final String deskripsi;
  final String tanggal;
  final String kategori;
  final String jenis;

  TransactionItem({
    required this.id,
    required this.jumlah,
    required this.deskripsi,
    required this.tanggal,
    required this.kategori,
    required this.jenis,
  });
}

// ChartData
class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}

// Painter
class BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Color(0xFF00BFA5)
          ..style = PaintingStyle.fill;
    final backgroundPaint =
        Paint()
          ..color = Colors.grey[200]!
          ..style = PaintingStyle.fill;

    if (data.isEmpty) return;

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Calculate bar width and spacing for better alignment
    final totalWidth = size.width;
    final barWidth =
        totalWidth / (data.length * 1.5); // Adjust ratio for better spacing
    final spacing = barWidth * 0.25; // Reduce spacing

    for (int i = 0; i < data.length; i++) {
      final barHeight =
          maxValue > 0 ? (data[i].value / maxValue) * size.height * 0.8 : 0;

      // Center the bars properly
      final totalBarsWidth =
          (barWidth * data.length) + (spacing * (data.length - 1));
      final startX = (totalWidth - totalBarsWidth) / 2;
      final x = startX + (i * (barWidth + spacing));
      final y = size.height - barHeight;

      // Draw background bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          Radius.circular(8),
        ),
        backgroundPaint,
      );

      // Draw actual bar
      if (barHeight > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barWidth, barHeight.toDouble()),
            Radius.circular(8),
          ),
          paint,
        );
      }

      // Draw value text
      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].value > 0 ? '${data[i].value.toStringAsFixed(1)}' : '0',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      final textY = data[i].value > 0 ? y - 15 : size.height / 2;
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, textY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

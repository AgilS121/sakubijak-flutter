import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakubijak/services/apiService.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

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
  List<WeeklyChartData> chartData = [];
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
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> jsonData = [];

        // Handle different response structures
        if (responseData is List) {
          jsonData = responseData;
        } else if (responseData is Map) {
          if (responseData.containsKey('data')) {
            jsonData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('transactions')) {
            jsonData = responseData['transactions'] as List<dynamic>;
          } else {
            print('Unknown response structure: $responseData');
            jsonData = [];
          }
        }

        print('Parsed ${jsonData.length} transactions');

        // Parse transactions with better error handling
        List<TransactionItem> transactionList = [];

        for (var item in jsonData) {
          try {
            // Handle different possible structures
            String jenis = '';
            String kategori = '';

            if (item['kategori'] != null) {
              if (item['kategori'] is Map) {
                jenis = item['kategori']['jenis']?.toString() ?? '';
                kategori = item['kategori']['nama_kategori']?.toString() ?? '';
              } else if (item['kategori'] is String) {
                kategori = item['kategori'];
                // Try to determine jenis from other fields
                if (item.containsKey('jenis')) {
                  jenis = item['jenis']?.toString() ?? '';
                }
              }
            }

            // If jenis is still empty, try to get it directly from item
            if (jenis.isEmpty && item.containsKey('jenis')) {
              jenis = item['jenis']?.toString() ?? '';
            }

            // If still empty, try to infer from amount or other indicators
            if (jenis.isEmpty) {
              double amount =
                  double.tryParse(item['jumlah']?.toString() ?? '0') ?? 0.0;
              if (amount > 0) {
                jenis = 'pemasukan';
              } else {
                jenis = 'pengeluaran';
              }
            }

            TransactionItem transaction = TransactionItem(
              id:
                  item['id'] is int
                      ? item['id']
                      : int.tryParse(item['id']?.toString() ?? '0') ?? 0,
              jumlah: double.tryParse(item['jumlah']?.toString() ?? '0') ?? 0.0,
              deskripsi: item['deskripsi']?.toString() ?? '',
              tanggal: item['tanggal']?.toString() ?? '',
              kategori: kategori,
              jenis: jenis.toLowerCase(),
            );

            transactionList.add(transaction);
            print(
              'Added transaction: ${transaction.deskripsi}, amount: ${transaction.jumlah}, jenis: ${transaction.jenis}',
            );
          } catch (e) {
            print('Error parsing transaction item: $e');
            print('Item: $item');
          }
        }

        // Calculate totals
        double pemasukan = 0.0;
        double pengeluaran = 0.0;

        for (var transaction in transactionList) {
          if (transaction.jenis == 'pemasukan') {
            pemasukan += transaction.jumlah.abs();
          } else if (transaction.jenis == 'pengeluaran') {
            pengeluaran += transaction.jumlah.abs();
          }
        }

        print('Total pemasukan: $pemasukan');
        print('Total pengeluaran: $pengeluaran');

        // Group by weeks for chart
        Map<String, WeeklyData> weeklyData = {};

        // Get the number of days in the month
        final daysInMonth =
            DateTime(monthDate.year, monthDate.month + 1, 0).day;
        final numberOfWeeks = (daysInMonth / 7).ceil();

        // Initialize weeks
        for (int i = 1; i <= numberOfWeeks; i++) {
          weeklyData['Minggu $i'] = WeeklyData(
            pemasukan: 0.0,
            pengeluaran: 0.0,
          );
        }

        // Process transactions for weekly data
        for (var transaction in transactionList) {
          try {
            DateTime date;

            // Try different date formats
            try {
              date = DateTime.parse(transaction.tanggal);
            } catch (e) {
              // Try alternative format like dd-MM-yyyy
              try {
                date = DateFormat('dd-MM-yyyy').parse(transaction.tanggal);
              } catch (e2) {
                // Try another format like yyyy/MM/dd
                try {
                  date = DateFormat('yyyy/MM/dd').parse(transaction.tanggal);
                } catch (e3) {
                  print('Could not parse date: ${transaction.tanggal}');
                  continue;
                }
              }
            }

            // Calculate week number more accurately
            int weekOfMonth = ((date.day - 1) / 7).floor() + 1;
            // Ensure we don't exceed the number of weeks
            if (weekOfMonth > numberOfWeeks) {
              weekOfMonth = numberOfWeeks;
            }

            String weekKey = 'Minggu $weekOfMonth';

            if (weeklyData.containsKey(weekKey)) {
              if (transaction.jenis == 'pemasukan') {
                weeklyData[weekKey]!.pemasukan += transaction.jumlah.abs();
              } else if (transaction.jenis == 'pengeluaran') {
                weeklyData[weekKey]!.pengeluaran += transaction.jumlah.abs();
              }
            }
          } catch (e) {
            print(
              'Error processing transaction date: ${transaction.tanggal}, error: $e',
            );
          }
        }

        // Convert to chart data
        List<WeeklyChartData> chartDataList = [];
        for (int i = 1; i <= numberOfWeeks; i++) {
          String weekKey = 'Minggu $i';
          WeeklyData data = weeklyData[weekKey]!;
          chartDataList.add(
            WeeklyChartData(
              label: weekKey,
              pemasukan: data.pemasukan,
              pengeluaran: data.pengeluaran,
            ),
          );
        }

        print('Chart data: ${chartDataList.length} weeks');
        for (var week in chartDataList) {
          print(
            '${week.label}: Pemasukan=${week.pemasukan}, Pengeluaran=${week.pengeluaran}',
          );
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
        print("Response body: ${response.body}");
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
          height: 300,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pilih Bulan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
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
              ),
            ],
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

  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
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

                            // Chart Title and Legend
                            Text(
                              'Pemasukan vs Pengeluaran Mingguan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 10),

                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 20),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // Debug info (hapus ini setelah testing)
                            if (transactions.isNotEmpty)
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Debug: ${transactions.length} transaksi ditemukan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            SizedBox(height: 10),

                            // Chart
                            Expanded(
                              child:
                                  chartData.isEmpty
                                      ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.bar_chart,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Tidak ada data untuk bulan ini',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Total transaksi: ${transactions.length}',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : Container(
                                        padding: EdgeInsets.all(16),
                                        child: CustomPaint(
                                          painter: DoubleBarChartPainter(
                                            chartData,
                                            _formatChartValue,
                                          ),
                                          child: Container(),
                                        ),
                                      ),
                            ),

                            // Chart Labels
                            if (chartData.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
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

// Weekly Data Model
class WeeklyData {
  double pemasukan;
  double pengeluaran;

  WeeklyData({required this.pemasukan, required this.pengeluaran});
}

// Weekly Chart Data Model
class WeeklyChartData {
  final String label;
  final double pemasukan;
  final double pengeluaran;

  WeeklyChartData({
    required this.label,
    required this.pemasukan,
    required this.pengeluaran,
  });
}

// Improved Double Bar Chart Painter
class DoubleBarChartPainter extends CustomPainter {
  final List<WeeklyChartData> data;
  final String Function(double) formatValue;

  DoubleBarChartPainter(this.data, this.formatValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final incomePaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    final expensePaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final backgroundPaint =
        Paint()
          ..color = Colors.grey[100]!
          ..style = PaintingStyle.fill;

    final gridPaint =
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // Calculate chart dimensions
    final chartArea = Rect.fromLTWH(
      40, // Left margin for Y-axis labels
      20, // Top margin
      size.width - 60, // Chart width
      size.height - 40, // Chart height
    );

    // Find max value for scaling
    double maxValue = 0;
    for (var item in data) {
      maxValue = math.max(maxValue, math.max(item.pemasukan, item.pengeluaran));
    }

    // Add some padding to max value
    maxValue = maxValue * 1.1;
    if (maxValue == 0) maxValue = 100000; // Default if no data

    // Draw grid lines
    for (int i = 0; i <= 5; i++) {
      double y = chartArea.top + (chartArea.height / 5) * i;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );

      // Draw Y-axis labels
      double value = maxValue * (1 - i / 5);
      _drawYAxisLabel(canvas, formatValue(value), chartArea.left - 5, y);
    }

    // Calculate bar dimensions
    final groupWidth = chartArea.width / data.length;
    final barWidth = groupWidth * 0.3;
    final barSpacing = groupWidth * 0.05;

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final centerX = chartArea.left + (i + 0.5) * groupWidth;

      // Calculate bar heights
      final incomeHeight = (item.pemasukan / maxValue) * chartArea.height;
      final expenseHeight = (item.pengeluaran / maxValue) * chartArea.height;

      // Income bar (left)
      final incomeRect = Rect.fromLTWH(
        centerX - barWidth - barSpacing / 2,
        chartArea.bottom - incomeHeight,
        barWidth,
        incomeHeight,
      );

      // Expense bar (right)
      final expenseRect = Rect.fromLTWH(
        centerX + barSpacing / 2,
        chartArea.bottom - expenseHeight,
        barWidth,
        expenseHeight,
      );

      // Draw bars with rounded corners
      canvas.drawRRect(
        RRect.fromRectAndRadius(incomeRect, Radius.circular(4)),
        incomePaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(expenseRect, Radius.circular(4)),
        expensePaint,
      );

      // Draw value labels on top of bars
      if (item.pemasukan > 0) {
        _drawValueLabel(
          canvas,
          formatValue(item.pemasukan),
          incomeRect.center.dx,
          incomeRect.top - 5,
          Colors.green,
        );
      }

      if (item.pengeluaran > 0) {
        _drawValueLabel(
          canvas,
          formatValue(item.pengeluaran),
          expenseRect.center.dx,
          expenseRect.top - 5,
          Colors.red,
        );
      }
    }
  }

  void _drawYAxisLabel(Canvas canvas, String text, double x, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width, y - textPainter.height / 2),
    );
  }

  void _drawValueLabel(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

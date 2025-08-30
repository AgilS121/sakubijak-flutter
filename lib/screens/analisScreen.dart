import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sakubijak/helper/shared_preferences.dart';
import 'package:sakubijak/services/apiService.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:url_launcher/url_launcher.dart';

class AnalysisScreen extends StatefulWidget {
  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final List<String> months = const [
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

  // ===== Ringkasan =====
  double totalSaldoAllTime = 0; // <-- ALL-TIME saldo
  double totalPengeluaran = 0; // bulanan
  double totalPemasukan = 0; // bulanan
  double totalSaldo = 0; // bulanan (opsional, jika ingin dipakai)

  // ===== TAMBAHAN BARU =====
  bool resetSaldoBulanan = false; // setting apakah reset saldo tiap bulan
  double saldoAwalBulan = 0.0; // saldo awal bulan jika tidak reset

  List<WeeklyChartData> chartData = [];
  List<TransactionItem> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load setting dari SharedPreferences
    _initializeLocaleAndFetchData();
  }

  // ===== METHOD BARU UNTUK SETTING =====
  Future<void> _loadSettings() async {
    resetSaldoBulanan =
        await SharedPrefHelper.getBool('reset_saldo_bulanan') ?? false;
  }

  Future<void> _saveSettings() async {
    await SharedPrefHelper.setBool('reset_saldo_bulanan', resetSaldoBulanan);
  }

  Future<void> _initializeLocaleAndFetchData() async {
    await initializeDateFormatting('id_ID', null);
    final now = DateTime.now();
    setState(() {
      selectedMonth = DateFormat.MMMM('id_ID').format(now);
    });
    await fetchAnalysisData(now);
  }

  // =======================
  //  Parsing Helper
  // =======================
  List<TransactionItem> _parseTransactions(dynamic responseData) {
    List<dynamic> jsonData = [];

    if (responseData is List) {
      jsonData = responseData;
    } else if (responseData is Map) {
      if (responseData.containsKey('data')) {
        jsonData = responseData['data'] as List<dynamic>;
      } else if (responseData.containsKey('transactions')) {
        jsonData = responseData['transactions'] as List<dynamic>;
      } else {
        debugPrint('Unknown response structure: $responseData');
      }
    }

    final List<TransactionItem> transactionList = [];
    for (var item in jsonData) {
      try {
        String jenis = '';
        String kategori = '';

        if (item['kategori'] != null) {
          if (item['kategori'] is Map) {
            jenis = item['kategori']['jenis']?.toString() ?? '';
            kategori = item['kategori']['nama_kategori']?.toString() ?? '';
          } else if (item['kategori'] is String) {
            kategori = item['kategori'];
            if (item.containsKey('jenis')) {
              jenis = item['jenis']?.toString() ?? '';
            }
          }
        }

        if (jenis.isEmpty && item.containsKey('jenis')) {
          jenis = item['jenis']?.toString() ?? '';
        }

        if (jenis.isEmpty) {
          final amount =
              double.tryParse(item['jumlah']?.toString() ?? '0') ?? 0.0;
          jenis = amount > 0 ? 'pemasukan' : 'pengeluaran';
        }

        transactionList.add(
          TransactionItem(
            id:
                item['id'] is int
                    ? item['id']
                    : int.tryParse(item['id']?.toString() ?? '0') ?? 0,
            jumlah: double.tryParse(item['jumlah']?.toString() ?? '0') ?? 0.0,
            deskripsi: item['deskripsi']?.toString() ?? '',
            tanggal: item['tanggal']?.toString() ?? '',
            kategori: kategori,
            jenis: jenis.toLowerCase(),
          ),
        );
      } catch (e) {
        debugPrint('Error parsing transaction item: $e');
        debugPrint('Item: $item');
      }
    }
    return transactionList;
  }

  // =======================
  //  Ambil Saldo ALL-TIME
  // =======================
  Future<double> _fetchSaldoAllTime() async {
    final api = ApiService();
    await api.loadToken();

    // Rentang luas agar mencakup semua data
    const mulai = '1900-01-01';
    const sampai = '9999-12-31';

    try {
      final resp = await api.getLaporan(mulai, sampai);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final allTx = _parseTransactions(decoded);

        double pemasukan = 0.0;
        double pengeluaran = 0.0;

        for (final t in allTx) {
          if (t.jenis == 'pemasukan') {
            pemasukan += t.jumlah.abs();
          } else if (t.jenis == 'pengeluaran') {
            pengeluaran += t.jumlah.abs();
          }
        }
        return pemasukan - pengeluaran;
      } else {
        debugPrint('All-time status: ${resp.statusCode}');
        debugPrint('All-time body: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error fetch saldo all time: $e');
    }
    return 0.0;
  }

  // ===== METHOD BARU: Ambil Saldo Sampai Bulan Sebelumnya =====
  Future<double> _fetchSaldoSebelumBulan(DateTime bulanSekarang) async {
    if (resetSaldoBulanan) return 0.0; // jika reset, kembalikan 0

    final api = ApiService();
    await api.loadToken();

    // Hitung dari awal sampai hari terakhir bulan sebelumnya
    const mulai = '1900-01-01';
    final sampai = DateFormat('yyyy-MM-dd').format(
      DateTime(
        bulanSekarang.year,
        bulanSekarang.month,
        0,
      ), // hari terakhir bulan sebelumnya
    );

    try {
      final resp = await api.getLaporan(mulai, sampai);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final allTx = _parseTransactions(decoded);

        double pemasukan = 0.0;
        double pengeluaran = 0.0;

        for (final t in allTx) {
          if (t.jenis == 'pemasukan') {
            pemasukan += t.jumlah.abs();
          } else if (t.jenis == 'pengeluaran') {
            pengeluaran += t.jumlah.abs();
          }
        }
        return pemasukan - pengeluaran;
      }
    } catch (e) {
      debugPrint('Error fetch saldo sebelum bulan: $e');
    }
    return 0.0;
  }

  // =======================
  //  Ambil Data Bulanan (DIMODIFIKASI)
  // =======================
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
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final transactionList = _parseTransactions(decoded);

        // Hitung total pemasukan & pengeluaran bulanan
        double pemasukan = 0.0;
        double pengeluaran = 0.0;
        for (var t in transactionList) {
          if (t.jenis == 'pemasukan') {
            pemasukan += t.jumlah.abs();
          } else if (t.jenis == 'pengeluaran') {
            pengeluaran += t.jumlah.abs();
          }
        }

        // ---- Chart Mingguan ----
        final Map<String, WeeklyData> weeklyData = {};
        final daysInMonth =
            DateTime(monthDate.year, monthDate.month + 1, 0).day;
        final numberOfWeeks = (daysInMonth / 7).ceil();

        for (int i = 1; i <= numberOfWeeks; i++) {
          weeklyData['Minggu $i'] = WeeklyData(
            pemasukan: 0.0,
            pengeluaran: 0.0,
          );
        }

        for (final t in transactionList) {
          try {
            DateTime date;
            try {
              date = DateTime.parse(t.tanggal);
            } catch (_) {
              try {
                date = DateFormat('dd-MM-yyyy').parse(t.tanggal);
              } catch (_) {
                date = DateFormat('yyyy/MM/dd').parse(t.tanggal);
              }
            }
            int weekOfMonth = ((date.day - 1) / 7).floor() + 1;
            if (weekOfMonth > numberOfWeeks) weekOfMonth = numberOfWeeks;

            final key = 'Minggu $weekOfMonth';
            if (t.jenis == 'pemasukan') {
              weeklyData[key]!.pemasukan += t.jumlah.abs();
            } else if (t.jenis == 'pengeluaran') {
              weeklyData[key]!.pengeluaran += t.jumlah.abs();
            }
          } catch (e) {
            debugPrint('Error processing date ${t.tanggal}: $e');
          }
        }

        final chartDataList = List<WeeklyChartData>.generate(numberOfWeeks, (
          i,
        ) {
          final key = 'Minggu ${i + 1}';
          final w = weeklyData[key]!;
          return WeeklyChartData(
            label: key,
            pemasukan: w.pemasukan,
            pengeluaran: w.pengeluaran,
          );
        });

        // ---- MODIFIKASI: Hitung saldo berdasarkan setting ----
        final saldoSebelum = await _fetchSaldoSebelumBulan(monthDate);
        final saldoAll = await _fetchSaldoAllTime();

        setState(() {
          transactions = transactionList;
          totalPemasukan = pemasukan; // bulanan
          totalPengeluaran = pengeluaran; // bulanan
          totalSaldo = pemasukan - pengeluaran; // bulanan
          saldoAwalBulan = saldoSebelum; // saldo sebelum bulan ini
          // Jika reset bulanan, gunakan saldo bulan ini saja. Jika tidak, gunakan all-time
          totalSaldoAllTime =
              resetSaldoBulanan
                  ? (saldoSebelum + pemasukan - pengeluaran)
                  : saldoAll;
          chartData = chartDataList;
        });
      } else {
        debugPrint("Gagal mengambil data laporan: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching laporan: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  // ===== DIALOG SETTING BARU =====
  void _showSettingDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Pengaturan Saldo'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pilih cara perhitungan saldo:'),
                      const SizedBox(height: 10),
                      RadioListTile<bool>(
                        title: const Text('Akumulatif dari awal'),
                        subtitle: const Text(
                          'Saldo dihitung dari semua transaksi',
                        ),
                        value: false,
                        groupValue: resetSaldoBulanan,
                        onChanged: (value) {
                          setDialogState(() {
                            resetSaldoBulanan = value!;
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: const Text('Reset setiap bulan'),
                        subtitle: const Text(
                          'Saldo dimulai dari 0 setiap bulan',
                        ),
                        value: true,
                        groupValue: resetSaldoBulanan,
                        onChanged: (value) {
                          setDialogState(() {
                            resetSaldoBulanan = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveSettings();
                        // Refresh data dengan setting baru
                        final now = DateTime.now();
                        final monthIndex = months.indexOf(selectedMonth);
                        final selectedDate = DateTime(
                          now.year,
                          monthIndex + 1,
                          1,
                        );
                        fetchAnalysisData(selectedDate);
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showMonthSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
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
                              ? const Icon(
                                Icons.check,
                                color: Color(0xFF00BFA5),
                              )
                              : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedMonth = month;
                        });
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

    int monthIndex = months.indexOf(selectedMonth);
    final now = DateTime.now();
    final selectedDate = DateTime(now.year, monthIndex + 1, 1);

    final mulai = DateFormat('yyyy-MM-dd').format(selectedDate);
    final sampai = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(selectedDate.year, selectedDate.month + 1, 0));

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Mengunduh laporan ...'),
                ],
              ),
            ),
      );

      final response = await api.eksporData('pdf', mulai, sampai);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Export status: ${response.statusCode}');
      debugPrint('Export body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          String? fileUrl = json['file_url'];
          if (fileUrl != null) {
            final launched = await launchUrl(
              Uri.parse(fileUrl),
              mode: LaunchMode.externalApplication,
            );
            if (launched) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Laporan $selectedMonth berhasil dibuka'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gagal membuka browser'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('URL file tidak ditemukan'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(json['message'] ?? 'Gagal mengekspor data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi berakhir. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh laporan (${response.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUrlDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Download Manual'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Silakan copy URL berikut dan buka di browser:'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    url,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
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
      backgroundColor: const Color(0xFF00BFA5),
      body: SafeArea(
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : Column(
                  children: [
                    // ===== Header (DIMODIFIKASI) =====
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          const Text(
                            'Grafik Keuangan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // TAMBAHAN: Icon setting
                          GestureDetector(
                            onTap: _showSettingDialog,
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _downloadReport,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ===== Summary (DIMODIFIKASI) =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Saldo berdasarkan setting
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resetSaldoBulanan
                                        ? 'Saldo Bulan Ini'
                                        : 'Saldo Total',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(totalSaldoAllTime)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Tampilkan saldo awal bulan jika tidak reset
                                  if (!resetSaldoBulanan && saldoAwalBulan != 0)
                                    Text(
                                      'Saldo awal bulan: Rp ${_formatCurrency(saldoAwalBulan)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white60,
                                      ),
                                    ),
                                ],
                              ),
                              // Pengeluaran Bulan Ini
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(totalPengeluaran)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total Pemasukan: Rp ${_formatCurrency(totalPemasukan)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Chart Section =====
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
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
                                    padding: const EdgeInsets.symmetric(
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Ringkasan Pemasukan dan Pengeluaran Mingguan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),

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
                                const SizedBox(width: 5),
                                Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (transactions.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${transactions.length} transaksi ditemukan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),

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
                                            const SizedBox(height: 16),
                                            Text(
                                              'Tidak ada data untuk bulan ini',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
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
                                        padding: const EdgeInsets.all(16),
                                        child: CustomPaint(
                                          painter: DoubleBarChartPainter(
                                            chartData,
                                            _formatChartValue,
                                          ),
                                          child: Container(),
                                        ),
                                      ),
                            ),

                            if (chartData.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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

// ===== Models =====
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

class WeeklyData {
  double pemasukan;
  double pengeluaran;
  WeeklyData({required this.pemasukan, required this.pengeluaran});
}

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

// ===== Custom Painter for Double Bar Chart =====
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
    final gridPaint =
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final chartArea = Rect.fromLTWH(
      40, // left padding for Y labels
      20, // top
      size.width - 60,
      size.height - 40,
    );

    // Calculate maximum value for scaling
    double maxValue = 0;
    for (var item in data) {
      maxValue = math.max(maxValue, math.max(item.pemasukan, item.pengeluaran));
    }
    maxValue = maxValue * 1.1; // Add 10% padding
    if (maxValue == 0) maxValue = 100000; // Default minimum

    // Draw grid lines and Y labels
    for (int i = 0; i <= 5; i++) {
      final y = chartArea.top + (chartArea.height / 5) * i;
      canvas.drawLine(
        Offset(chartArea.left, y),
        Offset(chartArea.right, y),
        gridPaint,
      );

      final value = maxValue * (1 - i / 5);
      _drawYAxisLabel(canvas, formatValue(value), chartArea.left - 5, y);
    }

    // Draw bars
    final groupWidth = chartArea.width / data.length;
    final barWidth = groupWidth * 0.3;
    final barSpacing = groupWidth * 0.05;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final centerX = chartArea.left + (i + 0.5) * groupWidth;

      // Calculate bar heights
      final incomeHeight = (item.pemasukan / maxValue) * chartArea.height;
      final expenseHeight = (item.pengeluaran / maxValue) * chartArea.height;

      // Income bar (left side)
      final incomeRect = Rect.fromLTWH(
        centerX - barWidth - barSpacing / 2,
        chartArea.bottom - incomeHeight,
        barWidth,
        incomeHeight,
      );

      // Expense bar (right side)
      final expenseRect = Rect.fromLTWH(
        centerX + barSpacing / 2,
        chartArea.bottom - expenseHeight,
        barWidth,
        expenseHeight,
      );

      // Draw bars with rounded corners
      canvas.drawRRect(
        RRect.fromRectAndRadius(incomeRect, const Radius.circular(4)),
        incomePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(expenseRect, const Radius.circular(4)),
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
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
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

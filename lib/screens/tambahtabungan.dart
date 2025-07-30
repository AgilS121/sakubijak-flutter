import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakubijak/services/apiService.dart';

class TambahTabunganDialog extends StatefulWidget {
  final Map<String, dynamic> tujuan;
  final Function() onSuccess;

  const TambahTabunganDialog({
    Key? key,
    required this.tujuan,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _TambahTabunganDialogState createState() => _TambahTabunganDialogState();
}

class _TambahTabunganDialogState extends State<TambahTabunganDialog> {
  final TextEditingController _jumlahController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jumlahController.text = 'Rp 0';
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  double _parseCurrency(String text) {
    final cleanText = text.replaceAll(RegExp(r'[Rp\s\.]'), '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  Future<void> _tambahTabungan() async {
    final jumlah = _parseCurrency(_jumlahController.text);

    if (jumlah <= 0) {
      _showSnackBar('Jumlah tabungan harus lebih dari 0');
      return;
    }

    final targetUang =
        double.tryParse(widget.tujuan['target_uang'].toString()) ?? 0.0;
    final uangTerkumpul =
        double.tryParse(widget.tujuan['uang_terkumpul'].toString()) ?? 0.0;
    final sisaTarget = targetUang - uangTerkumpul;

    if (jumlah > sisaTarget) {
      _showSnackBar(
        'Jumlah tabungan melebihi sisa target (Rp ${_formatCurrency(sisaTarget)})',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService();
      await api.loadToken();

      final idTujuan = widget.tujuan['id'];
      final uangBaruTerkumpul = (uangTerkumpul + jumlah).toInt();

      // Gunakan method updateTujuan yang sudah ada
      final response = await api.updateTujuan(idTujuan, uangBaruTerkumpul);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Tabungan berhasil ditambahkan!', isSuccess: true);
        widget.onSuccess();
        Navigator.of(context).pop();
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Gagal menambahkan tabungan';

        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }

        _showSnackBar(errorMessage);
      }
    } catch (e) {
      print('Error adding savings: $e');
      _showSnackBar('Terjadi kesalahan saat menambahkan tabungan');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetUang =
        double.tryParse(widget.tujuan['target_uang'].toString()) ?? 0.0;
    final uangTerkumpul =
        double.tryParse(widget.tujuan['uang_terkumpul'].toString()) ?? 0.0;
    final sisaTarget = targetUang - uangTerkumpul;
    final progress = targetUang > 0 ? (uangTerkumpul / targetUang) : 0.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.savings, color: Color(0xFF00BFA5), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tambah Tabungan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Info Tujuan
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xFFF0F8F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF00BFA5).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tujuan['judul'] ?? 'Tujuan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Rp ${_formatCurrency(targetUang)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terkumpul:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Rp ${_formatCurrency(uangTerkumpul)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00BFA5),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sisa:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Rp ${_formatCurrency(sisaTarget)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00BFA5),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% tercapai',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Input Jumlah
            Text(
              'Jumlah Tabungan',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) {
                    return TextEditingValue(
                      text: 'Rp 0',
                      selection: TextSelection.collapsed(offset: 3),
                    );
                  }
                  final number = int.tryParse(newValue.text) ?? 0;
                  final formatted = _formatCurrency(number.toDouble());
                  return TextEditingValue(
                    text: 'Rp $formatted',
                    selection: TextSelection.collapsed(
                      offset: formatted.length + 3,
                    ),
                  );
                }),
              ],
              decoration: InputDecoration(
                hintText: 'Rp 0',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF00BFA5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _tambahTabungan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00BFA5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'Tambah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }
}

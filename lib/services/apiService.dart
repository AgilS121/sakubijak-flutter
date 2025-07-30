import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sakubijak/helper/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://www.sakubijak.adservices.site/api';
  String? _token;

  Future<void> loadToken() async {
    _token = await SharedPrefHelper.getToken();
  }

  void setToken(String token) {
    _token = token;
  }

  Future<Map<String, String>> _getHeaders() async {
    if (_token == null) {
      await loadToken();
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Synchronous headers getter for backward compatibility
  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Authentication endpoints
  Future<http.Response> register(
    String nama,
    String email,
    String password,
    String pin,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
        'pin': pin,
      }),
    );
  }

  Future<http.Response> login(String email, String password) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  Future<http.Response> logout() async {
    final headers = await _getHeaders();
    return http.post(Uri.parse('$baseUrl/auth/logout'), headers: headers);
  }

  // Transaksi endpoints
  Future<http.Response> getTransaksi() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/transaksi'), headers: headers);
  }

  Future<http.Response> createTransaksi(
    int idKategori,
    int jumlah,
    String deskripsi,
    String tanggal,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: headers,
      body: jsonEncode({
        'id_kategori': idKategori,
        'jumlah': jumlah,
        'deskripsi': deskripsi,
        'tanggal': tanggal,
      }),
    );
  }

  Future<http.Response> getTransaksiDetail(int id) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/transaksi/$id'), headers: headers);
  }

  Future<http.Response> updateTransaksi(
    int id,
    int jumlah,
    String deskripsi,
  ) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('$baseUrl/transaksi/$id'),
      headers: headers,
      body: jsonEncode({'jumlah': jumlah, 'deskripsi': deskripsi}),
    );
  }

  Future<http.Response> deleteTransaksi(int id) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('$baseUrl/transaksi/$id'), headers: headers);
  }

  // Kategori endpoints
  Future<http.Response> getKategori() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/kategori'), headers: headers);
  }

  Future<http.Response> createKategori(
    String namaKategori,
    String jenis,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/kategori'),
      headers: headers,
      body: jsonEncode({'nama_kategori': namaKategori, 'jenis': jenis}),
    );
  }

  Future<http.Response> getKategoriDetail(int id) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/kategori/$id'), headers: headers);
  }

  Future<http.Response> updateKategori(
    int id,
    String namaKategori,
    String jenis,
  ) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('$baseUrl/kategori/$id'),
      headers: headers,
      body: jsonEncode({'nama_kategori': namaKategori, 'jenis': jenis}),
    );
  }

  Future<http.Response> deleteKategori(int id) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('$baseUrl/kategori/$id'), headers: headers);
  }

  // Token validation
  Future<bool> validateToken() async {
    if (_token == null) {
      await loadToken();
    }

    if (_token == null) {
      return false;
    }

    try {
      final url = Uri.parse('$baseUrl/user'); // Fixed: removed duplicate /api
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Token validation failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Tujuan Keuangan endpoints
  Future<http.Response> getTujuan() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/tujuan-keuangan'), headers: headers);
  }

  Future<http.Response> createTujuan(
    String judul,
    int targetUang,
    int uangTerkumpul,
    String tanggalTarget,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/tujuan-keuangan'),
      headers: headers,
      body: jsonEncode({
        'judul': judul,
        'target_uang': targetUang,
        'uang_terkumpul': uangTerkumpul,
        'tanggal_target': tanggalTarget,
      }),
    );
  }

  Future<http.Response> getTujuanDetail(int id) async {
    final headers = await _getHeaders();
    return http.get(
      Uri.parse('$baseUrl/tujuan-keuangan/$id'),
      headers: headers,
    );
  }

  Future<http.Response> updateTujuan(int id, int uangTerkumpul) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('$baseUrl/tujuan-keuangan/$id'),
      headers: headers,
      body: jsonEncode({'uang_terkumpul': uangTerkumpul}),
    );
  }

  Future<http.Response> deleteTujuan(int id) async {
    final headers = await _getHeaders();
    return http.delete(
      Uri.parse('$baseUrl/tujuan-keuangan/$id'),
      headers: headers,
    );
  }

  // Notifikasi endpoints
  Future<http.Response> getNotifikasi() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/notifikasi'), headers: headers);
  }

  Future<http.Response> getTagihanJatuhTempo() async {
    final headers = await _getHeaders();
    return http.get(
      Uri.parse('$baseUrl/notifikasi/tagihan-jatuh-tempo'),
      headers: headers,
    );
  }

  Future<http.Response> getUnreadCount() async {
    final headers = await _getHeaders();
    return http.get(
      Uri.parse('$baseUrl/notifikasi/unread-count'),
      headers: headers,
    );
  }

  Future<http.Response> markAsRead(int id) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/notifikasi/$id/mark-read'),
      headers: headers,
    );
  }

  // Tagihan endpoints
  Future<http.Response> getTagihan() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/tagihan'), headers: headers);
  }

  Future<http.Response> createTagihan(
    String judul,
    int jumlah,
    String tanggalJatuhTempo,
    bool sudahDibayar,
    String pengulangan,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/tagihan'),
      headers: headers,
      body: jsonEncode({
        'judul_tagihan': judul,
        'jumlah': jumlah,
        'tanggal_jatuh_tempo': tanggalJatuhTempo,
        'sudah_dibayar': sudahDibayar,
        'pengulangan': pengulangan,
      }),
    );
  }

  Future<http.Response> getTagihanDetail(int id) async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/tagihan/$id'), headers: headers);
  }

  Future<http.Response> updateTagihan(int id, bool sudahDibayar) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('$baseUrl/tagihan/$id'),
      headers: headers,
      body: jsonEncode({'sudah_dibayar': sudahDibayar}),
    );
  }

  Future<http.Response> deleteTagihan(int id) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('$baseUrl/tagihan/$id'), headers: headers);
  }

  // Sistem endpoints
  Future<http.Response> getSistem() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/admin/sistem'), headers: headers);
  }

  Future<http.Response> updateSistem(
    String logo,
    String deskripsi,
    String kontakResmi,
    String alamatAplikasi,
  ) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/admin/sistem'),
      headers: headers,
      body: jsonEncode({
        'logo': logo,
        'deskripsi': deskripsi,
        'kontak_resmi': kontakResmi,
        'alamat_aplikasi': alamatAplikasi,
      }),
    );
  }

  // Log endpoints
  Future<http.Response> getLog() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/admin/logs'), headers: headers);
  }

  Future<http.Response> createLog(String aksi) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/log'),
      headers: headers,
      body: jsonEncode({'aksi': aksi}),
    );
  }

  // Admin utility endpoints
  Future<http.Response> performBackup() async {
    final headers = await _getHeaders();
    return http.post(Uri.parse('$baseUrl/admin/backup'), headers: headers);
  }

  Future<http.Response> clearCache() async {
    final headers = await _getHeaders();
    return http.post(Uri.parse('$baseUrl/admin/clear-cache'), headers: headers);
  }

  Future<http.Response> resetSettings() async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/admin/reset-settings'),
      headers: headers,
    );
  }

  Future<http.Response> getTotalUsers() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/admin/total-users'), headers: headers);
  }

  Future<http.Response> getTotalKategori() async {
    final headers = await _getHeaders();
    return http.get(
      Uri.parse('$baseUrl/admin/total-kategori'),
      headers: headers,
    );
  }

  Future<http.Response> getAllUsers() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/admin/users'), headers: headers);
  }

  Future<http.Response> getSummary() async {
    final headers = await _getHeaders();
    return http.get(Uri.parse('$baseUrl/summary'), headers: headers);
  }

  Future<http.Response> eksporData(
    String jenisFile,
    String tanggalMulai,
    String tanggalSampai,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/ekspor');

    print('Ekspor URL: $url');
    print('Token: $_token');
    print('Jenis File: $jenisFile');
    print('Tanggal Mulai: $tanggalMulai');
    print('Tanggal Sampai: $tanggalSampai');

    final body = jsonEncode({
      'jenis_file': jenisFile,
      'tanggal_mulai': tanggalMulai,
      'tanggal_sampai': tanggalSampai,
    });

    print('Request headers: $headers');
    print('Request body: $body');

    final response = await http.post(url, headers: headers, body: body);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    return response;
  }

  Future<http.Response> getLaporan(String mulai, String sampai) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/laporan?mulai=$mulai&sampai=$sampai');

    final response = await http.get(url, headers: headers);
    return response;
  }

  Future<http.Response> updateProfile(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/profile/update');

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    return response;
  }

  Future<http.Response> getProfile() async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/profile');

    final response = await http.get(url, headers: headers);
    return response;
  }

  Future<http.Response> setPin(String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set-pin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'pin': pin}),
    );
    return response;
  }

  // Login dengan PIN
  Future<http.Response> loginWithPin(String email, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pin-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'pin': pin}),
    );
    return response;
  }

  // Cek status PIN user
  Future<http.Response> checkPinStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/check-pin-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    return response;
  }

  // Update PIN
  Future<http.Response> updatePin(String currentPin, String newPin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-pin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'current_pin': currentPin,
        'new_pin': newPin,
        'confirm_pin': newPin,
      }),
    );
    return response;
  }

  // Reset PIN (admin only)
  Future<http.Response> resetPin(String email, String newPin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-pin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'email': email, 'new_pin': newPin}),
    );
    return response;
  }

  Future<http.Response> getAnggaran() async {
    await loadToken();

    final response = await http.get(
      Uri.parse('$baseUrl/anggaran'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    print('Get Anggaran Response: ${response.statusCode} - ${response.body}');
    return response;
  }

  // Method untuk membuat anggaran baru
  Future<http.Response> createAnggaran(Map<String, dynamic> data) async {
    await loadToken();

    final response = await http.post(
      Uri.parse('$baseUrl/anggaran'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(data),
    );

    print(
      'Create Anggaran Response: ${response.statusCode} - ${response.body}',
    );
    return response;
  }

  // Method untuk mengupdate anggaran
  Future<http.Response> updateAnggaran(
    String id,
    Map<String, dynamic> data,
  ) async {
    await loadToken();

    final response = await http.put(
      Uri.parse('$baseUrl/anggaran/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(data),
    );

    print(
      'Update Anggaran Response: ${response.statusCode} - ${response.body}',
    );
    return response;
  }

  // Method untuk mendapatkan detail anggaran
  Future<http.Response> getAnggaranDetail(String id) async {
    await loadToken();

    final response = await http.get(
      Uri.parse('$baseUrl/anggaran/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    print(
      'Get Anggaran Detail Response: ${response.statusCode} - ${response.body}',
    );
    return response;
  }

  // Method untuk menghapus anggaran
  Future<http.Response> deleteAnggaran(String id) async {
    await loadToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/anggaran/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    print(
      'Delete Anggaran Response: ${response.statusCode} - ${response.body}',
    );
    return response;
  }

  Future<http.Response> tambahTabungan(int idTujuan, int jumlahTabungan) async {
    final headers = await _getHeaders();
    return http.post(
      Uri.parse('$baseUrl/tujuan-keuangan/$idTujuan/tambah-tabungan'),
      headers: headers,
      body: jsonEncode({'jumlah_tabungan': jumlahTabungan}),
    );
  }

  // Method alternatif jika endpoint berbeda
  Future<http.Response> tambahTabunganTujuan(
    int idTujuan,
    int jumlahBaru,
  ) async {
    final headers = await _getHeaders();
    return http.put(
      Uri.parse('$baseUrl/tujuan-keuangan/$idTujuan/tabungan'),
      headers: headers,
      body: jsonEncode({'tambah_uang': jumlahBaru}),
    );
  }
}

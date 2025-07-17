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

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Authentication endpoints
  Future<http.Response> register(
    String nama,
    String email,
    String password,
    String pin,
  ) {
    return http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
        'pin': pin,
      }),
    );
  }

  Future<http.Response> login(String email, String password) {
    return http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  Future<http.Response> logout() {
    return http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
  }

  // Transaksi endpoints
  Future<http.Response> getTransaksi() {
    return http.get(Uri.parse('$baseUrl/transaksi'), headers: _headers);
  }

  Future<http.Response> createTransaksi(
    int idKategori,
    int jumlah,
    String deskripsi,
    String tanggal,
  ) {
    return http.post(
      Uri.parse('$baseUrl/transaksi'),
      headers: _headers,
      body: jsonEncode({
        'id_kategori': idKategori,
        'jumlah': jumlah,
        'deskripsi': deskripsi,
        'tanggal': tanggal,
      }),
    );
  }

  Future<http.Response> getTransaksiDetail(int id) {
    return http.get(Uri.parse('$baseUrl/transaksi/$id'), headers: _headers);
  }

  Future<http.Response> updateTransaksi(int id, int jumlah, String deskripsi) {
    return http.put(
      Uri.parse('$baseUrl/transaksi/$id'),
      headers: _headers,
      body: jsonEncode({'jumlah': jumlah, 'deskripsi': deskripsi}),
    );
  }

  Future<http.Response> deleteTransaksi(int id) {
    return http.delete(Uri.parse('$baseUrl/transaksi/$id'), headers: _headers);
  }

  // Kategori endpoints
  Future<http.Response> getKategori() {
    return http.get(Uri.parse('$baseUrl/kategori'), headers: _headers);
  }

  Future<http.Response> createKategori(String namaKategori, String jenis) {
    return http.post(
      Uri.parse('$baseUrl/kategori'),
      headers: _headers,
      body: jsonEncode({'nama_kategori': namaKategori, 'jenis': jenis}),
    );
  }

  Future<http.Response> getKategoriDetail(int id) {
    return http.get(Uri.parse('$baseUrl/kategori/$id'), headers: _headers);
  }

  Future<http.Response> updateKategori(
    int id,
    String namaKategori,
    String jenis,
  ) {
    return http.put(
      Uri.parse('$baseUrl/kategori/$id'),
      headers: _headers,
      body: jsonEncode({'nama_kategori': namaKategori, 'jenis': jenis}),
    );
  }

  Future<http.Response> deleteKategori(int id) {
    return http.delete(Uri.parse('$baseUrl/kategori/$id'), headers: _headers);
  }

  // Laporan endpoints
  Future<http.Response> getLaporan(String mulai, String sampai) {
    final uri = Uri.parse(
      '$baseUrl/laporan',
    ).replace(queryParameters: {'mulai': mulai, 'sampai': sampai});
    return http.get(uri, headers: _headers);
  }

  // Tujuan Keuangan endpoints
  Future<http.Response> getTujuan() {
    return http.get(Uri.parse('$baseUrl/tujuan-keuangan'), headers: _headers);
  }

  Future<http.Response> createTujuan(
    String judul,
    int targetUang,
    int uangTerkumpul,
    String tanggalTarget,
  ) {
    return http.post(
      Uri.parse('$baseUrl/tujuan-keuangan'),
      headers: _headers,
      body: jsonEncode({
        'judul': judul,
        'target_uang': targetUang,
        'uang_terkumpul': uangTerkumpul,
        'tanggal_target': tanggalTarget,
      }),
    );
  }

  Future<http.Response> getTujuanDetail(int id) {
    return http.get(
      Uri.parse('$baseUrl/tujuan-keuangan/$id'),
      headers: _headers,
    );
  }

  Future<http.Response> updateTujuan(int id, int uangTerkumpul) {
    return http.put(
      Uri.parse('$baseUrl/tujuan-keuangan/$id'),
      headers: _headers,
      body: jsonEncode({'uang_terkumpul': uangTerkumpul}),
    );
  }

  Future<http.Response> deleteTujuan(int id) {
    return http.delete(
      Uri.parse('$baseUrl/tujuan-keuangan/$id'),
      headers: _headers,
    );
  }

  // Tagihan endpoints
  Future<http.Response> getTagihan() {
    return http.get(Uri.parse('$baseUrl/tagihan'), headers: _headers);
  }

  Future<http.Response> createTagihan(
    String judul,
    int jumlah,
    String tanggalJatuhTempo,
    bool sudahDibayar,
    String pengulangan,
  ) {
    return http.post(
      Uri.parse('$baseUrl/tagihan'),
      headers: _headers,
      body: jsonEncode({
        'judul_tagihan': judul,
        'jumlah': jumlah,
        'tanggal_jatuh_tempo': tanggalJatuhTempo,
        'sudah_dibayar': sudahDibayar,
        'pengulangan': pengulangan,
      }),
    );
  }

  Future<http.Response> getTagihanDetail(int id) {
    return http.get(Uri.parse('$baseUrl/tagihan/$id'), headers: _headers);
  }

  Future<http.Response> updateTagihan(int id, bool sudahDibayar) {
    return http.put(
      Uri.parse('$baseUrl/tagihan/$id'),
      headers: _headers,
      body: jsonEncode({'sudah_dibayar': sudahDibayar}),
    );
  }

  Future<http.Response> deleteTagihan(int id) {
    return http.delete(Uri.parse('$baseUrl/tagihan/$id'), headers: _headers);
  }

  // Ekspor Data endpoints
  Future<http.Response> eksporData(
    String jenisFile,
    String tanggalMulai,
    String tanggalSampai,
  ) {
    return http.post(
      Uri.parse('$baseUrl/ekspor'),
      headers: _headers,
      body: jsonEncode({
        'jenis_file': jenisFile,
        'tanggal_mulai': tanggalMulai,
        'tanggal_sampai': tanggalSampai,
      }),
    );
  }

  // Sistem endpoints
  Future<http.Response> getSistem() {
    return http.get(Uri.parse('$baseUrl/admin/sistem'), headers: _headers);
  }

  Future<http.Response> updateSistem(
    String logo,
    String deskripsi,
    String kontakResmi,
    String alamatAplikasi,
  ) {
    return http.post(
      Uri.parse('$baseUrl/admin/sistem'),
      headers: _headers,
      body: jsonEncode({
        'logo': logo,
        'deskripsi': deskripsi,
        'kontak_resmi': kontakResmi,
        'alamat_aplikasi': alamatAplikasi,
      }),
    );
  }

  // Log endpoints
  Future<http.Response> getLog({String? tanggal}) {
    Uri uri = Uri.parse('$baseUrl/log');
    if (tanggal != null) {
      uri = uri.replace(queryParameters: {'tanggal': tanggal});
    }
    return http.get(uri, headers: _headers);
  }

  Future<http.Response> createLog(String aksi) {
    return http.post(
      Uri.parse('$baseUrl/log'),
      headers: _headers,
      body: jsonEncode({'aksi': aksi}),
    );
  }

  // Admin utility endpoints (optional - jika diperlukan di backend)
  Future<http.Response> performBackup() {
    return http.post(Uri.parse('$baseUrl/admin/backup'), headers: _headers);
  }

  Future<http.Response> clearCache() {
    return http.post(
      Uri.parse('$baseUrl/admin/clear-cache'),
      headers: _headers,
    );
  }

  Future<http.Response> resetSettings() {
    return http.post(
      Uri.parse('$baseUrl/admin/reset-settings'),
      headers: _headers,
    );
  }

  Future<http.Response> getTotalUsers() {
    return http.get(Uri.parse('$baseUrl/admin/total-users'), headers: _headers);
  }

  Future<http.Response> getTotalKategori() {
    return http.get(
      Uri.parse('$baseUrl/admin/total-kategori'),
      headers: _headers,
    );
  }

  Future<http.Response> getAllUsers() {
    return http.get(Uri.parse('$baseUrl/admin/users'), headers: _headers);
  }
}

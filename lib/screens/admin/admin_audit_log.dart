// simple_audit_log_test.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';
import 'package:intl/intl.dart';

class SimpleAuditLogTest extends StatefulWidget {
  @override
  _SimpleAuditLogTestState createState() => _SimpleAuditLogTestState();
}

class _SimpleAuditLogTestState extends State<SimpleAuditLogTest> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.getLog();
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(
            data['data'],
          );

          setState(() {
            _auditLogs = logs;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Format data tidak sesuai';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Log Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadAuditLogs),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAuditLogs,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
              : _auditLogs.isEmpty
              ? Center(child: Text('Tidak ada data log'))
              : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Total logs: ${_auditLogs.length}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _auditLogs.length,
                      itemBuilder: (context, index) {
                        final log = _auditLogs[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              'ID: ${log['id']} - ${log['aksi'] ?? 'No Action'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (log['pengguna'] != null)
                                  Text(
                                    'User: ${log['pengguna']['nama']} (${log['pengguna']['email']})',
                                  ),
                                if (log['pengguna'] != null)
                                  Text('Role: ${log['pengguna']['role']}'),
                                Text('Tanggal: ${log['tanggal']}'),
                                Text('Created: ${log['created_at']}'),
                              ],
                            ),
                            trailing: Text('User ID: ${log['id_pengguna']}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

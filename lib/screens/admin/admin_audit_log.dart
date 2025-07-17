// admin_audit_log_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';
import 'package:intl/intl.dart';

class AdminAuditLogScreen extends StatefulWidget {
  @override
  _AdminAuditLogScreenState createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedAction = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.getLog();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> logs = [];

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          logs = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          logs = List<Map<String, dynamic>>.from(data);
        }

        setState(() {
          _auditLogs = logs;
          _isLoading = false;
        });
      } else {
        print('Error loading audit logs: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading audit logs: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _auditLogs.where((log) {
      // Filter by search query
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch =
            (log['user_name'] ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (log['action'] ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (log['description'] ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }

      // Filter by action
      bool matchesAction =
          _selectedAction == 'all' || log['action'] == _selectedAction;

      // Filter by date range
      bool matchesDate = true;
      if (_startDate != null || _endDate != null) {
        DateTime? logDate = DateTime.tryParse(log['created_at'] ?? '');
        if (logDate != null) {
          if (_startDate != null && logDate.isBefore(_startDate!)) {
            matchesDate = false;
          }
          if (_endDate != null &&
              logDate.isAfter(_endDate!.add(Duration(days: 1)))) {
            matchesDate = false;
          }
        }
      }

      return matchesSearch && matchesAction && matchesDate;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Filter Audit Log'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedAction,
                        decoration: InputDecoration(
                          labelText: 'Aksi',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Semua Aksi'),
                          ),
                          DropdownMenuItem(
                            value: 'login',
                            child: Text('Login'),
                          ),
                          DropdownMenuItem(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                          DropdownMenuItem(
                            value: 'create',
                            child: Text('Buat'),
                          ),
                          DropdownMenuItem(
                            value: 'update',
                            child: Text('Update'),
                          ),
                          DropdownMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value!;
                          });
                        },
                      ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Tanggal Mulai',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _startDate = date;
                                  });
                                }
                              },
                              controller: TextEditingController(
                                text:
                                    _startDate != null
                                        ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_startDate!)
                                        : '',
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Tanggal Akhir',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _endDate = date;
                                  });
                                }
                              },
                              controller: TextEditingController(
                                text:
                                    _endDate != null
                                        ? DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(_endDate!)
                                        : '',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedAction = 'all';
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      child: Text('Reset'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        this.setState(() {});
                      },
                      child: Text('Terapkan'),
                    ),
                  ],
                ),
          ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'create':
        return Colors.blue;
      case 'update':
        return Colors.amber;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Log'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadAuditLogs),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan user, aksi, atau deskripsi...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_selectedAction != 'all' ||
              _startDate != null ||
              _endDate != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text('Filter aktif: '),
                  if (_selectedAction != 'all')
                    Chip(
                      label: Text(_selectedAction),
                      onDeleted: () {
                        setState(() {
                          _selectedAction = 'all';
                        });
                      },
                    ),
                  if (_startDate != null || _endDate != null)
                    Chip(
                      label: Text(
                        '${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Mulai'} - ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Akhir'}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredLogs.isEmpty
                    ? Center(child: Text('Tidak ada log audit ditemukan'))
                    : ListView.builder(
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        final createdAt = DateTime.tryParse(
                          log['created_at'] ?? '',
                        );

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getActionColor(
                                log['action'] ?? '',
                              ),
                              child: Icon(
                                _getActionIcon(log['action'] ?? ''),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${log['user_name'] ?? 'Unknown'} - ${log['action'] ?? 'Unknown'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (log['description'] != null)
                                  Text(log['description']),
                                if (createdAt != null)
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                log['ip_address'] != null
                                    ? Tooltip(
                                      message: 'IP: ${log['ip_address']}',
                                      child: Icon(Icons.location_on, size: 16),
                                    )
                                    : null,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

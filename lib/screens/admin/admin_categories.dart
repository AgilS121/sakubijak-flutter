// admin_categories_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sakubijak/services/apiService.dart';

class AdminCategoriesScreen extends StatefulWidget {
  @override
  _AdminCategoriesScreenState createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.getKategori();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> categories = [];

        if (data is Map<String, dynamic> && data.containsKey('data')) {
          categories = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          categories = List<Map<String, dynamic>>.from(data);
        }

        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      } else {
        print('Error loading categories: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories.where((category) {
      return category['nama_kategori'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  void _showAddCategoryDialog() {
    final _nameController = TextEditingController();
    String _selectedType = 'pemasukan';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Tambah Kategori'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Jenis',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'pemasukan',
                            child: Text('Pemasukan'),
                          ),
                          DropdownMenuItem(
                            value: 'pengeluaran',
                            child: Text('Pengeluaran'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          _addCategory(_nameController.text, _selectedType);
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final _nameController = TextEditingController(
      text: category['nama_kategori'],
    );
    String _selectedType = category['jenis'];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Edit Kategori'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Jenis',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'pemasukan',
                            child: Text('Pemasukan'),
                          ),
                          DropdownMenuItem(
                            value: 'pengeluaran',
                            child: Text('Pengeluaran'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          _updateCategory(
                            category['id'],
                            _nameController.text,
                            _selectedType,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Text('Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _addCategory(String name, String type) async {
    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.createKategori(name, type);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori berhasil ditambahkan')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambahkan kategori')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateCategory(int id, String name, String type) async {
    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.updateKategori(id, name, type);
      if (response.statusCode == 200) {
        _loadCategories();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kategori berhasil diperbarui')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui kategori')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteCategory(int id) async {
    final api = ApiService();
    await api.loadToken();

    try {
      final response = await api.deleteKategori(id);
      if (response.statusCode == 200) {
        _loadCategories();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kategori berhasil dihapus')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus kategori')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hapus Kategori'),
            content: Text(
              'Apakah Anda yakin ingin menghapus kategori "${category['nama_kategori']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  _deleteCategory(category['id']);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Hapus'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kategori'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
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
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _filteredCategories.isEmpty
                    ? Center(child: Text('Tidak ada kategori ditemukan'))
                    : ListView.builder(
                      itemCount: _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = _filteredCategories[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              category['nama_kategori'] ?? 'Tidak diketahui',
                            ),
                            subtitle: Text(
                              'Jenis: ${category['jenis'] ?? 'Tidak diketahui'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed:
                                      () => _showEditCategoryDialog(category),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(category),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

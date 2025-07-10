// transaction_screen.dart
import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00D4AA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00D4AA),
        elevation: 0,
        title: Text(
          'Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Color(0xFF00D4AA),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: 'Semua'),
                Tab(text: 'Pemasukan'),
                Tab(text: 'Pengeluaran'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionList(),
                  _buildIncomeList(),
                  _buildExpenseList(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: Color(0xFF00D4AA),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildDateSection('Hari ini'),
        _buildTransactionItem(
          title: 'Gaji Bulanan',
          category: 'Pemasukan',
          amount: 'Rp 5.000.000',
          time: '09:00',
          isIncome: true,
        ),
        _buildTransactionItem(
          title: 'Makan Siang',
          category: 'Makanan',
          amount: 'Rp 25.000',
          time: '12:30',
          isIncome: false,
        ),
        _buildTransactionItem(
          title: 'Bensin Motor',
          category: 'Transportasi',
          amount: 'Rp 15.000',
          time: '17:00',
          isIncome: false,
        ),
        SizedBox(height: 20),
        _buildDateSection('Kemarin'),
        _buildTransactionItem(
          title: 'Freelance Project',
          category: 'Pemasukan',
          amount: 'Rp 1.200.000',
          time: '14:00',
          isIncome: true,
        ),
        _buildTransactionItem(
          title: 'Belanja Groceries',
          category: 'Kebutuhan',
          amount: 'Rp 150.000',
          time: '10:00',
          isIncome: false,
        ),
      ],
    );
  }

  Widget _buildIncomeList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildDateSection('Hari ini'),
        _buildTransactionItem(
          title: 'Gaji Bulanan',
          category: 'Pemasukan',
          amount: 'Rp 5.000.000',
          time: '09:00',
          isIncome: true,
        ),
        SizedBox(height: 20),
        _buildDateSection('Kemarin'),
        _buildTransactionItem(
          title: 'Freelance Project',
          category: 'Pemasukan',
          amount: 'Rp 1.200.000',
          time: '14:00',
          isIncome: true,
        ),
        _buildTransactionItem(
          title: 'Bonus Kinerja',
          category: 'Pemasukan',
          amount: 'Rp 800.000',
          time: '16:00',
          isIncome: true,
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildDateSection('Hari ini'),
        _buildTransactionItem(
          title: 'Makan Siang',
          category: 'Makanan',
          amount: 'Rp 25.000',
          time: '12:30',
          isIncome: false,
        ),
        _buildTransactionItem(
          title: 'Bensin Motor',
          category: 'Transportasi',
          amount: 'Rp 15.000',
          time: '17:00',
          isIncome: false,
        ),
        SizedBox(height: 20),
        _buildDateSection('Kemarin'),
        _buildTransactionItem(
          title: 'Belanja Groceries',
          category: 'Kebutuhan',
          amount: 'Rp 150.000',
          time: '10:00',
          isIncome: false,
        ),
        _buildTransactionItem(
          title: 'Bayar Listrik',
          category: 'Tagihan',
          amount: 'Rp 200.000',
          time: '15:00',
          isIncome: false,
        ),
      ],
    );
  }

  Widget _buildDateSection(String date) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Text(
        date,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String category,
    required String amount,
    required String time,
    required bool isIncome,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isIncome
                      ? Color(0xFF00D4AA).withOpacity(0.1)
                      : Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              color: isIncome ? Color(0xFF00D4AA) : Color(0xFFFF6B6B),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? Color(0xFF00D4AA) : Color(0xFFFF6B6B),
                ),
              ),
              SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddTransactionModal(),
    );
  }

  Widget _buildAddTransactionModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Text(
                  'Tambah Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Transaksi berhasil ditambahkan')),
                    );
                  },
                  child: Text(
                    'Simpan',
                    style: TextStyle(color: Color(0xFF00D4AA)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTransactionTypeButton('Pemasukan', true),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTransactionTypeButton(
                          'Pengeluaran',
                          false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildInputField('Jumlah', 'Rp 0'),
                  SizedBox(height: 16),
                  _buildInputField('Keterangan', 'Masukkan keterangan'),
                  SizedBox(height: 16),
                  _buildDropdownField('Kategori', 'Pilih kategori'),
                  SizedBox(height: 16),
                  _buildInputField('Tanggal', 'Pilih tanggal'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTypeButton(String title, bool isIncome) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color:
            isIncome
                ? Color(0xFF00D4AA).withOpacity(0.1)
                : Color(0xFFFF6B6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIncome ? Color(0xFF00D4AA) : Color(0xFFFF6B6B),
          width: 2,
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isIncome ? Color(0xFF00D4AA) : Color(0xFFFF6B6B),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF00D4AA)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF00D4AA)),
            ),
          ),
          items:
              [
                'Makanan',
                'Transportasi',
                'Kebutuhan',
                'Tagihan',
                'Hiburan',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (String? newValue) {},
        ),
      ],
    );
  }
}

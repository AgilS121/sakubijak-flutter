// notification_screen.dart
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00D4AA),
      appBar: AppBar(
        backgroundColor: Color(0xFF00D4AA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi 1',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildNotificationItem(
                    title: 'Reminder',
                    message:
                        'Selamat bekerja di hari ini. Andalah yang membuat kebahagiaan.',
                    time: '7:00 - 16:00',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE0F2FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF00D4AA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.notifications, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
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
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

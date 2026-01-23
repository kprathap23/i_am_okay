import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'No history available yet.',
          style: TextStyle(
            fontSize: 18.0,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

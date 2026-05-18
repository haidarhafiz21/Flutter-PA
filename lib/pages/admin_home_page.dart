import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  final String nama;

  const AdminHomePage({super.key, required this.nama});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Mobile')),
      body: Center(
        child: Text(
          'Selamat datang Admin\n$nama',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
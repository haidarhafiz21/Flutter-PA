import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BorrowPickupBanner extends StatefulWidget {
  const BorrowPickupBanner({super.key});

  @override
  State<BorrowPickupBanner> createState() => _BorrowPickupBannerState();
}

class _BorrowPickupBannerState extends State<BorrowPickupBanner> {
  Duration? _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final deadline = prefs.getInt('borrow_pickup_deadline');

    if (deadline == null) {
      if (mounted) setState(() => _remaining = null);
      return;
    }

    final diff = DateTime.fromMillisecondsSinceEpoch(deadline)
        .difference(DateTime.now());

    if (diff.isNegative) {
      await prefs.remove('borrow_pickup_deadline');
      if (mounted) setState(() => _remaining = null);
    } else {
      if (mounted) setState(() => _remaining = diff);
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == null) return const SizedBox.shrink();

    return Material(
      color: Colors.orange,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buku harus segera diambil (${_format(_remaining!)})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

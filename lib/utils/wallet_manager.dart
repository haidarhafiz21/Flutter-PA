import 'package:shared_preferences/shared_preferences.dart';

class WalletManager {
  static const _saldoKey = 'user_saldo';

  static Future<int> getSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_saldoKey) ?? 200000;
  }

  static Future<void> setSaldo(int saldo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_saldoKey, saldo);
  }

  static Future<void> topUp(int nominal) async {
    final saldo = await getSaldo();
    await setSaldo(saldo + nominal);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../pickup/pickup_countdown_page.dart';
import '../admin/scan_book_page.dart';

class FaceVerificationPage extends StatefulWidget {
  final int userId;
  final int bookId;
  final String role;

  const FaceVerificationPage({
    super.key,
    required this.userId,
    required this.bookId,
    required this.role,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  CameraController? cameraController;

  String foto1 = "";
  String foto2 = "";

  bool loadingCamera = true;
  bool loading = false;
  bool sudahMulai = false;

  String statusText = "Membuka kamera...";

  @override
  void initState() {
    super.initState();
    bukaKamera();
  }

  Future<void> bukaKamera() async {
    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        loadingCamera = false;
        statusText = "Posisikan wajah di dalam frame";
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !sudahMulai) {
          sudahMulai = true;
          ambilFotoOtomatis();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingCamera = false;
        statusText = "Kamera gagal dibuka";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka kamera")),
      );
    }
  }

  Future<void> ambilFotoOtomatis() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (loading) return;

    try {
      setState(() {
        loading = true;
        foto1 = "";
        foto2 = "";
        statusText = "Diam sebentar, mengambil wajah pertama...";
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final photo1 = await cameraController!.takePicture();
      final bytes1 = await photo1.readAsBytes();
      foto1 = base64Encode(bytes1);

      setState(() {
        statusText = "Kedip lalu gerakkan wajah ke kanan/kiri sedikit";
      });

      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      final photo2 = await cameraController!.takePicture();
      final bytes2 = await photo2.readAsBytes();
      foto2 = base64Encode(bytes2);

      setState(() {
        statusText = "Memverifikasi wajah...";
      });

      await verifikasi();
    } catch (e) {
      debugPrint("AUTO CAMERA ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        statusText = "Gagal mengambil wajah, coba ulangi";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil wajah")),
      );
    }
  }

  Future<void> verifikasi() async {
    if (foto1.isEmpty || foto2.isEmpty) {
      if (!mounted) return;

      setState(() {
        loading = false;
        statusText = "Foto wajah belum lengkap";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto wajah belum lengkap")),
      );
      return;
    }

    try {
      final verify = await http.post(
        Uri.parse(ApiConfig.verifyFace),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "foto_scan": foto1,
          "foto_liveness": foto2,
        }),
      );

      final verifyData =
          verify.body.isNotEmpty ? jsonDecode(verify.body) : {};

      debugPrint("VERIFY RESPONSE: ${verify.body}");

      if (verifyData["match"] == true) {
        if (widget.role == "admin_mobile") {
          await tutupKamera();

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanBookPage(userId: widget.userId),
            ),
          );
          return;
        }

        await prosesBooking();
      } else {
        if (!mounted) return;

        setState(() {
          loading = false;
          statusText = verifyData["message"] ?? "Wajah tidak cocok";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verifyData["message"] ?? "Wajah tidak cocok"),
          ),
        );
      }
    } catch (e) {
      debugPrint("FACE VERIFICATION ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        statusText = "Verifikasi gagal, coba ulangi";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verifikasi gagal, coba ulangi")),
      );
    }
  }

  Future<void> prosesBooking() async {
    try {
      setState(() {
        statusText = "Wajah cocok, membuat booking...";
      });

      final booking = await http.post(
        Uri.parse(ApiConfig.booking),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "book_id": widget.bookId,
        }),
      );

      debugPrint("BOOKING RESPONSE: ${booking.body}");

      final bookingData =
          booking.body.isNotEmpty ? jsonDecode(booking.body) : {};

      if (bookingData["success"] == true) {
        final batasAmbilString = bookingData["batas_ambil"]?.toString();

        if (batasAmbilString == null || batasAmbilString.isEmpty) {
          throw Exception("batas_ambil tidak ditemukan");
        }

        final batasAmbil = DateTime.parse(batasAmbilString).toLocal();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'borrow_pickup_deadline',
          batasAmbil.millisecondsSinceEpoch,
        );

        await tutupKamera();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PickupCountdownPage(userId: widget.userId),
          ),
        );
      } else {
        if (!mounted) return;

        setState(() {
          loading = false;
          statusText = bookingData["message"] ?? "Booking gagal";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bookingData["message"] ?? "Booking gagal"),
          ),
        );
      }
    } catch (e) {
      debugPrint("BOOKING ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
        statusText = "Verifikasi berhasil tetapi booking gagal";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verifikasi berhasil tetapi booking gagal"),
        ),
      );
    }
  }

  Future<void> tutupKamera() async {
    try {
      await cameraController?.dispose();
      cameraController = null;
    } catch (_) {}
  }

  Widget cameraPreview() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CameraPreview(cameraController!),
    );
  }

  Widget infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Text(
        "Arahkan wajah ke kamera depan. Sistem akan mengambil wajah secara otomatis. Saat diminta, kedip lalu gerakkan wajah ke kanan/kiri sedikit.",
        style: TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget statusBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            loading ? Icons.face_retouching_natural : Icons.face,
            color: loading ? Colors.orange : Colors.green,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffdf7fb),
      appBar: AppBar(
        title: const Text("Verifikasi Wajah"),
        centerTitle: true,
        backgroundColor: const Color(0xfffdf7fb),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loadingCamera
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                infoBox(),
                const SizedBox(height: 18),
                SizedBox(
                  height: 430,
                  child: Stack(
                    children: [
                      Positioned.fill(child: cameraPreview()),
                      Center(
                        child: Container(
                          width: 240,
                          height: 310,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: loading ? Colors.orange : Colors.green,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(160),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            loading
                                ? "Sedang proses verifikasi..."
                                : "Kamera siap",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                statusBox(),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            sudahMulai = true;
                            ambilFotoOtomatis();
                          },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Ulangi Verifikasi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
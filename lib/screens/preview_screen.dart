import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/scan_controller.dart';
import '../utils/theme.dart';
import '../widgets/common_widgets.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  // ── Simpan PDF ke Downloads/TenggooScans ───────────────────────────────────
  Future<void> _savePdf(String pdfPath) async {
    try {
      final srcFile = File(pdfPath);
      if (!srcFile.existsSync()) {
        _snack('File PDF tidak ditemukan', isError: true);
        return;
      }
      final downloadsDir =
          Directory('/storage/emulated/0/Download/TenggooScans');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }
      final fileName =
          'tenggo_scans_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final destPath = '${downloadsDir.path}/$fileName';
      await srcFile.copy(destPath);
      await MediaScanner.loadMedia(path: destPath);
      _snack('PDF disimpan di: Download/TenggooScans/$fileName');
    } catch (e) {
      // Fallback ke internal app dir
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final tenggoDir = Directory('${appDir.path}/TenggooScans');
        if (!tenggoDir.existsSync()) tenggoDir.createSync();
        final fileName =
            'tenggo_scans_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await File(pdfPath).copy('${tenggoDir.path}/$fileName');
        await MediaScanner.loadMedia(path: '${tenggoDir.path}/$fileName');
        _snack('PDF disimpan di folder TenggooScans (internal)');
      } catch (e2) {
        _snack('Gagal menyimpan PDF: $e2', isError: true);
      }
    }
  }

  // ── Simpan JPEG ke Gallery ────────────────────────────────────────────────
  Future<void> _saveImages(List<String> images) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) await Gal.requestAccess(toAlbum: true);
      int saved = 0;
      for (final p in images) {
        if (File(p).existsSync()) {
          await Gal.putImage(p, album: 'TenggooScans');
          saved++;
        }
      }
      if (saved > 0) {
        _snack('$saved gambar disimpan ke Gallery › Album "TenggooScans"');
      } else {
        _snack('Tidak ada gambar yang berhasil disimpan', isError: true);
      }
    } catch (e) {
      _snack('Gagal menyimpan gambar: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Berhasil ✓',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          isError ? AppTheme.error : AppTheme.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScanController ctrl = Get.find();

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Pratinjau Dokumen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            ctrl.clearScan();
            Get.back();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: Obx(() {
        final images = ctrl.scannedImagesPaths;
        final pdfPath = ctrl.scannedPdfPath;

        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner_outlined,
                      size: 36, color: AppTheme.primary),
                ),
                const SizedBox(height: 16),
                const Text('Tidak ada dokumen yang di-scan',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        return Column(
          children: [
            // ── Preview List ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: images.length,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              StatusChip(
                                label: 'Halaman ${i + 1}',
                                color: AppTheme.primary,
                                bgColor: AppTheme.primarySurface,
                              ),
                              const Spacer(),
                              Text(
                                '${i + 1} / ${images.length}',
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textHint),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.divider),
                        // Image
                        Image.file(
                          File(images[i]),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            height: 120,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppTheme.textHint, size: 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Action Panel ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border:
                    const Border(top: BorderSide(color: AppTheme.divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PDF actions
                  Row(
                    children: [
                      Expanded(
                        child: IconActionButton(
                          icon: Icons.download_rounded,
                          label: 'Simpan PDF',
                          color: AppTheme.primary,
                          onPressed: pdfPath.isNotEmpty
                              ? () => _savePdf(pdfPath)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: IconActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share PDF',
                          color: AppTheme.primary,
                          isOutlined: true,
                          onPressed: pdfPath.isNotEmpty
                              ? () async {
                                  await Share.shareXFiles(
                                    [XFile(pdfPath)],
                                    subject: 'Dokumen TenggooScans',
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // JPEG actions
                  Row(
                    children: [
                      Expanded(
                        child: IconActionButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Simpan ke Gallery',
                          color: AppTheme.success,
                          onPressed: () => _saveImages(images),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: IconActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share JPEG',
                          color: AppTheme.success,
                          isOutlined: true,
                          onPressed: () async {
                            await Share.shareXFiles(
                              images.map((p) => XFile(p)).toList(),
                              subject: 'Gambar TenggooScans',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ctrl.clearScan();
                      Get.back();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textHint,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text(
                      'Selesai & Kembali',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

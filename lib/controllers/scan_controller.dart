import 'dart:io';
import 'package:get/get.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// Konversi URI (file:// atau path biasa) ke file path yang bisa dibaca oleh dart:io
String _toFilePath(String uri) {
  if (uri.startsWith('file://')) {
    return Uri.parse(uri).toFilePath();
  }
  return uri;
}

class ScanController extends GetxController {
  final _scannedPdfPath = ''.obs;
  final _scannedImagesPaths = <String>[].obs;
  final _isScanning = false.obs;

  String get scannedPdfPath => _scannedPdfPath.value;
  List<String> get scannedImagesPaths => _scannedImagesPaths;
  bool get isScanning => _isScanning.value;

  late DocumentScanner _documentScanner;

  @override
  void onInit() {
    super.onInit();
    // Initialize the scanner with some default options
    final options = DocumentScannerOptions(
      documentFormats: {DocumentFormat.pdf, DocumentFormat.jpeg},
      mode: ScannerMode.full,
      pageLimit: 50,
      isGalleryImport: true,
    );
    _documentScanner = DocumentScanner(options: options);
  }

  @override
  void onClose() {
    _documentScanner.close();
    super.onClose();
  }

  Future<bool> startScan() async {
    try {
      _isScanning.value = true;
      final result = await _documentScanner.scanDocument();
      
      try {
        if (result.pdf != null && result.pdf!.uri.isNotEmpty) {
          final path = _toFilePath(result.pdf!.uri);
          // Pastikan file benar-benar ada sebelum menyimpan path-nya
          if (File(path).existsSync()) {
            _scannedPdfPath.value = path;
          } else {
            _scannedPdfPath.value = result.pdf!.uri; // fallback ke uri asli
          }
        }
      } catch (_) {
        _scannedPdfPath.value = '';
      }

      _scannedImagesPaths.clear();
      if (result.images != null && result.images!.isNotEmpty) {
        // Normalize semua path gambar juga
        _scannedImagesPaths.addAll(
          result.images!.map((uri) => _toFilePath(uri)).toList(),
        );
      }

      _isScanning.value = false;
      return true;
    } catch (e) {
      // Jika user membatalkan scan (klik tombol X), jangan tampilkan error
      final msg = e.toString().toLowerCase();
      if (!msg.contains('cancel')) {
        Get.snackbar(
          'Error',
          'Gagal melakukan pemindaian: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      _isScanning.value = false;
    }
    return false;
  }

  void clearScan() {
    _scannedPdfPath.value = '';
    _scannedImagesPaths.clear();
  }
}

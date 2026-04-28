import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

class ConvertController extends GetxController {
  final _isLoading = false.obs;
  final _pickedImages = <File>[].obs;
  final _pickedPdf = Rxn<File>();
  final _pdfPages = <Uint8List>[].obs;
  final _progress = 0.0.obs;
  final _statusMessage = ''.obs;

  bool get isLoading => _isLoading.value;
  List<File> get pickedImages => _pickedImages;
  File? get pickedPdf => _pickedPdf.value;
  List<Uint8List> get pdfPages => _pdfPages;
  double get progress => _progress.value;
  String get statusMessage => _statusMessage.value;

  final _imagePicker = ImagePicker();

  // ── Pick images dari gallery ──────────────────────────────────────────────
  Future<void> pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 90);
    if (picked.isNotEmpty) {
      _pickedImages.addAll(picked.map((xf) => File(xf.path)));
    }
  }

  void removeImage(int index) => _pickedImages.removeAt(index);
  void clearImages() => _pickedImages.clear();

  // ── Reorder images ────────────────────────────────────────────────────────
  void reorderImage(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _pickedImages.removeAt(oldIndex);
    _pickedImages.insert(newIndex, item);
  }

  // ── Convert Images → PDF ──────────────────────────────────────────────────
  Future<void> convertImagesToPdf() async {
    if (_pickedImages.isEmpty) {
      _showSnackbar('Pilih minimal 1 gambar terlebih dahulu', isError: true);
      return;
    }
    try {
      _isLoading.value = true;
      _progress.value = 0;
      _statusMessage.value = 'Membuat PDF...';

      final pdf = pw.Document();
      final total = _pickedImages.length;

      for (int i = 0; i < total; i++) {
        _progress.value = (i + 1) / total;
        _statusMessage.value = 'Memproses halaman ${i + 1} dari $total...';

        final imageBytes = await _pickedImages[i].readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        // Tentukan orientasi dari gambar
        final decodedImage = await decodeImageFromList(imageBytes);
        final isLandscape = decodedImage.width > decodedImage.height;
        final pageFormat = isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (ctx) => pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }

      // Simpan ke Downloads/TenggooScans
      final downloadsDir = Directory('/storage/emulated/0/Download/TenggooScans');
      if (!downloadsDir.existsSync()) downloadsDir.createSync(recursive: true);

      final fileName = 'tenggo_scans_img2pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${downloadsDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await MediaScanner.loadMedia(path: filePath);

      _isLoading.value = false;
      _showSnackbar('PDF berhasil dibuat!\nDisimpan di: Download/TenggooScans/$fileName');
    } catch (e) {
      _isLoading.value = false;
      _showSnackbar('Gagal membuat PDF: $e', isError: true);
    }
  }

  // ── Pick PDF — Menggunakan System File Picker ──────────────────────────────
  Future<void> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        _pickedPdf.value = File(result.files.single.path!);
        _pdfPages.clear();
      }
    } catch (e) {
      _showSnackbar('Gagal memilih file: $e', isError: true);
    }
  }

  void clearPdf() {
    _pickedPdf.value = null;
    _pdfPages.clear();
  }

  // ── Convert PDF → Images ──────────────────────────────────────────────────
  Future<void> convertPdfToImages() async {
    if (_pickedPdf.value == null) {
      _showSnackbar('Pilih file PDF terlebih dahulu', isError: true);
      return;
    }
    try {
      _isLoading.value = true;
      _pdfPages.clear();
      _statusMessage.value = 'Membaca PDF...';

      final document = await pdfx.PdfDocument.openFile(_pickedPdf.value!.path);
      final pageCount = document.pagesCount;

      // Simpan ke gallery
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) await Gal.requestAccess(toAlbum: true);

      final tmpDir = await getTemporaryDirectory();
      int savedCount = 0;

      for (int i = 1; i <= pageCount; i++) {
        _progress.value = i / pageCount;
        _statusMessage.value = 'Mengkonversi halaman $i dari $pageCount...';

        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (pageImage != null) {
          _pdfPages.add(pageImage.bytes);

          // Simpan ke gallery
          final tmpFile = File('${tmpDir.path}/tenggo_page_$i.jpg');
          await tmpFile.writeAsBytes(pageImage.bytes);
          await Gal.putImage(tmpFile.path, album: 'TenggooScans');
          savedCount++;
        }
      }

      document.close();
      _isLoading.value = false;

      if (savedCount > 0) {
        _showSnackbar('$savedCount halaman disimpan ke Gallery › Album "TenggooScans"');
      }
    } catch (e) {
      _isLoading.value = false;
      _showSnackbar('Gagal mengkonversi PDF: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Selesai ✓',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    );
  }
}

# 📱 TenggooScans

Aplikasi Document Scanner yang modern, minimalis, dan powerful untuk Android. Dibangun menggunakan Flutter dengan dukungan Google ML Kit untuk pemindaian dokumen berkualitas tinggi.

---

## ✨ Fitur Utama

### 📷 Smart Document Scanner
- **Deteksi Tepi Otomatis**: Mendeteksi sudut dokumen secara cerdas menggunakan Google ML Kit.
- **Multi-Output**: Hasil scan tersimpan otomatis sebagai PDF berkualitas tinggi dan kumpulan gambar JPEG.
- **Share Instant**: Bagikan dokumen langsung ke WhatsApp, Email, atau aplikasi lainnya.

### 🔄 Document Converter
- **Image to PDF**: Ubah banyak foto dari galeri menjadi satu file PDF rapi dengan orientasi otomatis.
- **PDF to Image**: Ekstrak halaman PDF menjadi gambar JPEG berkualitas tinggi langsung ke Galeri HP.
- **System File Picker**: Mendukung pemilihan file PDF dari seluruh penyimpanan perangkat (Internal, SD Card, Drive).

### 🎨 Modern UI/UX
- **Desain Minimalis**: Antarmuka bersih dengan palet warna Indigo yang profesional.
- **Mode Navigasi**: Bottom navigation untuk akses cepat antar fitur Scanner dan Konversi.
- **Real-time Progress**: Indikator progres saat melakukan konversi file berat.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Scanner Engine**: [Google ML Kit Document Scanner](https://pub.dev/packages/google_mlkit_document_scanner)
- **PDF Engine**: [pdf](https://pub.dev/packages/pdf) & [pdfx](https://pub.dev/packages/pdfx)
- **File & Media**: `gal`, `image_picker`, `file_picker`, `media_scanner`

---

## 🚀 Cara Menjalankan (Development)

### Prasyarat
- Flutter SDK (Versi terbaru direkomendasikan)
- **JDK 17** (Sudah dikonfigurasi di `android/gradle.properties`)
- HP Android Fisik (Wajib untuk fitur Scanner ML Kit)

### Langkah-langkah
1. Clone repository ini.
2. Jalankan perintah untuk mengambil dependencies:
   ```bash
   flutter pub get
   ```
3. Hubungkan HP Android Anda dan jalankan aplikasi:
   ```bash
   flutter run
   ```

---

## 📂 Lokasi Penyimpanan
Aplikasi ini menyimpan file di folder publik agar mudah ditemukan:
- **PDF**: `Internal Storage/Download/TenggooScans/`
- **Gambar**: `Gallery/Album/TenggooScans/`

---

## 📝 Lisensi
Proyek ini dibuat untuk tujuan utilitas dokumen harian. Semua library yang digunakan bersifat Open Source.

**TenggooScans — Scan & Convert Simplified.**

# ngapak_farm

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Akun dan laporan karyawan

- Pemilik mendaftarkan akun pertama kali dari halaman pembuka aplikasi.
- Setelah masuk, pemilik dapat menambah, mengedit, dan menghapus akun karyawan
  melalui menu **Karyawan**. Email dan kata sandi awal diberikan kepada karyawan
  untuk masuk.
- Karyawan dapat mengirim laporan kegiatan dengan tanggal, jam, dan catatan
  opsional. Pemilik melihat laporan melalui menu **Laporan Karyawan** atau ikon
  notifikasi; laporan yang belum dibuka ditandai dengan badge.
- Data akun, laporan, dan penanda notifikasi tersimpan lokal menggunakan Hive.
  Sinkronisasi antarperangkat dan push notification belum tersedia; untuk
  penggunaan beberapa perangkat diperlukan backend.
- Kata sandi disimpan sebagai hash PBKDF2-HMAC-SHA256 bersalt. Penyimpanan lokal
  ini bukan pengganti autentikasi backend untuk deployment multi-perangkat.

## POS produk daging

- Menu **POS** digunakan untuk penjualan produk daging per kilogram dan terpisah
  dari alur jual kambing.
- Pemilik dapat menambah, mengedit, menonaktifkan produk, dan menambah stok.
  Karyawan hanya dapat memilih produk yang tersedia dan membuat penjualan.
- Checkout mendukung pembayaran tunai dengan perhitungan kembalian atau QRIS
  dengan foto bukti pembayaran. Penjualan mengurangi stok produk dan dicatat
  sebagai pemasukan keuangan; statistik menampilkan total kg daging terjual.
- Data POS dan bukti QRIS tersimpan lokal di perangkat menggunakan Hive dan
  penyimpanan dokumen aplikasi.

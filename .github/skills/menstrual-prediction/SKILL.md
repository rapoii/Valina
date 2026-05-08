---
name: menstrual-prediction
description: 'Sistem dan logika perhitungan prediksi siklus menstruasi, masa subur (fertile window), puncak ovulasi, dan tingkat peluang kehamilan (pregnancy rate). Gunakan saat modifikasi `CycleCalculator` atau menganalisis fase siklus.'
argument-hint: 'Masukkan data periode jika ada atau skenario prediksi spesifik.'
user-invocable: true
disable-model-invocation: false
---

# Menstrual Cycle Prediction System

## Kapan Menggunakan Skill Ini
- Saat menambah fitur baru atau mengubah logika prediksi pada `CycleCalculator` atau fitur terkait kalender.
- Untuk melakukan perbaikan *bug* atau kalkulasi fase menstruasi, folikuler, ovulasi, luteal, dan peluang kehamilan (pregnancy probability).
- Saat membuat atau menguji *edge cases* siklus menstruasi (misalnya: data tidak teratur, menstruasi lebih dari batas normal, fallback jika data tidak tersedia).

## Dasar Teori dan Rumus Prediksi

Berikut standar logika biologis (algoritma ritme/kalender) untuk menghitung siklus menstruasi secara *default* (menggunakan data historis pengguna atau *fallback* jika baru menginstal):

1.  **Estimasi Siklus (*Cycle Length*) & Periode (*Period Length*)**:
    - Berdasarkan rata-rata historis (misal 3-6 bulan terakhir).
    - Jika kosong, gunakan `fallbackCycleLength` (umumnya 28 hari) dan `fallbackPeriodLength` (umumnya 5 hari).

2.  **Fase Menstruasi (*Menstrual Phase*)**:
    - Mulai dari Hari ke-1 pendarahan hingga durasi pendarahan berakhir (Hari ke-*Period Length*).
    - *Pregnancy Rate*: Rendah.

3.  **Haid Berikutnya (*Next Period*)**:
    - Tanggal Haid Terakhir (Hari ke-1) + `Cycle Length`.

4.  **Puncak Ovulasi (*Ovulation Peak*)**:
    - Rata-rata umumnya terjadi 14 hari sebelum *Next Period* dimulai.
    - Rumus: `Next Period - 14 Days` atau Hari ke-(`Cycle Length` - 14).
    - *Pregnancy Rate*: Sangat Tinggi (Maksimum).

5.  **Masa Subur (*Fertile Window*)**:
    - Umumnya 5 hari sebelum Hari Ovulasi hingga 1 hari setelah Hari Ovulasi.
    - Rumus: (`Ovulation Peak` - 5 Days) sampai (`Ovulation Peak` + 1 Day).
    - *Pregnancy Rate*: Tinggi hingga Sangat Tinggi.

6.  **Fase Luteal (*Luteal Phase*) & Peluang Kehamilan (*Pregnancy Rate*)**:
    - Mengisi hari-hari sisa antara selesainya rentang masa subur hingga mulainya *Next Period*.
    - *Pregnancy Rate*: Rendah setelah selesainya masa subur.

## Prosedur Menerapkan Perubahan Logika / Modifikasi

Setiap kali pengguna meminta Anda merancang logika, menambah variabel baru (seperti peluang kehamilan rendah/menengah/tinggi per harinya), atau *debugging*, jalankan langkah-langkah berikut:

1.  **Analisis Data Input**: 
    - Pastikan *input* berupa daftar (`List`) log siklus sebelumnya, tanggal hari ini (`today`), serta nilai parameter `fallback`.
2.  **Baca Implementasi Saat Ini**:
    - Periksa `lib/core/utils/cycle_calculator.dart` dan `lib/data/models/cycle.dart` (termasuk *enum* `CyclePhase`).
3.  **Terapkan Modifikasi Logika Prediksi**:
    - Tulis kode berdasarkan rumus di atas. 
    - Bila diminta mengembalikan tingkat kehamilan (*pregnancy chance*), petakan setiap *phase date* ke probabilitas kehamilan harian yang spesifik (mis. `High` untuk `Fertile`, `Peak` untuk `Ovulation`).
4.  **Tulis *Unit Test***:
    - Selalu perbarui atau tulis *test* baru di `test/cycle_calculator_test.dart` minimal dengan:
        - Skenario tanpa data (*fallback*).
        - Skenario dengan data historis teratur.
        - Skenario siklus bervariasi / tidak teratur.
    - Jalankan `flutter test test/cycle_calculator_test.dart` via terminal dan pastikan tes berhasil.

## Resource Files

- [CycleCalculator (Utility)](../../lib/core/utils/cycle_calculator.dart)
- [Cycle Tests](../../test/cycle_calculator_test.dart)
- [Models dan Enum](../../lib/data/models/)


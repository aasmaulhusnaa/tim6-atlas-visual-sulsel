# tim6-atlas-visual-sulsel

**Atlas Visual Sulawesi Selatan: TPT dan Rata-rata Lama Sekolah, 24 kabupaten/kota, 2023-2025.**
Proyek Tim 6, mata kuliah Komputasi Statistika Lanjut (S2 Statistika, FMIPA Unhas).

Pertanyaan yang dijawab: bagaimana menyajikan satu indikator pembangunan untuk 24 kabupaten/kota di Sulawesi Selatan secara jujur (ketidakpastian tampak), teruji (pola terbukti bukan kebetulan), dan terprogram (seluruh grafik dapat dibuat ulang dengan kode).

## Pesan utama

Hubungan TPT dan RLS tampak kuat (r = 0,75 pada 2025), tetapi didorong terutama oleh tiga kota: pada kabupaten saja korelasinya hanya r = 0,13. Wilayah dengan RLS lebih tinggi cenderung memiliki TPT lebih tinggi, dan Makassar, Palopo, dan Parepare berada di antara yang tertinggi.

## Indikator dan data

| Indikator | Peran | Satuan |
|---|---|---|
| TPT (Tingkat Pengangguran Terbuka) | Utama | persen |
| RLS (Rata-rata Lama Sekolah) | Pendamping | tahun |

- **Cakupan:** 24 kabupaten/kota Sulawesi Selatan, 2023-2025.
- **Sumber:** BPS (TPT Agustus dan RLS); batas wilayah dari geoBoundaries (IDN-ADM2).
- **Data bersih:** `data/data-bersih/` (`data_bersih.rds` dan `data_bersih.csv`) dengan kolom `kode_wilayah`, `kabupaten`, `tahun`, `tpt`, `rls`; satu baris per wilayah per tahun.
- **Jenis wilayah** ditentukan dari kode wilayah: 7371 sampai 7373 (Makassar, Parepare, Palopo) adalah kota, sisanya kabupaten.

## Struktur repositori

```
tim6-atlas-visual-sulsel/
├── R/                   skrip analisis dan tema
├── data/
│   ├── batas-peta/      batas wilayah (geoBoundaries IDN-ADM2)
│   ├── data-bersih/     data_bersih.rds dan data_bersih.csv
│   ├── data-kode-wilayah/
│   └── data-mentah/
├── makeover/            grafik sebelum dan sesudah makeover
├── theme_team/          dokumentasi tema, bukti uji buta warna, galeri grafik
├── keluaran/            (menyusul) grafik dan 24 profil kabupaten
├── atlas.qmd            (menyusul) atlas Quarto
├── infografis.pdf       (menyusul) infografis kebijakan
└── README.md
```

| Lokasi | Isi |
|---|---|
| `R/01_data_bersih.R` | Impor, pembersihan, dan penggabungan data dengan kode wilayah |
| `R/02_makeover.R` | Kode grafik makeover (sebelum dan sesudah) |
| `R/03_theme_tim .R` | Palet warna, skala, dan `theme_tim()` yang dipakai semua grafik |
| `R/uji_buta_warna.R` | Uji palet dengan simulasi buta warna (`colorspace`) |
| `makeover/` | `before.png`, `after.png`, dan `catatan_perbaikan.md` (alasan perbaikan) |
| `theme_team/readme.md` | Aturan tema dan palet secara lengkap |
| `theme_team/uji_palet_*.png` | Bukti uji buta warna palet tim dan palet peta |
| `theme_team/galeri/` | Contoh grafik hasil galeri (dumbbell dan komposisi) |

Catatan: nama folder `theme_team` dan file `03_theme_tim .R` (ada spasi sebelum `.R`) ditulis apa adanya seperti di repositori.

## Cara menjalankan ulang

1. Unduh atau clone repositori ini, lalu buka R atau RStudio.
2. Atur folder kerja ke folder utama repositori:
   ```r
   setwd("alamat/ke/tim6-atlas-visual-sulsel")
   ```
3. Pasang paket yang dibutuhkan:
   ```r
   install.packages(c("ggplot2", "patchwork", "colorspace"))
   # untuk tahap berikutnya: sf, purrr, nullabor, quarto
   ```
4. Jalankan skrip berurutan: `R/01_data_bersih.R`, lalu `R/02_makeover.R`.
5. Jalankan skrip galeri grafik (`galeri_grafik.R`, grafik 1 sampai 6). Skrip ini mencari file tema (`03_theme_tim .R`) dan `data_bersih.csv` di dalam repositori secara otomatis, lalu menyimpan grafik sebagai PNG.
6. Untuk mengganti indikator atau tahun, ubah pengaturan di bagian atas skrip galeri (`tahun_pilih`, `th_awal`, `th_akhir`), lalu jalankan ulang.
7. *(menyusul)* Render atlas dengan `quarto render atlas.qmd`, dan 24 profil kabupaten dengan satu perintah.

## Tema grafik

Semua grafik memakai tema buatan sendiri, `theme_tim()`, tanpa paket tema siap pakai. Kabupaten dibedakan dari kota dengan warna dan bentuk titik (kabupaten lingkaran ungu, kota persegi kuning), garis memakai vermilion, judul biru, dan peta koroplet memakai palet sekuensial Blues. Palet diuji dengan simulasi deuteranopia, protanopia, tritanopia, dan grayscale. Aturan lengkapnya ada di [`theme_team/readme.md`](theme_team/readme.md).

## Hasil

| Produk | Status |
|---|---|
| Galeri grafik statistik (grafik 1 sampai 6) | Dalam pengerjaan |
| Makeover grafik resmi | [`makeover/`](makeover/) |
| Peta koroplet dan 24 profil kabupaten | Menyusul |
| Grafik ketidakpastian (bootstrap) dan lineup | Menyusul |
| Atlas Visual (Quarto, HTML) | Menyusul |
| Infografis kebijakan | Menyusul |

## Checkpoint

| Checkpoint | Isi | Tag |
|---|---|---|
| 1 | Data bersih dan makeover sebelum/sesudah | `cp1` |
| 2 | `theme_tim()` dan galeri | `cp2` |
| 3 | Fungsi grafik, 24 profil, dan peta | `cp3` |

## Tim

| Anggota | Peran |
|---|---|
| Wafiq Chairani | *(isi)* |
| Asmaul Husna | *(isi)* |

## Deklarasi penggunaan AI

Tim menggunakan asisten AI (Claude, Anthropic) sebagai bantuan untuk menyusun dan memperbaiki kode R.

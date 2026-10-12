# Atlas Visual Sulawesi Selatan

**Tingkat Pengangguran Terbuka (TPT) di 24 kabupaten/kota Sulawesi Selatan, 2023-2025**

Proyek 14 hari mata kuliah **Komputasi Statistika Lanjut** (25H06210204), S2 Statistika Universitas Hasanuddin, Semester Ganjil 2026/2027.

**Tim 6:** Asmaul Husna dan Wafiq Chairani

## Pertanyaan Proyek

Bagaimana menyajikan satu indikator pembangunan untuk 24 kabupaten/kota di Sulawesi Selatan secara **jujur** (ketidakpastian tampak), **teruji** (pola terbukti bukan kebetulan), dan **terprogram** (seluruh grafik dapat dibuat ulang dengan satu perintah)?

## Temuan Utama

- TPT di Sulawesi Selatan cenderung **lebih tinggi di wilayah perkotaan**. Pada 2025, TPT tertinggi ada di Makassar (9,60%) dan terendah di Enrekang (1,78%).
- Wilayah dengan rata-rata lama sekolah (RLS) lebih tinggi cenderung memiliki TPT lebih tinggi. Ini hubungan antarwilayah, bukan sebab-akibat.
- Pada tingkat Satuan Wilayah Pembangunan (SWP), selang kepercayaan bootstrap 95% menunjukkan Mamminasata tertinggi (5,40%) dan Selatan-Selatan terendah (2,27%).
- Uji lineup 20 panel: 10 dari 12 pengamat sah memilih panel data asli, jauh di atas harapan bila hanya menebak (0,6 orang), dengan p-value visual < 0,001.

Rincian, grafik, dan tafsirannya ada di **`atlas.html`** (dirender dari `atlas.qmd`).

## Data

| Hal | Keterangan |
|---|---|
| Indikator utama | Tingkat Pengangguran Terbuka (TPT, %) |
| Indikator pendamping | Rata-rata Lama Sekolah (RLS, tahun) |
| Cakupan | 24 kabupaten/kota Sulawesi Selatan, 2023-2025 |
| Sumber data | Badan Pusat Statistik (BPS) |
| Batas wilayah | geoBoundaries (IDN-ADM2) |
| Data bersih | `data/data-bersih/data_bersih.rds` (memuat geometri peta, objek `sf`) |

## Struktur Repositori

```
.
├── R/                         # semua skrip, urut sesuai alur kerja
│   ├── 01_data_bersih.R       # impor, pembersihan, penggabungan data dan batas peta
│   ├── 02_makeover.R          # makeover grafik resmi (before/after)
│   ├── 03_theme_tim.R         # theme_tim(), palet warna, skala warna peta
│   ├── 04_galeri_grafik.R     # galeri 6 grafik statistik
│   ├── 05_fungsi_grafik.R     # fungsi grafik dengan tidy evaluation ({{ }})
│   ├── 06_lineup.R            # pembuatan lineup 20 panel
│   ├── 07_peta_korpolet.R     # peta koroplet + uji buta warna
│   ├── 08_profil_wilayah.R    # 24 profil kabupaten/kota (purrr::walk2 + ggsave)
│   ├── 09_grafik_sk_bootstrap.R  # SK bootstrap 95% per SWP
│   ├── 10_analisis_lineup.R   # p-value visual hasil lineup
│   ├── 11_autoplot            # metode S3 autoplot()
│   ├── grafik_infografis.R    # grafik versi tanpa teks untuk infografis
│   └── uji_buta_warna.R       # uji simulasi deuteranopia dan protanopia
├── data/
│   ├── data-mentah/           # data mentah
│   ├── data-kode-wilayah/     # kode wilayah
│   ├── batas-peta/            # batas wilayah geoBoundaries
│   └── data-bersih/           # data bersih (.rds)
├── theme_team/                # galeri grafik dan uji palet tema
├── makeover/                  # before.png, after.png, catatan_perbaikan.md
├── berkas_lineup/             # lineup 20 panel, kunci, formulir, jawaban pengamat
├── hasil_lineup/              # gambar dan ringkasan hasil lineup
├── peta_koroplet/             # peta TPT 2025 dan hasil uji buta warna
├── SK_bootstrap/              # grafik SK bootstrap
├── keluaran/
│   └── profil/                # 24 profil kabupaten/kota (PNG)
├── atlas.qmd                  # sumber atlas (Quarto)
├── infografis.pdf             # infografis kebijakan 1 halaman
└── README.md
```

## Cara Menjalankan Ulang

### 1. Prasyarat

- [R](https://cran.r-project.org/) (disarankan versi 4.1 atau lebih baru)
- [Quarto](https://quarto.org/docs/get-started/) (sudah termasuk di RStudio versi terbaru)
- Paket R:

```r
install.packages(c("ggplot2", "sf", "patchwork", "purrr", "rlang",
                   "colorspace", "scales", "knitr"))
```

Skrip pembersihan data (`01_data_bersih.R`) dapat memerlukan paket tambahan untuk membaca data mentah; paketnya disebutkan di bagian awal skrip tersebut.

### 2. Ambil Repositori

```bash
git clone https://github.com/<nama-akun>/tim6-atlas-visual-sulsel.git
```

Buka folder hasil clone di RStudio (File > New Project > Existing Directory), atau atur folder kerja R ke folder utama repositori. Semua skrip mencari berkas secara otomatis dari folder utama, jadi tidak ada jalur yang perlu diubah.

### 3. Render Atlas

Dari folder utama repositori:

```bash
quarto render atlas.qmd
```

Hasilnya `atlas.html`: satu berkas mandiri berisi pesan utama, galeri, peta, profil, grafik ketidakpastian, hasil lineup, makeover, catatan revisi, dan deklarasi AI. Render pertama dapat memakan beberapa menit karena bootstrap dan 24 profil dihitung ulang.

### 4. Demo: ganti satu argumen, render ulang

Buka `atlas.qmd`, ubah salah satu nilai di bagian atas, lalu render lagi:

```r
tahun_demo     <- 2025    # tahun peta, peringkat profil, dan scatterplot
indikator_demo <- "tpt"   # "tpt" atau "rls"
```

Peta, uji buta warna, 24 profil, dan angka di narasi ikut berubah.

### 5. 24 Profil dari Satu Perintah

Skrip `R/08_profil_wilayah.R` memuat fungsi `plot_profil()` dan `buat_semua_profil()`. Menjalankan skrip itu menghasilkan 24 berkas PNG di `keluaran/profil/`. Argumen indikator dan tahun dapat diganti:

```r
source("R/08_profil_wilayah.R")                 # membuat 24 profil
buat_semua_profil(d, tahun_rank = 2023)         # peringkat tahun 2023
buat_semua_profil(d, tahun = 2024:2025)         # tren 2024-2025
buat_semua_profil(d, kiri = rls, kanan = tpt)   # tukar indikator
```

### 6. Skrip Lain

| Tujuan | Jalankan |
|---|---|
| Galeri 6 grafik | `R/04_galeri_grafik.R` |
| Peta koroplet + uji buta warna | `R/07_peta_korpolet.R` |
| SK bootstrap 95% | `R/09_grafik_sk_bootstrap.R` |
| Analisis lineup | `R/10_analisis_lineup.R` (membaca `jawaban_pengamat.csv`; menulis ke `keluaran/lineup/`) |
| Grafik tanpa teks untuk infografis | `R/grafik_infografis.R` (menulis ke `keluaran/tanpa_teks/`) |

Urutan skrip mengikuti nomor di depan nama berkasnya. Setiap skrip memuat `03_theme_tim.R` sendiri.

## Komponen Proyek

| Komponen | Keluaran | Lokasi |
|---|---|---|
| Makeover | Grafik resmi sebelum dan sesudah, catatan perbaikan | `makeover/` |
| Tema dan galeri | `theme_tim()`, palet, 6 grafik statistik | `R/03_theme_tim.R`, `theme_team/galeri/` |
| Fungsi grafik | Fungsi dengan `{{ }}` (tidy evaluation) | `R/05_fungsi_grafik.R`, `R/08_profil_wilayah.R` |
| 24 profil | Satu perintah, 24 PNG | `keluaran/profil/` |
| Peta | Koroplet `sf`, lolos simulasi deuteranopia dan protanopia (`colorspace`) | `peta_koroplet/` |
| Ketidakpastian | SK bootstrap 95% per SWP | `SK_bootstrap/` |
| Inferensi visual | Lineup 20 panel, p-value visual | `berkas_lineup/`, `hasil_lineup/` |
| `autoplot()` | Metode S3 dengan dispatch | `R/11_autoplot` |
| Atlas dan infografis | Atlas Quarto (HTML) dan infografis 1 halaman | `atlas.qmd`, `infografis.pdf` |

## Checkpoint

| Tag | Isi |
|---|---|
| `cp1` | Data bersih + makeover before/after |
| `cp2` | `theme_tim()` + galeri grafik |
| `cp3` | Fungsi grafik + 24 profil + peta |

## Reprodusibilitas

- Semua grafik dihasilkan dari kode. Tidak ada penyuntingan manual, kecuali tata letak infografis.
- Tema (`theme_tim()`) dan palet dibuat sendiri; tidak memakai paket tema siap pakai.
- Warna peta diuji dengan simulasi deuteranopia dan protanopia (`colorspace::deutan()` dan `colorspace::protan()`).
- Angka di narasi atlas dihitung dengan kode inline dari data, bukan diketik manual.

## Catatan Data Lineup

Pengamat lineup mengisi formulir daring, dan anggota Tim 6 (pembuat lineup) tidak dihitung. Bila satu nama mengisi lebih dari sekali, hanya jawaban pertama yang dipakai. Hasil analisis hanya memakai data pengamat sah (n = 12).

## Deklarasi Penggunaan AI

| Alat AI | Digunakan untuk | Cara verifikasi |
|---|---|---|
| Claude | Menulis dan merevisi kode R, membuat kerangka atlas.qmd, dan penysunan draf narasi | Semua kode dijalankan sendiri oleh tim dan hasilnya dicek terhadap data; angka di narasi dihitung dari data (kode inline), bukan diketik dari keluaran AI. Draf narasi keluaran AI kembali direvisi oleh tim agar kalimat yang digunakan dapat lebih mudah dipahami. |

Keputusan analisis (pemilihan indikator, pengelompokan wilayah, tafsiran hasil) dibuat dan diperiksa oleh tim.

## Sumber Data

- Badan Pusat Statistik (BPS), data TPT dan RLS kabupaten/kota Sulawesi Selatan.
- geoBoundaries, batas wilayah administrasi (IDN-ADM2).

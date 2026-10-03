# Draf Makeover: Grafik Tingkat Pengangguran Terbuka (TPT) Sulawesi Selatan

## 1. Sumber grafik asli

- **Judul:** Infografis "Keadaan Ketenagakerjaan Sulawesi Selatan Agustus 2025", bagian "Tingkat Pengangguran Terbuka (TPT)"
- **Penerbit:** BPS Provinsi Sulawesi Selatan
- **Nomor rilis:** Berita Resmi Statistik No. 68/11/73/Th. XXIX, 5 November 2025
- **Tautan:** https://sulsel.bps.go.id/id/infographic?id=358
- **Berkas:** `before.png` (potongan bagian grafik TPT)

## 2. Data pada grafik asli (persen)

Angka dibaca dari infografis. Total TPT bulan Agustus telah dicocokkan dengan data bersih tim (baris "Sulawesi Selatan" pada berkas TPT BPS): 4,33 (2023), 4,19 (2024), dan 4,21 (2025).

| Periode | Laki-laki | Perempuan | Perkotaan | Perdesaan | TPT total |
|---|---|---|---|---|---|
| Ags 2023 | 4,39 | 4,25 | 6,24 | 2,80 | 4,33 |
| Feb 2024 | 5,10 | 4,58 | 6,36 | 3,70 | 4,90 |
| Ags 2024 | 3,76 | 4,85 | 6,20 | 2,44 | 4,19 |
| Feb 2025 | 5,40 | 4,26 | 6,99 | 3,09 | 4,96 |
| Ags 2025 | 4,39 | 3,92 | 6,12 | 2,40 | 4,21 |

## 3. Identifikasi masalah grafik

Analisis masalah berdasarkan prinsip persepsi visual, dampaknya terhadap pembacaan data, cara memperbaiki, serta alasan desain yang merujuk pada prinsip persepsi visual.

### Ringkasan

| No. | Masalah | Prinsip persepsi visual |
|---|---|---|
| 1 | Dua pembagian penduduk yang berbeda dicampur dalam satu kelompok batang | Similarity, Proximity, Grouping |
| 2 | Batang dan garis digabung tanpa sumbu Y dan tanpa skala bersama | Common Scale, Position dan Length, Visual Hierarchy, Grouping/Separation |
| 3 | Pengkodean warna dan legenda lemah | Similarity, Proximity, Pre-attentive Attributes |

### Masalah 1: Dua pembagian penduduk dicampur dalam satu kelompok batang

- **Masalah:** Laki-laki dan perempuan membagi penduduk menurut jenis kelamin, sedangkan perkotaan dan perdesaan membagi penduduk menurut wilayah. Keempatnya ditampilkan sebagai empat kategori yang setara.
- **Prinsip persepsi visual:** Similarity (kesamaan), Proximity (kedekatan), dan Grouping.
- **Dampak:** Pembaca dapat menganggap keempat kategori memiliki dasar klasifikasi yang sama, padahal sebenarnya terdiri atas dua dimensi yang berbeda.
- **Cara memperbaiki:** Memisahkan kategori menjadi dua panel, yaitu panel “Tingkat Pengangguran Terbuka Berdasarkan Jenis Kelamin” yang berisi laki-laki dan perempuan, serta panel “Tingkat Pengangguran Terbuka Berdasarkan Wilayah” yang berisi perkotaan dan pedesaan.
- **Alasan desain:** Pemisahan panel membuat setiap kelompok memiliki dasar klasifikasi yang jelas. Laki-laki dan perempuan dipersepsikan sebagai satu kelompok berdasarkan jenis kelamin, sedangkan perkotaan dan pedesaan sebagai satu kelompok berdasarkan wilayah. Hal ini menerapkan prinsip Similarity, Proximity, dan Grouping sehingga hubungan antar kategori lebih mudah dipahami.

### Masalah 2: Batang dan garis digabung tanpa sumbu Y dan tanpa skala bersama

- **Masalah:** Batang menunjukkan TPT menurut jenis kelamin dan wilayah, sedangkan garis menunjukkan TPT total. Titik TPT 4,33% digambar di atas batang bernilai 6,24%, padahal nilainya lebih kecil.
- **Prinsip persepsi visual:** Common Scale (skala yang sama), Position dan Length (posisi dan panjang), Visual Hierarchy (hierarki visual), dan Grouping/Separation.
- **Dampak:** Posisi vertikal objek tidak merepresentasikan besar nilai secara konsisten, sehingga pembaca memperoleh persepsi keliru tentang perbandingan nilai dan besar perubahan. Pembaca juga harus memahami dua bentuk representasi sekaligus, sehingga fokus menjadi kabur.
- **Cara memperbaiki:** Memisahkan grafik TPT total dalam bentuk garis dari grafik TPT berdasarkan kategori dalam bentuk batang. Ketiga panel menggunakan skala sumbu Y yang sama, yaitu dimulai dari 0 hingga 8 persen.
- **Alasan desain:** Skala Y yang sama membuat posisi dan panjang elemen visual dapat dibandingkan secara langsung antar panel. Pemisahan grafik juga membuat informasi TPT total dan TPT berdasarkan kategori tidak saling bertumpuk. Dengan demikian, prinsip Common Scale, Position and Length, serta Visual Hierarchy dapat diterapkan dengan lebih baik.

### Masalah 3: Pengkodean warna dan legenda lemah

- **Masalah:** Oranye (perempuan) dan cokelat (perkotaan) sama-sama berwarna hangat dan sulit dibedakan, hijau perdesaan mirip hijau penanda TPT, dan legenda terletak jauh di bawah batang dengan ikon kecil.
- **Prinsip persepsi visual:** Similarity (kesamaan warna), Proximity (kedekatan legenda dengan data), dan Pre-attentive Attributes (warna).
- **Dampak:** Kategori yang berbeda tampak serupa dan pembaca harus bolak-balik antara batang dan legenda untuk mencocokkan warna, sehingga beban kognitif meningkat dan risiko salah baca bertambah, terutama bagi pembaca dengan buta warna.
- **Cara memperbaiki:** Menggunakan satu keluarga warna untuk setiap dimensi, yaitu warna biru untuk jenis kelamin dan warna oranye untuk wilayah, dengan perbedaan tingkat kecerahan untuk membedakan kategori. Label kategori juga ditempatkan langsung pada batang sehingga legenda tidak diperlukan.
- **Alasan desain:** Penggunaan keluarga warna yang konsisten membantu pembaca mengenali kategori yang masih berada dalam dimensi yang sama. Label langsung pada batang membuat informasi kategori berada dekat dengan objek yang dijelaskan sehingga mengurangi kebutuhan untuk berpindah antara grafik dan legenda. Perbedaan warna dan kecerahan juga memanfaatkan warna sebagai atribut pre-attentive sehingga kategori dapat dikenali dengan lebih cepat.

## 4. Berkas makeover

| Berkas | Isi |
|---|---|
| `before.png` | Grafik TPT asli (potongan dari infografis BPS) |
| `makeover.R` | Kode R untuk membuat grafik perbaikan |
| `after.png` | Hasil rancangan ulang |
| `catatan.md` | Dokumen ini |

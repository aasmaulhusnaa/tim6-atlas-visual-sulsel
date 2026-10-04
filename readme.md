# Tema Grafik Tim 6: Atlas Visual Sulawesi Selatan

Dokumen ini menjelaskan tema, palet warna, dan aturan visual yang dipakai pada seluruh grafik atlas.

Indikator utama: **TPT** (Tingkat Pengangguran Terbuka, %). Indikator pendamping: **RLS** (Rata-rata Lama Sekolah, tahun).

Cakupan: 24 kabupaten/kota Sulawesi Selatan, 2023-2025.

Tema dibuat sendiri (tidak memakai ggthemes atau paket tema siap pakai). Titik awalnya `theme_minimal()` bawaan ggplot2, lalu dimodifikasi lewat `theme_tim()`.

---

## 1. Palet warna tim

| Elemen | Hex | Warna | Nama di kode |
|---|---|---|---|
| Kota | `#F0E442` | Kuning | `pal_tim[["kota"]]` |
| Kabupaten | `#CC79A7` | Ungu | `pal_tim[["kabupaten"]]` |
| Teks | `#000000` | Hitam | `pal_tim[["teks"]]` |
| Garis tepi titik, garis seri | `#4D4D4D` | Abu gelap | `pal_tim[["tepi"]]` |
| Garis regresi, garis kotak boxplot, garis penghubung dumbbell | `#E69F00` | Oranye | `pal_tim[["garis_utama"]]` |
| Titik 2023 di dumbbell | `#F7F7F7` | Hampir putih | `pal_tim[["titik_2023"]]` |
| Isian kotak, pita, garis bantu | `#D9D9D9` | Abu terang | `pal_tim[["abu_terang"]]` |

Warna kuning, ungu, dan oranye berasal dari palet Okabe-Ito yang dirancang aman bagi penderita buta warna.

**Keputusan tim:**
- Titik 2023 pada dumbbell memakai `#F7F7F7`, bukan `#999999`. Alasannya, `#999999` hampir tidak bisa dibedakan dari ungu kabupaten pada simulasi deuteranopia.
- Warna garis utama memakai oranye `#E69F00`, bukan biru `#0072B2` maupun teal `#009E73`. Alasannya, oranye dari palet Okabe-Ito kontrasnya kuat terhadap latar putih dan abu terang, dan membuat biru bebas dipakai khusus untuk peta koroplet (palet sekuensial Blues).

## 2. Pengkodean jenis wilayah (warna + bentuk)

Jenis wilayah tidak hanya dibedakan dengan warna, tetapi juga dengan bentuk titik, supaya tetap terbaca di cetakan hitam-putih dan oleh penderita buta warna.

| Jenis wilayah | Isian | Bentuk | `shape` ggplot2 |
|---|---|---|---|
| Kabupaten (21 wilayah) | Ungu `#CC79A7` | Lingkaran | 21 |
| Kota (Makassar, Parepare, Palopo) | Kuning `#F0E442` | Persegi | 22 |

Tepian semua titik: abu gelap `#4D4D4D`. Tepian ini wajib karena kuning di latar putih kontrasnya rendah.

Jenis wilayah ditentukan dari kode wilayah: 7371 sampai 7373 adalah kota, sisanya kabupaten.

## 3. Aturan warna per grafik

| No | Grafik | Pengaturan |
|---|---|---|
| 1 | Boxplot + titik | Isian kotak abu terang, garis kotak oranye, titik berisi menurut jenis wilayah dengan tepian abu gelap |
| 2 | Small multiples | Garis seri abu gelap, titik berisi menurut jenis wilayah dengan tepian abu gelap |
| 3 | Scatterplot | Titik berisi menurut jenis wilayah dengan tepian abu gelap. Garis regresi oranye, pita oranye transparan |
| 4 | Titik diurutkan | Titik berisi menurut jenis wilayah dengan tepian abu gelap. Garis bantu abu terang tipis |
| 5 | Dumbbell | Titik 2023 `#F7F7F7`, titik 2025 berisi menurut jenis wilayah dengan tepian abu gelap, garis penghubung oranye. Arah perubahan ditandai garis putus-putus untuk TPT turun dan garis penuh untuk TPT naik (atau panah kecil di ujung titik 2025), tanpa warna baru |
| 6 | Komposisi multipanel | Belum ditentukan (gabungan grafik lain) |
| 7 | Peta koroplet (Hari 9) | Palet sekuensial Blues 7 kelas (`#EFF3FF`, `#C6DBEF`, `#9ECAE1`, `#6BAED6`, `#4292C6`, `#2171B5`, `#084594`), batas wilayah abu gelap `#4D4D4D`, wilayah tanpa data `#D9D9D9` |

## 4. Komponen `theme_tim()`

| Komponen | Pengaturan |
|---|---|
| Titik awal | `theme_minimal()` bawaan ggplot2 |
| Warna teks | Semua teks hitam `#000000` |
| Judul | Tebal, ukuran 1,3 x dasar, rata kiri terhadap seluruh grafik (`plot.title.position = "plot"`) |
| Subjudul | Warna hitam, jarak bawah 10 pt |
| Caption (sumber) | Ukuran 0,8 x dasar, rata kiri, dipakai untuk sumber data dan keterangan garis atau pita |
| Judul sumbu | Ukuran 0,95 x dasar |
| Teks sumbu | Ukuran 0,85 x dasar, tanpa tanda sumbu (`axis.ticks`) |
| Grid | Hanya grid mayor, warna abu terang `#D9D9D9`, tebal 0,3. Pilihan: `"y"` (bawaan), `"x"`, `"xy"`, `"none"`. Grid minor dihapus |
| Border panel | Dihapus |
| Latar | Putih polos |
| Legenda | Posisi atas (bawaan), judul tebal, tanpa latar dan tanpa kotak kunci |
| Facet (strip) | Teks tebal, ukuran 0,8 x dasar, rata kiri, tanpa latar strip. Jarak antarpanel 0,9 baris |
| Margin luar | 12, 14, 10, 12 pt (atas, kanan, bawah, kiri) |

Tidak ada warna di luar palet tim pada tema ini (latar strip facet sengaja dikosongkan).

## 5. Fungsi pendukung

| Fungsi / objek | Kegunaan |
|---|---|
| `pal_tim` | Vektor bernama berisi seluruh warna tim |
| `warna_jenis` | Pemetaan jenis wilayah ke warna isian |
| `bentuk_jenis` | Pemetaan jenis wilayah ke bentuk titik (21 dan 22) |
| `scale_fill_jenis()` | Skala isian menurut jenis wilayah. Judul legenda "Jenis wilayah" |
| `scale_shape_jenis()` | Skala bentuk menurut jenis wilayah. Judul sama dengan skala isian, jadi legenda menyatu |
| `lab_tpt`, `lab_rls` | Label sumbu standar untuk TPT dan RLS |
| `tipe_arah`, `scale_linetype_arah()` | Tipe garis dumbbell menurut arah perubahan: putus-putus untuk "Turun", penuh untuk "Naik". Garis tetap oranye |
| `pal_peta` | Vektor 7 warna Blues (terang ke gelap) untuk peta koroplet |
| `scale_fill_peta()` | Skala isian peta. `tipe = "kelas"` (dengan `n` kelas, 3 sampai 7) atau `"kontinu"`. Wilayah tanpa data abu terang |
| `theme_set(theme_tim())` | Menjadikan tema ini default untuk semua grafik |

## 6. Catatan aksesibilitas

Hasil pengecekan palet dengan simulasi buta warna:

- **Kuning dan ungu** mudah dibedakan pada deuteranopia, protanopia, dan grayscale. Ini pasangan warna utama grafik.
- **Oranye dan kuning** sama-sama hangat dan bisa tampak mirip pada deuteranopia dan protanopia. Keduanya dibedakan oleh fungsi (oranye untuk garis dan pita, kuning untuk isian titik persegi kota) dan oleh bentuk titik. Pada grafik 3, garis regresi dibuat cukup tebal dan pita cukup transparan agar tidak tertukar dengan titik kuning.
- **Peta (Blues)**: terang ke gelapnya berurutan dan tetap terbaca pada deuteranopia, protanopia, dan grayscale. Pada tritanopia corak bergeser ke teal, tetapi urutan kelas tetap terbaca lewat terang-gelap. Biru hanya dipakai di peta, sehingga tidak bentrok dengan warna garis.
- **Kuning** kontrasnya rendah pada latar putih, sehingga selalu dipakai dengan tepian abu gelap.


### Hasil uji

**Palet tim** (kuning, ungu, oranye, abu gelap, dan warna netral), diuji dengan `swatchplot` dari paket `colorspace`:

lihat gambar uji_palet_tim.png di directory ini

*Gambar 1. Palet tim pada penglihatan normal, deuteranopia (Deutan), protanopia (Protan), tritanopia (Tritan), dan grayscale.*

- **Lolos untuk pembeda utama.** Pada deuteranopia dan protanopia, ungu berubah menjadi abu kebiruan sehingga tetap jelas berbeda dari kuning dan oranye. Kuning tetap cerah, sedangkan oranye bergeser menjadi kuning-olive yang lebih gelap, jadi keduanya masih dibedakan oleh tingkat terang.
- **Grayscale.** Kuning sangat terang, ungu dan oranye sedang, dan abu gelap `#4D4D4D` paling gelap, sehingga tepian titik tetap terlihat.
- **Batasan.** Ungu dan oranye berdekatan tingkat terangnya di grayscale. Keduanya tidak tertukar karena fungsinya berbeda (ungu untuk isian titik kabupaten, oranye untuk garis dan pita), dan jenis wilayah juga dibedakan oleh bentuk titik.

**Palet peta** (Blues, 7 kelas):

lihat gambar uji_palet_peta.png di directory ini

*Gambar 2. Palet Blues pada penglihatan normal, deuteranopia (Deutan), protanopia (Protan), tritanopia (Tritan), dan grayscale.*

- **Lolos.** Pada deuteranopia dan protanopia, corak tetap biru dan ketujuh kelas tetap berurutan dari terang ke gelap. Pada tritanopia corak bergeser ke teal, tetapi urutan kelas tetap terbaca lewat terang-gelap.
- **Grayscale.** Kelas menggelap secara bertahap dari kelas 1 sampai 7, jadi peta tetap terbaca pada cetakan hitam-putih.
- **Catatan.** Kelas 1 hampir putih, jadi batas wilayah diberi garis abu gelap. Abu terang untuk wilayah tanpa data sama terangnya dengan kelas 2 pada grayscale. Bila ada wilayah tanpa data, beri keterangan selain warna (misalnya label di legenda atau catatan di caption).

## 7. Berkas terkait

| Berkas | Isi |
|---|---|
| `theme_tim.R` | Palet, skala, label, dan `theme_tim()` (file tema utama) |
| `grafik_tim6.R` | |
| `uji_palet_tim.png`, `uji_palet_peta.png` | Bukti uji buta warna palet tim dan palet peta |

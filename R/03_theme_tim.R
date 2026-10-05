library(ggplot2)

# =============================================================================
# theme_tim.R - Tema Grafik Tim 6: Atlas Visual Sulawesi Selatan
# Dijalankan dari folder utama repositori:  source("R/theme_tim.R")
# Aturan lengkap ada di README.md.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PALET TIM (sesuai tabel "Palet warna tim" di README)
# -----------------------------------------------------------------------------
pal_tim <- c(
  kota        = "#F0E442",  # Kota (kuning)
  kabupaten   = "#CC79A7",  # Kabupaten (ungu)
  teks        = "#000000",  # Teks (hitam)
  judul       = "#0072B2",  # Judul grafik (biru Okabe-Ito), hanya judul
  tepi        = "#4D4D4D",  # Garis tepi titik, garis seri (abu gelap)
  garis_utama = "#D55E00",  # Garis regresi, garis kotak boxplot, penghubung dumbbell (vermilion)
  titik_2023  = "#F7F7F7",  # Titik 2023 di dumbbell (hampir putih, bertepian abu gelap)
  abu_terang  = "#D9D9D9"   # Isian kotak, pita, garis bantu
)

# -----------------------------------------------------------------------------
# 2. JENIS WILAYAH: warna + bentuk (grafik 1-5)
#    Kabupaten = lingkaran ungu (shape 21), Kota = persegi kuning (shape 22).
#    Shape 21 dan 22 dapat diisi (fill) dan bertepian (color = pal_tim[["tepi"]]).
# -----------------------------------------------------------------------------
warna_jenis <- c("Kabupaten" = pal_tim[["kabupaten"]],
                 "Kota"      = pal_tim[["kota"]])

bentuk_jenis <- c("Kabupaten" = 21, "Kota" = 22)

scale_fill_jenis <- function(...) {
  ggplot2::scale_fill_manual(values = warna_jenis, name = "Jenis wilayah", ...)
}

# Judul sama dengan skala isian, jadi legenda warna dan bentuk menyatu.
scale_shape_jenis <- function(...) {
  ggplot2::scale_shape_manual(values = bentuk_jenis, name = "Jenis wilayah", ...)
}

# -----------------------------------------------------------------------------
# 3. DUMBBELL: arah perubahan lewat tipe garis, bukan warna baru
#    Garis penghubung tetap vermilion (pal_tim[["garis_utama"]]).
#    Contoh: geom_segment(aes(linetype = arah), color = pal_tim[["garis_utama"]])
#    dengan kolom `arah` berisi "Naik" atau "Turun".
# -----------------------------------------------------------------------------
tipe_arah <- c("Turun" = "dashed", "Naik" = "solid")

scale_linetype_arah <- function(...) {
  ggplot2::scale_linetype_manual(values = tipe_arah,
                                 name = "Arah TPT 2023-2025", ...)
}

# -----------------------------------------------------------------------------
# 4. LABEL SUMBU
# -----------------------------------------------------------------------------
lab_tpt <- "Tingkat Pengangguran Terbuka (%)"
lab_rls <- "Rata-rata Lama Sekolah (tahun)"

# -----------------------------------------------------------------------------
# 5. PETA KOROPLET: palet sekuensial Blues 7 kelas (terang ke gelap)
#    Lolos simulasi deuteranopia, protanopia, tritanopia, dan grayscale
#    (lihat README bagian 7). Biru dipakai untuk peta dan judul, bukan garis.
#    Tinggi = gelap. Beri garis batas wilayah abu gelap (pal_tim[["tepi"]])
#    karena kelas terendah hampir putih.
# -----------------------------------------------------------------------------
pal_peta <- c("#EFF3FF", "#C6DBEF", "#9ECAE1", "#6BAED6",
              "#4292C6", "#2171B5", "#084594")

# tipe = "kelas"  : data berkelas (faktor), n = jumlah kelas (3 sampai 7)
# tipe = "kontinu": data numerik kontinu
# Wilayah tanpa data memakai abu terang.
scale_fill_peta <- function(tipe = c("kelas", "kontinu"), n = 7,
                            name = lab_tpt, ...) {
  tipe <- match.arg(tipe)
  if (tipe == "kelas") {
    stopifnot(n >= 3, n <= 7)
    warna <- pal_peta[round(seq(1, length(pal_peta), length.out = n))]
    ggplot2::scale_fill_manual(values = warna, name = name, drop = FALSE,
                               na.value = pal_tim[["abu_terang"]], ...)
  } else {
    ggplot2::scale_fill_gradientn(colours = pal_peta, name = name,
                                  na.value = pal_tim[["abu_terang"]], ...)
  }
}

# -----------------------------------------------------------------------------
# 6. THEME_TIM()
#    Semua teks hitam kecuali judul (biru), grid mayor abu terang, tanpa warna
#    di luar palet tim.
#    Argumen grid: "y" (bawaan), "x", "xy", atau "none".
# -----------------------------------------------------------------------------
theme_tim <- function(base_size = 11, base_family = "",
                      grid = c("y", "x", "xy", "none"),
                      legend = "top") {
  grid  <- match.arg(grid)
  garis <- element_line(color = pal_tim[["abu_terang"]], linewidth = 0.3)
  hitam <- pal_tim[["teks"]]

  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      text = element_text(color = hitam),

      # judul, subjudul, caption (rata kiri terhadap seluruh grafik)
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.title    = element_text(face = "bold", size = base_size * 1.5,
                                   color = pal_tim[["judul"]], margin = margin(b = 6)),
      plot.subtitle = element_text(color = hitam, margin = margin(b = 10)),
      plot.caption  = element_text(color = hitam, size = base_size * 0.8,
                                   hjust = 0, margin = margin(t = 10)),

      # sumbu (tanpa tanda sumbu)
      axis.title   = element_text(size = base_size * 0.95, color = hitam),
      axis.title.x = element_text(margin = margin(t = 8)),
      axis.title.y = element_text(margin = margin(r = 8)),
      axis.text    = element_text(size = base_size * 0.85, color = hitam),
      axis.ticks   = element_blank(),

      # grid, panel, latar putih polos
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank(),
      panel.border     = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background  = element_rect(fill = "white", color = NA),

      # legenda: judul tebal, tanpa latar, tanpa kotak kunci
      legend.position   = legend,
      legend.title      = element_text(face = "bold", size = base_size * 0.9,
                                       color = hitam),
      legend.text       = element_text(size = base_size * 0.85, color = hitam),
      legend.background = element_blank(),
      legend.key        = element_blank(),

      # facet / small multiples (latar strip dikosongkan agar tetap dalam palet)
      strip.text       = element_text(face = "bold", size = base_size * 0.8,
                                      hjust = 0, color = hitam),
      strip.background = element_blank(),
      panel.spacing    = grid::unit(0.9, "lines"),

      plot.margin = margin(12, 14, 10, 12)
    ) +
    switch(grid,
           y    = theme(panel.grid.major.y = garis),
           x    = theme(panel.grid.major.x = garis),
           xy   = theme(panel.grid.major   = garis),
           none = theme())
}

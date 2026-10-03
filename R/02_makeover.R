library(tidyverse)
library(patchwork)
library(here)

folder_proyek <- "C:/Users/ThinkPad E14/Documents/STATISTIK/PROJECT KOMSTAT TIM 6"
dir_makeover <- file.path(folder_proyek, "keluaran", "makeover")
dir.create(dir_makeover, recursive = TRUE, showWarnings = FALSE)


# ==== 1. Data (disalin dari grafik resmi BPS) ================================
periode_lv <- c("Ags 2023", "Feb 2024", "Ags 2024", "Feb 2025", "Ags 2025")

tpt_wide <- tibble(
  periode   = factor(periode_lv, levels = periode_lv),
  total     = c(4.33, 4.90, 4.19, 4.96, 4.21),
  laki_laki = c(4.39, 5.10, 3.76, 5.40, 4.39),
  perempuan = c(4.25, 4.58, 4.85, 4.26, 3.92),
  perkotaan = c(6.24, 6.36, 6.20, 6.99, 6.12),
  pedesaan = c(2.80, 3.70, 2.44, 3.09, 2.40)
)

# Pemeriksaan: BPS menyatakan TPT Ags 2025 naik 0,02 poin dari Ags 2024.
stopifnot(
  nrow(tpt_wide) == 5,
  isTRUE(all.equal(tpt_wide$total[5] - tpt_wide$total[3], 0.02)),
  !anyNA(tpt_wide)
)

# Satu keluarga warna per dimensi (biru = jenis kelamin, oranye = wilayah),
# gelap vs terang agar tetap terbedakan oleh pembaca buta warna.
kategori_info <- tribble(
  ~kode,       ~kategori,    ~dimensi,         ~warna,    ~warna_teks,
  "laki_laki", "Laki-laki",  "Jenis kelamin",  "#08519C", "white",
  "perempuan", "Perempuan",  "Jenis kelamin",  "#9ECAE1", "white",
  "perkotaan", "Perkotaan",  "Wilayah",        "#A63603", "white",
  "pedesaan", "pedesaan",  "Wilayah",        "#FDAE6B", "white"
)

tpt_total <- select(tpt_wide, periode, nilai = total)

tpt_kat <- tpt_wide |>
  select(-total) |>
  pivot_longer(-periode, names_to = "kode", values_to = "nilai") |>
  left_join(kategori_info, by = "kode")

# ==== 2. Tema sendiri =========================================================
tema_makeover <- function(ukuran = 11) {
  theme(
    text                  = element_text(colour = "grey15", size = ukuran),
    plot.title            = element_text(face = "bold", size = ukuran + 1,
                                         hjust = 0),
    plot.title.position   = "plot",
    plot.subtitle         = element_text(colour = "red"),
    plot.caption          = element_text(colour = "grey40", size = ukuran - 3,
                                         hjust = 0),
    plot.caption.position = "plot",
    panel.background      = element_blank(),
    panel.grid.major.y    = element_line(colour = "grey88", linewidth = 0.3),
    panel.grid.major.x    = element_blank(),
    panel.grid.minor      = element_blank(),
    axis.ticks            = element_blank(),
    axis.line.x           = element_line(colour = "grey50", linewidth = 0.4),
    axis.text             = element_text(colour = "grey25"),
    legend.position       = "none",          # label langsung, tanpa legenda
    plot.margin           = margin(8, 10, 8, 10)
  )
}

fmt <- scales::label_number(accuracy = 0.01, decimal.mark = ",")

# Skala Y bersama untuk SEMUA panel (Common Scale), dimulai dari nol.
skala_y <- scale_y_continuous(
  limits = c(0, 8), breaks = seq(0, 8, 2),
  expand = expansion(mult = c(0, 0.02))
)

# ==== 3. Panel 1: TPT total (garis) ==========================================
p_total <- ggplot(tpt_total, aes(x = periode, y = nilai, group = 1)) +
  geom_line(colour = "blue2", linewidth = 0.9) +
  geom_point(colour = "blue2", size = 2.8) +
  geom_text(aes(label = fmt(nilai)), vjust = -1.1, size = 3.5,
            fontface = "bold", colour = "grey15") +
  skala_y +
  labs(title = "Total Tingkat Pengangguran Terbuka",
       x = NULL, y = "persen (%)") +
  tema_makeover()

# ==== 4. Fungsi panel batang (satu dimensi per panel) ========================
buat_panel <- function(data, judul) {
  data <- data |> mutate(kategori = factor(kategori, levels = unique(kategori)))
  periode_awal <- levels(data$periode)[1]
  
  ggplot(data, aes(x = periode, y = nilai, group = kategori)) +
    geom_col(aes(fill = warna),
             position = position_dodge(width = 0.8), width = 0.75) +
    # nilai di ujung batang
    geom_text(aes(label = fmt(nilai)),
              position = position_dodge(width = 0.8),
              vjust = -0.4, size = 3, colour = "grey15") +
    # label langsung nama kategori pada batang kelompok pertama
    geom_text(data = filter(data, periode == periode_awal),
              aes(label = kategori, y = 0.15, colour = warna_teks),
              position = position_dodge(width = 0.8),
              angle = 90, hjust = 0, size = 3, fontface = "bold") +
    scale_fill_identity() +
    scale_colour_identity() +
    skala_y +
    labs(title = judul, x = NULL, y = NULL) +
    tema_makeover()
}

p_jk <- tpt_kat |>
  filter(dimensi == "Jenis kelamin") |>
  buat_panel("Tingkat Pengangguran Terbuka Berdasarkan Jenis Kelamin")

p_wil <- tpt_kat |>
  filter(dimensi == "Wilayah") |>
  buat_panel("Tingkat Pengangguran Terbuka Berdasarkan Wilayah")

# ==== 5. Rakit dengan patchwork ==============================================
grafik_akhir <- p_total / (p_jk | p_wil) +
  plot_layout(heights = c(1, 1.5)) +
  plot_annotation(
    title    = "Tingkat Pengangguran Terbuka Sulawesi Selatan",
    subtitle = "Periode Agustus 2023 - Agustus 2025 (persen)",
    caption  = paste0("Sumber: BPS Provinsi Sulawesi Selatan, Berita Resmi ",
                      "Statistik No. 68/11/73/Th. XXIX, 5 November 2025. ",
                      "Digambar ulang oleh Tim 6"),
    theme    = tema_makeover()
  )

grafik_akhir

# ==== 6. Simpan ==============================================================
dir.create(here("keluaran", "makeover"), showWarnings = FALSE, recursive = TRUE)
ggsave(here("keluaran", "makeover", "tpt_after.png"), grafik_akhir,
       width = 11, height = 8, dpi = 300, bg = "white")


# ==== 7. Tabel analisis masalah (untuk atlas.qmd) ============================
tabel_masalah <- tribble(
  ~No, ~Masalah, ~`Prinsip persepsi visual`, ~Dampak, ~Perbaikan, ~`Alasan desain`,
  1, "Dua pembagian penduduk (jenis kelamin dan wilayah) dicampur dalam satu kelompok batang.",
  "Similarity, Proximity, Grouping",
  "Pembaca mengira keempat kategori berasal dari dasar klasifikasi yang sama.",
  "Pisahkan menjadi dua panel: jenis kelamin dan wilayah.",
  "Objek yang berdekatan dalam satu panel dipersepsi sebagai satu kelompok; satu dimensi per panel.",
  2, "Batang dan garis digabung tanpa sumbu Y dan skala bersama; titik TPT digambar di atas batang yang lebih tinggi.",
  "Common Scale, Position and Length, Visual Hierarchy",
  "Posisi vertikal tidak mewakili besar nilai; fokus pembaca menjadi kabur.",
  "Pisahkan garis (TPT total) dan batang (per kategori); semua panel satu skala Y mulai dari nol.",
  "Posisi dan panjang pada skala sama adalah tugas persepsi paling akurat; satu grafik, satu pesan.",
  3, "Pengkodean warna dan legenda lemah: oranye dan cokelat sama-sama hangat, hijau ganda, legenda jauh, ikon kecil.",
  "Similarity, Proximity, Pre-attentive attributes",
  "Pembaca bolak-balik ke legenda; risiko salah baca, terutama bagi pembaca buta warna.",
  "Satu keluarga warna per dimensi (biru, oranye) dengan gelap-terang kontras; label langsung pada batang; ikon dihapus.",
  "Label dekat objek mengurangi beban kognitif; warna sebagai atribut pre-attentive dikenali tanpa usaha sadar."
)

# Di atlas.qmd:  knitr::kable(tabel_masalah)
tabel_masalah

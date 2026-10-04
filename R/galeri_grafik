# galeri_grafik.R
# =============================================================================
# Galeri grafik statistik Tim 6 (Grafik 1 sampai 5; Grafik 6 = patchwork, terpisah)
#   1. Boxplot + titik: sebaran TPT 24 wilayah per tahun, kota disorot
#   2. Small multiples: tren TPT 2023-2025, 24 panel
#   3. Scatterplot TPT vs RLS + garis regresi + pita kepercayaan 95%
#   4. Titik diurutkan: TPT tahun terpilih, dari tertinggi
#   5. Dumbbell: perubahan TPT tahun awal ke tahun akhir, diurutkan
#
# Memakai: theme_tim/03_theme_tim.R (palet, skala, tema) dan data_bersih.csv
#
# CARA MENJALANKAN: folder kerja R = folder utama repositori
#   (cek dengan getwd(); kalau belum, jalankan setwd("...") di Console).
# Setelah skrip jalan, objek grafik_1 ... grafik_5 tersedia. Lihat satu per satu
# dengan print(grafik_2), atau gunakan panah di panel Plots dan tombol Zoom.
# =============================================================================

# -----------------------------------------------------------------------------
# 0. PENGATURAN
# -----------------------------------------------------------------------------
pola_tema <- "theme_tim.*\\.R(\\.txt)?$"   # mis. 03_theme_tim.R
pola_data <- "data_bersih.*\\.rds$"        # mis. data_bersih.csv

tahun_pilih <- 2025   # untuk grafik 3 dan 4
th_awal     <- 2023   # untuk grafik 5 (dumbbell)
th_akhir    <- 2025

# -----------------------------------------------------------------------------
# 1. PAKET DAN TEMA TIM
# -----------------------------------------------------------------------------
library(ggplot2)

cari_berkas <- function(pola, nama) {
  hasil <- list.files(".", pattern = pola, recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
  if (length(hasil) == 0) {
    semua <- list.files(".", pattern = "\\.(R|csv)", recursive = TRUE,
                        ignore.case = TRUE)
    stop("File ", nama, " tidak ditemukan.\nFolder kerja: ", getwd(),
         "\nFile .R dan .csv yang terlihat di folder ini:\n",
         paste(" -", semua, collapse = "\n"),
         "\nPastikan folder kerja adalah folder utama repositori.")
  }
  if (length(hasil) > 1) {
    message("Ada lebih dari satu kandidat untuk ", nama, ", dipakai yang pertama:\n",
            paste(" -", hasil, collapse = "\n"))
  }
  hasil[1]
}

berkas_tema <- cari_berkas(pola_tema, "tema (theme_tim)")
berkas_data <- cari_berkas(pola_data, "data (data_bersih.rds)")
cat("Tema :", berkas_tema, "\nData :", berkas_data, "\n")
source(berkas_tema)
theme_set(theme_tim())

# -----------------------------------------------------------------------------
# 2. BACA DAN SIAPKAN DATA
# -----------------------------------------------------------------------------
dat <- readRDS(berkas_data)
# File RDS tampaknya berupa objek spasial sf.
# Untuk galeri grafik ini, atribut tabel saja yang dibutuhkan.
if (inherits(dat, "sf")) {
  dat <- sf::st_drop_geometry(dat)
}

perlu  <- c("kode_wilayah", "kabupaten", "tahun", "tpt", "rls")
hilang <- setdiff(perlu, names(dat))
if (length(hilang) > 0) {
  stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "),
       "\nKolom yang ada: ", paste(names(dat), collapse = ", "))
}
str(dat)

dat$tahun <- as.integer(dat$tahun)
dat$tpt   <- as.numeric(dat$tpt)
dat$rls   <- as.numeric(dat$rls)

# jenis wilayah: kode 7371-7373 (Makassar, Parepare, Palopo) = Kota
dat$jenis <- factor(ifelse(dat$kode_wilayah >= 7371, "Kota", "Kabupaten"),
                    levels = c("Kabupaten", "Kota"))

# label singkat
dat$label <- dat$kabupaten
dat$label[dat$label == "Pangkajene dan Kepulauan"] <- "Pangkep"
dat$label[dat$label == "Sindereng Rappang"]        <- "Sidrap"

# format angka desimal koma untuk teks
koma <- function(x, d = 2) format(round(x, d), nsmall = d, decimal.mark = ",")

# =============================================================================
# GRAFIK 1: Boxplot + titik (sebaran TPT per tahun, kota disorot)
#   Isian kotak abu terang, garis kotak garis_utama, titik berisi menurut jenis
#   wilayah (bentuk berbeda) dengan tepian abu gelap. Kota diberi label.
# =============================================================================
dat$tahun_f  <- factor(dat$tahun)
d_kab        <- dat[dat$jenis == "Kabupaten", ]
d_kota       <- dat[dat$jenis == "Kota", ]
d_kota_akhir <- d_kota[d_kota$tahun == max(dat$tahun), ]

med      <- tapply(dat$tpt, dat$tahun, median)
teks_med <- paste0(names(med), ": ", koma(med), "%", collapse = " | ")

grafik_1 <- ggplot(dat, aes(x = tahun_f, y = tpt)) +
  geom_boxplot(fill = pal_tim[["abu_terang"]], color = pal_tim[["garis_utama"]],
               width = 0.45, linewidth = 0.7, outlier.shape = NA) +
  geom_point(data = d_kab, aes(fill = jenis, shape = jenis),
             position = position_jitter(width = 0.12, height = 0, seed = 2026),
             size = 2.8, stroke = 0.6, color = pal_tim[["tepi"]]) +
  geom_point(data = d_kota, aes(fill = jenis, shape = jenis),
             size = 3.2, stroke = 0.7, color = pal_tim[["tepi"]]) +
  geom_text(data = d_kota_akhir, aes(label = label),
            hjust = -0.3, size = 3.3, color = pal_tim[["teks"]]) +
  scale_fill_jenis() +
  scale_shape_jenis() +
  scale_x_discrete(expand = expansion(add = c(0.6, 1.1))) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
  labs(
    title    = "Sebaran TPT 24 kabupaten/kota Sulawesi Selatan per tahun",
    subtitle = paste0("Setiap titik satu wilayah; kota diberi label. Median TPT: ", teks_med),
    x        = NULL,
    y        = lab_tpt,
    caption  = "Kotak: kuartil dan median (garis tengah). Sumber: BPS, diolah Tim 6 oleh Tim 6."
  ) +
  theme_tim(grid = "y")

print(grafik_1)

# =============================================================================
# GRAFIK 2: Small multiples, tren TPT per wilayah (24 panel)
#   Garis seri abu gelap; titik berisi menurut jenis wilayah, tepian abu gelap.
#   Skala sumbu y sama di semua panel agar bisa dibandingkan.
#   Panel diurutkan dari TPT tahun akhir tertinggi.
# =============================================================================
urut_wilayah <- dat[dat$tahun == th_akhir, ]
urut_wilayah <- urut_wilayah$label[order(urut_wilayah$tpt, decreasing = TRUE)]
dat$label_f  <- factor(dat$label, levels = urut_wilayah)

grafik_2 <- ggplot(dat, aes(x = tahun, y = tpt)) +
  geom_line(color = pal_tim[["tepi"]], linewidth = 0.7) +
  geom_point(aes(fill = jenis, shape = jenis), size = 2.4, stroke = 0.6,
             color = pal_tim[["tepi"]]) +
  facet_wrap(~ label_f, ncol = 6) +
  scale_fill_jenis() +
  scale_shape_jenis() +
  scale_x_continuous(breaks = range(dat$tahun), expand = expansion(mult = 0.18)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(
    title    = paste0("Tren TPT ", min(dat$tahun), "-", max(dat$tahun),
                      " di 24 kabupaten/kota Sulawesi Selatan"),
    subtitle = paste0("Panel diurutkan dari TPT ", th_akhir, " tertinggi"),
    x        = NULL,
    y        = lab_tpt,
    caption  = "Sumber: BPS, diolah Tim 6."
  ) +
  theme_tim(grid = "y") +
  theme(axis.text.x = element_text(size = 8),
        strip.text  = element_text(size = 10))

print(grafik_2)

# =============================================================================
# GRAFIK 3: Scatterplot TPT vs RLS + garis regresi + pita kepercayaan 95%
#   Titik berisi menurut jenis wilayah; garis dan pita memakai garis_utama.
#   Tiga wilayah dengan TPT tertinggi diberi label.
# =============================================================================
d3 <- dat[dat$tahun == tahun_pilih, ]
if (nrow(d3) == 0) stop("Tidak ada data untuk tahun ", tahun_pilih)
d3_label <- d3[order(d3$tpt, decreasing = TRUE)[1:3], ]

r3   <- cor(d3$rls, d3$tpt)
arah <- ifelse(r3 > 0, "lebih tinggi", "lebih rendah")

grafik_3 <- ggplot(d3, aes(x = rls, y = tpt)) +
  geom_smooth(method = "lm", formula = y ~ x, level = 0.95,
              color = pal_tim[["garis_utama"]], fill = pal_tim[["garis_utama"]],
              alpha = 0.2, linewidth = 0.9) +
  geom_point(aes(fill = jenis, shape = jenis), size = 3.2, stroke = 0.7,
             color = pal_tim[["tepi"]]) +
  geom_text(data = d3_label, aes(label = label),
            color = pal_tim[["teks"]], fontface = "bold", size = 3.4,
            hjust = 1, nudge_x = -0.12) +
  scale_fill_jenis() +
  scale_shape_jenis() +
  scale_x_continuous(expand = expansion(mult = 0.06)) +
  labs(
    title    = paste0("Wilayah dengan RLS lebih tinggi cenderung memiliki TPT ", arah),
    subtitle = paste0("24 kabupaten/kota Sulawesi Selatan, ", tahun_pilih,
                      " (r = ", koma(r3), "). Tiga wilayah dengan TPT tertinggi diberi label."),
    x        = lab_rls,
    y        = lab_tpt,
    caption  = "Garis: regresi linear; pita: selang kepercayaan 95%.\nSumber: BPS, diolah Tim 6."
  ) +
  theme_tim(grid = "xy")

print(grafik_3)

# =============================================================================
# GRAFIK 4: Titik diurutkan (Cleveland dot plot), TPT tahun terpilih
#   Titik berisi menurut jenis wilayah; garis bantu abu terang tipis dari nol.
# =============================================================================
d4 <- dat[dat$tahun == tahun_pilih, ]
d4$label_urut <- reorder(d4$label, d4$tpt)   # tertinggi di atas

grafik_4 <- ggplot(d4, aes(x = tpt, y = label_urut)) +
  geom_segment(aes(x = 0, xend = tpt, yend = label_urut),
               color = pal_tim[["abu_terang"]], linewidth = 0.4) +
  geom_point(aes(fill = jenis, shape = jenis), size = 3.2, stroke = 0.7,
             color = pal_tim[["tepi"]]) +
  geom_text(aes(label = koma(tpt)), hjust = -0.7, size = 3,
            color = pal_tim[["teks"]]) +
  scale_fill_jenis() +
  scale_shape_jenis() +
  scale_x_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(
    title    = paste0("TPT ", tahun_pilih, " per kabupaten/kota Sulawesi Selatan"),
    x        = lab_tpt,
    y        = NULL,
    caption  = "Sumber: BPS, diolah Tim 6."
  ) +
  theme_tim(grid = "x")

print(grafik_4)

# =============================================================================
# GRAFIK 5: Dumbbell, perubahan TPT tahun awal ke tahun akhir (diurutkan)
#   Titik tahun awal: titik_2023 (bertepian abu gelap). Titik tahun akhir:
#   isian dan bentuk menurut jenis wilayah. Garis penghubung: garis_utama,
#   arah perubahan lewat tipe garis (Naik = solid, Turun = putus-putus).
# =============================================================================
d_awal  <- dat[dat$tahun == th_awal,  c("kode_wilayah", "tpt")]
d_akhir <- dat[dat$tahun == th_akhir, c("kode_wilayah", "label", "jenis", "tpt")]
if (nrow(d_awal) == 0 || nrow(d_akhir) == 0) {
  stop("Data untuk tahun ", th_awal, " atau ", th_akhir, " tidak ada.")
}
names(d_awal)[2]  <- "tpt_awal"
names(d_akhir)[4] <- "tpt_akhir"

dumb <- merge(d_akhir, d_awal, by = "kode_wilayah")
dumb$perubahan <- dumb$tpt_akhir - dumb$tpt_awal
dumb$arah  <- factor(ifelse(dumb$perubahan > 0, "Naik", "Turun"),
                     levels = c("Turun", "Naik"))
dumb$label <- reorder(dumb$label, dumb$perubahan)   # kenaikan terbesar di atas

kat_awal <- as.character(th_awal)
titik <- rbind(
  data.frame(label = dumb$label, jenis = dumb$jenis,
             tpt = dumb$tpt_awal,  kategori = kat_awal),
  data.frame(label = dumb$label, jenis = dumb$jenis,
             tpt = dumb$tpt_akhir, kategori = as.character(dumb$jenis))
)

warna_dumb <- c(pal_tim[["titik_2023"]], warna_jenis[["Kabupaten"]], warna_jenis[["Kota"]])
names(warna_dumb) <- c(kat_awal, "Kabupaten", "Kota")
n_naik <- sum(dumb$perubahan > 0)

grafik_5 <- ggplot() +
  geom_segment(data = dumb,
               aes(x = tpt_awal, xend = tpt_akhir,
                   y = label, yend = label, linetype = arah),
               color = pal_tim[["garis_utama"]], linewidth = 1) +
  geom_point(data = titik,
             aes(x = tpt, y = label, fill = kategori, shape = jenis),
             size = 3.2, stroke = 0.7, color = pal_tim[["tepi"]]) +
  scale_fill_manual(
    values = warna_dumb,
    breaks = c(kat_awal, "Kabupaten", "Kota"),
    labels = c(kat_awal, paste0("Kabupaten, ", th_akhir), paste0("Kota, ", th_akhir)),
    name   = NULL
  ) +
  scale_shape_jenis() +
  scale_linetype_arah() +
  guides(
    fill     = guide_legend(order = 1,
                            override.aes = list(shape = c(21, 21, 22), size = 3.2)),
    shape    = "none",
    linetype = guide_legend(order = 2)
  ) +
  labs(
    title    = paste0("Perubahan TPT kabupaten/kota Sulawesi Selatan, ", th_awal, " ke ", th_akhir),
    subtitle = paste0("TPT naik di ", n_naik, " dari ", nrow(dumb),
                      " wilayah"),
    x        = lab_tpt,
    y        = NULL,
    caption  = paste0("Titik hampir putih: ", th_awal, "; titik berwarna: ", th_akhir,
                      ". Garis solid: TPT naik; garis putus-putus: TPT turun.\n",
                      "Sumber: BPS, diolah Tim 6.")
  ) +
  theme_tim(grid = "y") +
  theme(legend.key.width = grid::unit(2, "lines"))

print(grafik_5)

# =============================================================================
# GRAFIK 6: Komposisi multipanel (patchwork) dari grafik 3, 4, dan 5
#   Urutan dari atas: judul, subjudul, SATU legenda gabungan (di tengah),
#   panel A (scatterplot, setengah lebar di tengah), lalu panel B (titik
#   diurutkan) dan C (dumbbell) berdampingan.
#   Semua panel tanpa legenda sendiri. Judul panel hitam dan lebih kecil.
# =============================================================================
if (!requireNamespace("patchwork", quietly = TRUE)) {
  stop("Paket 'patchwork' belum terpasang. Jalankan: install.packages('patchwork')")
}
library(patchwork)

# korelasi semua wilayah vs hanya kabupaten (untuk pesan utama)
kab3  <- d3[d3$jenis == "Kabupaten", ]
r_kab <- cor(kab3$rls, kab3$tpt)

if (abs(r3) - abs(r_kab) > 0.3) {
  judul_6 <- "Hubungan TPT dan RLS tampak kuat, tetapi didorong terutama oleh tiga kota"
} else {
  judul_6 <- paste0("Wilayah dengan RLS lebih tinggi cenderung memiliki TPT ", arah)
}
subjudul_6 <- paste0("Korelasi TPT-RLS ", tahun_pilih, ": semua wilayah r = ", koma(r3),
                     "; hanya kabupaten r = ", koma(r_kab), ". TPT naik di ", n_naik,
                     " dari ", nrow(dumb), " wilayah pada ", th_awal, "-", th_akhir, ".")
caption_6 <- paste0(
  "A: garis regresi linear dan pita kepercayaan 95%; tiga TPT tertinggi diberi label. ",
  "B: diurutkan dari TPT tertinggi. C: diurutkan dari kenaikan terbesar. ",
  "Sumber: BPS, diolah Tim 6.")

# -----------------------------------------------------------------------------
# LEGENDA GABUNGAN (digambar sebagai satu strip, ditaruh di bawah subjudul)
#   Jenis wilayah: Kabupaten, Kota | titik awal (2023) | Arah TPT: Turun, Naik
#   Posisi dihitung otomatis dari perkiraan lebar teks, lalu ditengahkan.
# -----------------------------------------------------------------------------
lebar_kanvas <- 14   # samakan dengan width pada ggsave
lw <- function(x, tebal = FALSE) nchar(x) * ifelse(tebal, 0.075, 0.062) + 0.05

item <- list(
  list(tipe = "judul", label = "Jenis wilayah"),
  list(tipe = "titik", label = "Kabupaten", shape = 21, fill = warna_jenis[["Kabupaten"]]),
  list(tipe = "titik", label = "Kota",      shape = 22, fill = warna_jenis[["Kota"]]),
  list(tipe = "jeda"),
  list(tipe = "titik", label = paste0(th_awal, " (titik awal)"), shape = 21,
       fill = pal_tim[["titik_2023"]]),
  list(tipe = "jeda"),
  list(tipe = "judul", label = "Arah TPT"),
  list(tipe = "garis", label = "Turun", lt = tipe_arah[["Turun"]]),
  list(tipe = "garis", label = "Naik",  lt = tipe_arah[["Naik"]])
)

x <- 0; l_pt <- l_gr <- l_tx <- list()
for (it in item) {
  if (it$tipe == "jeda") { x <- x + 0.5; next }
  if (it$tipe == "judul") {
    l_tx[[length(l_tx) + 1]] <- data.frame(x = x, label = it$label, face = "bold")
    x <- x + lw(it$label, TRUE) + 0.25
  } else if (it$tipe == "titik") {
    l_pt[[length(l_pt) + 1]] <- data.frame(x = x + 0.1, shape = it$shape, fill = it$fill)
    l_tx[[length(l_tx) + 1]] <- data.frame(x = x + 0.28, label = it$label, face = "plain")
    x <- x + 0.28 + lw(it$label) + 0.3
  } else {
    l_gr[[length(l_gr) + 1]] <- data.frame(x = x, xend = x + 0.5, lt = it$lt)
    l_tx[[length(l_tx) + 1]] <- data.frame(x = x + 0.6, label = it$label, face = "plain")
    x <- x + 0.6 + lw(it$label) + 0.3
  }
}
geser <- (lebar_kanvas - (x - 0.3)) / 2    # menengahkan seluruh legenda
d_pt <- do.call(rbind, l_pt); d_pt$x <- d_pt$x + geser; d_pt$y <- 0.5
d_gr <- do.call(rbind, l_gr); d_gr$x <- d_gr$x + geser; d_gr$xend <- d_gr$xend + geser; d_gr$y <- 0.5
d_tx <- do.call(rbind, l_tx); d_tx$x <- d_tx$x + geser; d_tx$y <- 0.5

p_leg <- ggplot() +
  geom_segment(data = d_gr, aes(x = x, xend = xend, y = y, yend = y, linetype = lt),
               color = pal_tim[["garis_utama"]], linewidth = 0.8) +
  geom_point(data = d_pt, aes(x = x, y = y, shape = shape, fill = fill),
             size = 2.6, stroke = 0.6, color = pal_tim[["tepi"]]) +
  geom_text(data = d_tx, aes(x = x, y = y, label = label, fontface = face),
            hjust = 0, size = 3, color = pal_tim[["teks"]]) +
  scale_shape_identity() + scale_fill_identity() + scale_linetype_identity() +
  coord_cartesian(xlim = c(0, lebar_kanvas), ylim = c(0, 1), expand = FALSE) +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0))

# -----------------------------------------------------------------------------
# PANEL (semua tanpa legenda sendiri)
# -----------------------------------------------------------------------------
gaya_panel <- theme(plot.title = element_text(face = "bold", size = 12,
                                              color = pal_tim[["teks"]],
                                              margin = margin(b = 6)),
                    legend.position = "none")
sumbu_y_kecil <- theme(axis.text.y = element_text(size = 8))

p_a <- grafik_3 +
  scale_y_continuous(expand = expansion(mult = c(0.08, 0.15))) +
  labs(title = paste0("A. TPT dan RLS, ", tahun_pilih), subtitle = NULL, caption = NULL,
       y = "TPT (%)") +
  gaya_panel

# panel B: ganti label angka dengan versi lebih kecil agar tidak menumpuk
p_b <- grafik_4
p_b$layers <- Filter(function(l) !inherits(l$geom, "GeomText"), p_b$layers)
p_b <- p_b +
  geom_text(aes(label = koma(tpt)), hjust = -0.6, size = 2.6, color = pal_tim[["teks"]]) +
  labs(title = paste0("B. TPT ", tahun_pilih, " per wilayah"), subtitle = NULL, caption = NULL) +
  gaya_panel + sumbu_y_kecil

p_c <- grafik_5 +
  labs(title = paste0("C. Perubahan TPT ", th_awal, " ke ", th_akhir),
       subtitle = NULL, caption = NULL) +
  gaya_panel + sumbu_y_kecil

# -----------------------------------------------------------------------------
# KOMPOSISI: legenda | A | (B dan C). Baris bawah diberi porsi tinggi terbesar.
# -----------------------------------------------------------------------------
# panel A hanya memakai separuh lebar (diapit ruang kosong) agar proporsinya
# mendekati persegi panjang biasa, bukan strip lebar yang membuat garis tampak datar
baris_a <- (plot_spacer() | p_a | plot_spacer()) +
  plot_layout(widths = c(1, 2, 1))

grafik_6 <- (p_leg / baris_a / (p_b | p_c)) +
  # strip legenda diberi tinggi tetap 1 cm (bukan relatif) agar teksnya tidak terpotong
  plot_layout(heights = unit(c(1, 1.7, 3), c("cm", "null", "null"))) +
  plot_annotation(
    title    = judul_6,
    subtitle = subjudul_6,
    caption  = caption_6,
    theme    = theme(
      plot.title    = element_text(face = "bold", size = 18, color = pal_tim[["judul"]],
                                   margin = margin(b = 6)),
      plot.subtitle = element_text(size = 11, color = pal_tim[["teks"]],
                                   margin = margin(b = 18)),
      plot.caption  = element_text(size = 9, color = pal_tim[["teks"]], hjust = 0)
    )
  )

print(grafik_6)

# =============================================================================
# SIMPAN SEMUA GRAFIK SEBAGAI PNG
# Tempel di PALING AKHIR galeri_grafik.R (setelah print(grafik_6)).
# Hasil: keluaran/galeri/grafik_1_boxplot.png ... grafik_6_komposisi.png
# Folder kerja harus folder utama repositori (getwd()).
# =============================================================================
folder_keluaran <- file.path("keluaran", "galeri")
dir.create(folder_keluaran, recursive = TRUE, showWarnings = FALSE)

# lebar dan tinggi dalam inci; grafik_6 memakai lebar_kanvas agar legenda gabungan pas
ukuran <- data.frame(
  objek  = c("grafik_1", "grafik_2", "grafik_3", "grafik_4", "grafik_5", "grafik_6"),
  berkas = c("grafik_1_boxplot", "grafik_2_small_multiples", "grafik_3_scatterplot",
             "grafik_4_titik_diurutkan", "grafik_5_dumbbell", "grafik_6_komposisi"),
  lebar  = c(9, 14, 11, 8, 8, lebar_kanvas),
  tinggi = c(6, 9, 6.5, 8, 8.5, 18),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(ukuran))) {
  if (!exists(ukuran$objek[i])) {
    warning("Objek ", ukuran$objek[i], " tidak ditemukan, dilewati.")
    next
  }
  jalur <- file.path(folder_keluaran, paste0(ukuran$berkas[i], ".png"))
  ggsave(jalur, plot = get(ukuran$objek[i]),
         width = ukuran$lebar[i], height = ukuran$tinggi[i],
         dpi = 200, bg = "white")
  cat("Tersimpan:", normalizePath(jalur, winslash = "/"), "\n")
}

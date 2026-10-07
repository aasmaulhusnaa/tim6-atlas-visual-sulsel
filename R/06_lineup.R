# R/lineup.R
# =============================================================================
# Lineup protocol (inferensi visual) untuk hubungan TPT dan RLS
#
# Hipotesis nol (H0): TPT dan RLS tidak berhubungan antarwilayah.
# Cara kerja: 1 panel memuat data asli (scatterplot TPT vs RLS, 24 wilayah),
# 19 panel lain memuat data nol, yaitu RLS diacak (permutasi) antarwilayah
# sehingga hubungan apa pun dengan TPT hilang. Pengamat diminta memilih panel
# yang paling berbeda. Kalau banyak pengamat memilih panel asli, hubungan itu
# nyata secara visual.

# Data : data-bersih/data_bersih.rds (kolom yang dipakai: kode_wilayah, tahun, tpt, rls)
# Paket: ggplot2, nullabor
#   install.packages("nullabor")
# =============================================================================

# -----------------------------------------------------------------------------
# 0. PENGATURAN
# -----------------------------------------------------------------------------
tahun_uji   <- 2025    # tahun data yang diuji
seed_lineup <- 2026    # supaya lineup bisa dibuat ulang persis sama
n_panel     <- 20      # 1 data asli + 19 data nol
posisi_tetap <- NULL   # NULL = diacak di antara panel 2-20; atau isi angka 2-20


dir_salinan <- NULL    # tidak membuat salinan

# Buka folder gambar di File Explorer setelah disimpan? (TRUE / FALSE)
buka_folder <- FALSE

# mengatuh ukuran dan resolusi gambar 20 panel lineup
lebar_gambar  <- 14
tinggi_gambar <- 7.5
resolusi      <- 300    # dpi; 14 inci x 300 dpi = 4200 piksel lebar

# -----------------------------------------------------------------------------
# 1. PAKET, TEMA TIM, DAN DATA
# -----------------------------------------------------------------------------
for (p in c("ggplot2", "nullabor")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Paket '", p, "' belum terpasang. Jalankan: install.packages('", p, "')")
  }
}
library(ggplot2)
library(nullabor)

# Folder utama repositori (`dir_repo`) dicari otomatis: mulai dari folder kerja R,
# naik ke folder induk sampai ketemu folder yang memuat berkas .Rproj, folder
# .git, atau folder data-bersih. Tidak ada path laptop pribadi di kode ini,
# jadi skrip sama persis bisa dipakai di laptop siapa pun.
cari_dir_repo <- function(mulai = getwd()) {
  d <- normalizePath(mulai, winslash = "/", mustWork = FALSE)
  repeat {
    if (length(list.files(d, pattern = "\\.Rproj$")) > 0 ||
        dir.exists(file.path(d, ".git")) ||
        dir.exists(file.path(d, "data-bersih"))) return(d)
    induk <- dirname(d)
    if (identical(induk, d)) return(NA_character_)   # sudah di puncak, tidak ketemu
    d <- induk
  }
}
# Cadangan: lokasi skrip ini sendiri. Kalau folder kerja R di luar repositori
# (mis. Documents) tetapi skrip disimpan di dalam repositori, dir_repo tetap ketemu.
lokasi_skrip <- function() {
  of <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)      # lewat source()
  if (!is.null(of) && nzchar(of)) {
    return(normalizePath(dirname(of), winslash = "/", mustWork = FALSE))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
    if (!is.null(p) && nzchar(p)) {                                  # dokumen aktif di RStudio
      return(normalizePath(dirname(p), winslash = "/", mustWork = FALSE))
    }
  }
  NA_character_
}
dir_repo <- cari_dir_repo()
if (is.na(dir_repo)) {
  ls_skrip <- lokasi_skrip()
  if (!is.na(ls_skrip)) dir_repo <- cari_dir_repo(ls_skrip)
}
if (is.na(dir_repo)) {
  stop("Folder repositori tidak ditemukan dari folder kerja R maupun dari lokasi skrip ini.",
       "\nPastikan skrip ini disimpan di dalam folder repositori, lalu buka repositori sebagai",
       "\nRStudio Project (File > New Project > Existing Directory),",
       "\natau pindahkan folder kerja ke dalam repositori dengan setwd().", call. = FALSE)
}
# jalur ditampilkan relatif terhadap repositori, bukan jalur laptop
rel <- function(p) substring(p, nchar(dir_repo) + 2)
cat("Repositori:", basename(dir_repo), "\n")

# cari file tema dan data di dalam folder proyek (nama tidak harus persis)
cari_berkas <- function(pola, nama) {
  hasil <- list.files(dir_repo, pattern = pola, recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
  if (length(hasil) == 0) {
    stop("File ", nama, " tidak ditemukan di folder repositori: ", basename(dir_repo))
  }
  hasil[1]
}

berkas_tema <- cari_berkas("theme_tim.*\\.R(\\.txt)?$", "tema (theme_tim)")
berkas_data <- cari_berkas("data_bersih.*\\.rds$",      "data (data_bersih.rds)")
cat("Tema :", rel(berkas_tema), "\nData :", rel(berkas_data), "\n")

source(berkas_tema)
theme_set(theme_tim())

d <- readRDS(berkas_data)
if (!is.data.frame(d)) {
  stop("Isi data_bersih.rds bukan data frame (kelasnya: ", paste(class(d), collapse = ", "), ").")
}
# Membuang kolom geometri
d <- as.data.frame(d)
d <- d[, !vapply(d, function(k) inherits(k, "sfc"), logical(1)), drop = FALSE]
cat("\nKolom di data_bersih.rds:", paste(names(d), collapse = ", "), "\n")

hilang <- setdiff(c("kode_wilayah", "tahun", "tpt", "rls"), names(d))
if (length(hilang) > 0) {
  stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "),
       "\nKolom yang ada: ", paste(names(d), collapse = ", "),
       "\nUbah nama kolom di skrip ini sesuai nama kolom di data Anda.")
}
d$tahun <- as.integer(d$tahun)
d$tpt   <- as.numeric(d$tpt)
d$rls   <- as.numeric(d$rls)

# jenis wilayah: kode 7371-7373 (Makassar, Parepare, Palopo) = Kota
# (di data_bersih.rds kode_wilayah bertipe teks, jadi diubah ke angka dulu)
d$jenis <- factor(ifelse(as.integer(d$kode_wilayah) >= 7371, "Kota", "Kabupaten"),
                  levels = c("Kabupaten", "Kota"))

# data yang diuji: satu tahun; kolom tpt, rls, dan jenis wilayah
# (hanya rls yang diacak; jenis wilayah tetap menempel pada tpt-nya)
d_uji <- d[d$tahun == tahun_uji, c("tpt", "rls", "jenis")]
d_uji <- d_uji[complete.cases(d_uji), ]

# -----------------------------------------------------------------------------
# 2. BUAT LINEUP: 1 data asli + 19 data RLS yang diacak
# -----------------------------------------------------------------------------
set.seed(seed_lineup)
# nomor panel yang memuat data asli
posisi_asli <- if (is.null(posisi_tetap)) sample(2:n_panel, 1) else posisi_tetap
stopifnot(posisi_asli %in% 2:n_panel)

# suppressMessages: pesan decrypt(...) dari nullabor memuat kode terenkripsi
# posisi panel asli, jadi tidak ditampilkan di Console supaya tidak bocor
# lewat tangkapan layar. Kuncinya disimpan terpisah di kunci_lineup.txt.
lp <- suppressMessages(
  lineup(null_permute("rls"), d_uji, n = n_panel, pos = posisi_asli)
)

# -----------------------------------------------------------------------------
# 3. PENGECEKAN (tidak mencetak apa pun kalau lolos)
# -----------------------------------------------------------------------------
stopifnot(
  nrow(d_uji) == 24,                                    # 24 kabupaten/kota
  length(unique(lp$.sample)) == n_panel,                # 20 panel
  nrow(lp) == n_panel * nrow(d_uji),                    # 20 x 24 = 480 baris
  posisi_asli %in% seq_len(n_panel),
  isTRUE(all.equal(sort(lp$rls[lp$.sample == posisi_asli]), sort(d_uji$rls))),
  isTRUE(all.equal(sort(lp$tpt[lp$.sample == posisi_asli]), sort(d_uji$tpt)))
)

# -----------------------------------------------------------------------------
# 4. GAMBAR LINEUP
#    Semua panel bergaya sama (seperti grafik 3): titik berwarna dan berbentuk
#    menurut jenis wilayah, ditambah garis regresi linear dan pita kepercayaan
#    95% berwarna garis_utama di SETIAP panel, tanpa sorotan yang membedakan
#    satu panel. Angka sumbu disembunyikan (standar lineup).
#    Catatan: karena garis dan pita ikut digambar, yang dibandingkan pengamat
#    adalah pola keseluruhan termasuk kemiringan garis; tulis ini di atlas.
# -----------------------------------------------------------------------------
g_lineup <- ggplot(lp, aes(x = rls, y = tpt)) +
  # garis regresi dan pita kepercayaan 95% (dihitung terpisah di tiap panel)
  geom_smooth(method = "lm", formula = y ~ x, level = 0.95,
              color = pal_tim[["garis_utama"]], fill = pal_tim[["garis_utama"]],
              alpha = 0.2, linewidth = 0.9) +
  geom_point(aes(fill = jenis, shape = jenis), size = 2.8, stroke = 0.6,
             color = pal_tim[["tepi"]]) +
  scale_fill_jenis() +
  scale_shape_jenis() +
  facet_wrap(~ .sample, nrow = 4) +
  labs(
    title    = "Manakah panel yang paling berbeda dari yang lain?",
    subtitle = "Dari 20 panel ini, satu memuat data asli. Pilih nomor panel yang menurut Anda paling berbeda.",
    x        = "RLS",
    y        = "TPT"
  ) +
  theme_tim(grid = "xy") +
  theme(
    axis.text    = element_blank(),
    axis.ticks   = element_blank(),
    strip.text   = element_text(face = "bold", hjust = 0.5, size = 11),
    # bingkai tiap panel dan nomornya, supaya batas antarpanel jelas
    panel.border     = element_rect(fill = NA, color = pal_tim[["tepi"]], linewidth = 0.5),
    strip.background = element_rect(fill = NA, color = pal_tim[["tepi"]], linewidth = 0.5),
    panel.spacing    = grid::unit(1, "lines")
  )

print(g_lineup)

# -----------------------------------------------------------------------------
# 5. SIMPAN GAMBAR DAN KUNCI JAWABAN
# -----------------------------------------------------------------------------
dir.create(file.path(dir_repo, "keluaran", "lineup"), recursive = TRUE, showWarnings = FALSE)
berkas_gambar <- file.path(dir_repo, "keluaran", "lineup", "lineup_tpt_rls.png")
ggsave(berkas_gambar, g_lineup, width = lebar_gambar, height = tinggi_gambar,
       dpi = resolusi, bg = "white")

# --- salinan gambar ke folder pilihan di laptop ---
if (!is.null(dir_salinan)) {
  if (identical(dir_salinan, "pilih")) {
    dir_salinan <- NULL
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      dir_salinan <- rstudioapi::selectDirectory(
        caption = "Pilih folder untuk menyimpan gambar lineup")
    } else if (.Platform$OS.type == "windows") {
      dir_salinan <- utils::choose.dir(caption = "Pilih folder untuk menyimpan gambar lineup")
    }
  }
  if (!is.null(dir_salinan) && !is.na(dir_salinan) && nzchar(dir_salinan)) {
    dir.create(dir_salinan, recursive = TRUE, showWarnings = FALSE)
    berkas_salinan <- file.path(dir_salinan, basename(berkas_gambar))
    if (file.copy(berkas_gambar, berkas_salinan, overwrite = TRUE)) {
      message("Salinan gambar tersimpan di: ", berkas_salinan)
    } else {
      warning("Salinan gambar gagal dibuat di: ", dir_salinan)
    }
  } else {
    message("Tidak ada folder yang dipilih; salinan gambar tidak dibuat.")
  }
}

berkas_kunci <- file.path(dir_repo, "kunci_lineup.txt")   # di folder proyek, bukan di keluaran/
writeLines(c(
  paste("panel_asli :", posisi_asli),
  paste("tahun      :", tahun_uji),
  paste("set.seed   :", seed_lineup),
  paste("dibuat     :", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
), berkas_kunci)

message("Gambar lineup tersimpan: ", rel(berkas_gambar))
message("Lokasi lengkap di laptop: ", normalizePath(berkas_gambar, winslash = "/", mustWork = FALSE))
message("Kunci jawaban tersimpan di: ", rel(berkas_kunci),
        " (jangan dibagikan ke pengamat)")

if (isTRUE(buka_folder) && interactive()) {
  utils::browseURL(dirname(berkas_gambar))   # membuka folder gambar di File Explorer
}
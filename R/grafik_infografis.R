# gambar_tanpa_teks.R
# =============================================================================
# Membuat versi SEMUA grafik tanpa judul, subjudul, caption (sumber dan tulisan di
# bawah grafik). Cocok untuk grafik yang keterangannya ditulis di atlas (Quarto),
# infografis, atau dokumen lain.
#
# Grafik yang diproses (dibuat oleh tiga skrip tim):
#   04_galeri_grafik.R        grafik_1 ... grafik_6
#   07_peta_korpolet.R        peta_tpt_2025, uji_peta (uji buta warna)
#   09_grafik_sk_bootstrap.R  grafik_sk1, grafik_sk2
#
# Khusus peta_tpt_2025: dibuat ulang tanpa judul/subjudul/caption dan label wilayah
# hanya berisi nama (tanpa angka dalam kurung).
#
# Cara kerja: tiap skrip dijalankan dulu bila objek grafiknya belum ada di sesi R ini
# (tampilan layarnya disembunyikan), lalu setiap grafik dipasangi labs(title = NULL,
# subtitle = NULL, caption = NULL) dan disimpan sebagai PNG baru. Gambar asli
# (berjudul) TIDAK ditimpa. Hasil: keluaran/tanpa_teks/<nama>_tanpa_teks.png
#
# CARA MENJALANKAN: buka repositori lewat file .Rproj, Session > Restart R, lalu
# jalankan seluruh skrip ini (Source).
# =============================================================================

# -----------------------------------------------------------------------------
# 0. PENGATURAN
# -----------------------------------------------------------------------------
# Grafik gabungan (grafik_6 dan uji buta warna) punya judul pada tiap panel
# (mis. "A. TPT dan RLS", "Deuteranopia (simulasi)"). FALSE = judul panel tetap ada
# supaya panel bisa dikenali; TRUE = judul panel ikut dihapus.
hapus_judul_panel <- FALSE

tampilkan_hasil <- TRUE      # TRUE = tampilkan tiap grafik baru di panel Plots

# Ukuran huruf dan lebar gambar (berlaku untuk SEMUA grafik)
ukuran_dasar <- 13           # ukuran huruf dasar tema (bawaan tema tim = 11)
faktor_lebar <- 1.2          # pengali lebar gambar (1 = ukuran semula)
paksa_ulang  <- TRUE         # TRUE = semua grafik dibuat ulang agar ukuran huruf baru terpakai
# Ukuran untuk infografis: ukuran bingkai grafik di kanvas A4 (210 x 297 mm), dalam mm
# (hasil pengukuran dari rancangan infografis; ubah di sini bila bingkai diubah)
font_infografis <- 9         # ukuran huruf dasar yang diinginkan pada halaman A4
bingkai <- data.frame(
  objek     = c("peta_tpt_2025", "grafik_sk1",       "grafik_3"),
  berkas    = c("peta_tpt_2025", "sk_tpt_swp_rata2", "grafik_3_scatterplot"),
  lebar_mm  = c(119, 132, 118),
  tinggi_mm = c( 78,  71,  67),
  stringsAsFactors = FALSE
)
tahun_scatter <- 2025        # tahun pada label sumbu x scatterplot: "Rata-rata Lama Sekolah (2025)"

# =============================================================================
# A. PENGATURAN JALUR
# =============================================================================
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

# =============================================================================
# B. PAKET
# =============================================================================
for (p in c("ggplot2", "patchwork")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Paket '", p, "' belum terpasang. Jalankan: install.packages('", p, "')",
         call. = FALSE)
  }
}
library(ggplot2)

# =============================================================================
# C. FUNGSI: hapus judul, subjudul, dan caption
# =============================================================================
#' @param g objek ggplot atau patchwork
#' @param hapus_judul_panel hanya untuk patchwork: TRUE = judul tiap panel ikut dihapus
tanpa_teks <- function(g, hapus_judul_panel = FALSE) {
  kosong <- ggplot2::labs(title = NULL, subtitle = NULL, caption = NULL)
  if (inherits(g, "patchwork")) {
    # judul, subjudul, caption keseluruhan komposisi (plot_annotation)
    g <- g + patchwork::plot_annotation(title = NULL, subtitle = NULL, caption = NULL)
    # judul tiap panel (opsional); & menerapkan ke semua panel
    if (hapus_judul_panel) g <- g & kosong
    g
  } else {
    g + kosong
  }
}

# =============================================================================
# D. MUAT GRAFIK DARI TIGA SKRIP (bila belum ada di sesi ini)
# =============================================================================
cari_skrip <- function(pola, nama) {
  hasil <- list.files(dir_repo, pattern = pola, recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
  hasil <- hasil[!grepl("/\\.Rproj\\.user/", hasil)]
  if (length(hasil) == 0) {
    semua <- list.files(dir_repo, pattern = "\\.R$", recursive = TRUE, ignore.case = TRUE)
    stop("Skrip ", nama, " tidak ditemukan di dalam repositori.\n",
         "Berkas .R yang terlihat:\n", paste0("  - ", semua, collapse = "\n"),
         call. = FALSE)
  }
  hasil[order(file.mtime(hasil), decreasing = TRUE)][1]
}

daftar_skrip <- list(
  list(nama = "galeri grafik",  pola = "^04_galeri_grafik\\.R$",
       objek = paste0("grafik_", 1:6)),
  list(nama = "peta koroplet",  pola = "^07_peta_kor.*\\.R$",
       objek = c("peta_tpt_2025", "uji_peta")),
  list(nama = "SK bootstrap",   pola = "^09_grafik_sk_boot.*\\.R$",
       objek = c("grafik_sk1", "grafik_sk2"))
)

# ukuran huruf dasar dibaca theme_tim() lewat opsi tim.base_size
# (butuh versi theme_tim di 03_theme_tim.R yang membaca opsi ini)
options(tim.base_size = ukuran_dasar)
if (paksa_ulang) {
  rm(list = intersect(unlist(lapply(daftar_skrip, `[[`, "objek")), ls(globalenv())),
     envir = globalenv())
}

for (s in daftar_skrip) {
  sudah_ada <- all(vapply(s$objek, exists, logical(1)))
  if (sudah_ada) {
    message("[", s$nama, "] objek sudah ada di sesi ini, skrip tidak dijalankan ulang.")
    next
  }
  berkas <- cari_skrip(s$pola, s$nama)
  message("[", s$nama, "] menjalankan ", rel(berkas), " ...")
  grDevices::pdf(NULL)                              # tampilan layar skrip asli disembunyikan
  dev_null <- grDevices::dev.cur()
  ok <- tryCatch({ source(berkas); TRUE },
                 error = function(e) {
                   message("GAGAL menjalankan ", basename(berkas), ": ", conditionMessage(e))
                   FALSE
                 })
  try(grDevices::dev.off(dev_null), silent = TRUE)
  if (!ok) stop("Berhenti: perbaiki galat di ", basename(berkas), " lalu jalankan ulang.",
                call. = FALSE)
}

# jalur dan fungsi bantu milik skrip-skrip tadi bisa menimpa milik kita: pulihkan
dir_repo <- cari_dir_repo(dir_repo)
rel <- function(p) substring(p, nchar(dir_repo) + 2)

# -----------------------------------------------------------------------------
# Peta koroplet versi tanpa teks (TPT 2025, 5 kelas kuantil, legenda di kanan,
# label bergaris untuk wilayah tertinggi dan terendah, palet Blues): tanpa judul,
# subjudul, caption, dan tanpa angka pada label (hanya "Makassar" dan "Enrekang").
# Angka dibuang langsung dari lapisan label di objek grafik, jadi cara ini jalan
# dengan plot_peta() versi lama maupun baru.
# -----------------------------------------------------------------------------
if (!exists("plot_peta")) {
  stop("Fungsi plot_peta() tidak ada. Session > Restart R, lalu jalankan ulang skrip ini.",
       call. = FALSE)
}

# Data peta dibaca ulang dari berkas. Objek `d` di sesi tidak dipakai karena skrip
# lain (mis. SK bootstrap) bisa menimpanya dengan data tanpa geometri.
berkas_peta <- file.path(dir_repo, c("data-bersih/data_bersih.rds",
                                     "data/data-bersih/data_bersih.rds"))
berkas_peta <- berkas_peta[file.exists(berkas_peta)][1]
if (is.na(berkas_peta)) stop("data_bersih.rds tidak ditemukan.", call. = FALSE)
d_peta <- readRDS(berkas_peta)
if (!inherits(d_peta, "sf")) {
  stop("data_bersih.rds bukan objek sf (tidak memuat geometri peta).", call. = FALSE)
}

# "Makassar (9,60)" -> "Makassar" pada semua lapisan label (geom_label)
hapus_angka_label <- function(g) {
  for (i in seq_along(g$layers)) {
    if (inherits(g$layers[[i]]$geom, "GeomLabel")) {
      dt <- g$layers[[i]]$data
      if (is.data.frame(dt) && "teks" %in% names(dt)) {
        dt$teks <- sub("\\s*\\(.*\\)\\s*$", "", dt$teks)
        g$layers[[i]]$data <- dt
      }
    }
  }
  g
}

peta_tpt_2025 <- plot_peta(d_peta, indikator = tpt, tahun = 2025,
                           judul = NA, subjudul = NA, caption = NA)
peta_tpt_2025 <- hapus_angka_label(peta_tpt_2025)

# Scatterplot (grafik_3): label sumbu x "(tahun)" diganti tahun datanya, "(2025)"
if (exists("grafik_3")) {
  grafik_3 <- grafik_3 +
    labs(x = sub("(tahun)", paste0("(", tahun_scatter, ")"), lab_rls, fixed = TRUE))
}

# =============================================================================
# E. BUAT VERSI TANPA TEKS DAN SIMPAN
# =============================================================================
lebar_kanvas_6 <- if (exists("lebar_kanvas")) lebar_kanvas else 14

# nama objek, nama berkas dasar, lebar (inci), tinggi (inci), dpi
# (ukuran dan dpi sama dengan penyimpanan di skrip asli)
tabel <- data.frame(
  objek  = c(paste0("grafik_", 1:6), "peta_tpt_2025", "uji_peta", "grafik_sk1", "grafik_sk2"),
  berkas = c("grafik_1_boxplot", "grafik_2_small_multiples", "grafik_3_scatterplot",
             "grafik_4_titik_diurutkan", "grafik_5_dumbbell", "grafik_6_komposisi",
             "peta_tpt_2025", "uji_buta_warna_peta_tpt_2025",
             "sk_tpt_swp_rata2", "sk_tpt_swp_per_tahun"),
  lebar  = c(9, 14, 11, 8, 8, lebar_kanvas_6, 9, 15, 9, 13) * faktor_lebar,
  tinggi = c(6, 9, 6.5, 8, 8.5, 18, 8, 6.5, 5.5, 5.5),
  dpi    = c(rep(200, 6), 300, 300, 300, 300),
  stringsAsFactors = FALSE
)

dir_out <- file.path(dir_repo, "keluaran", "tanpa_teks")
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

# ragg (bila terpasang) lebih tahan terhadap galat perangkat grafik
dev_png <- if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else "png"

grafik_tanpa_teks <- list()
status <- character(nrow(tabel))
for (i in seq_len(nrow(tabel))) {
  nama_obj <- tabel$objek[i]
  if (!exists(nama_obj)) {
    status[i] <- "dilewati (objek tidak ada)"
    next
  }
  g <- tanpa_teks(get(nama_obj), hapus_judul_panel = hapus_judul_panel)
  grafik_tanpa_teks[[nama_obj]] <- g
  
  berkas <- file.path(dir_out, paste0(tabel$berkas[i], "_tanpa_teks.png"))
  hasil <- try(ggsave(berkas, g, width = tabel$lebar[i], height = tabel$tinggi[i],
                      dpi = tabel$dpi[i], bg = "white", device = dev_png), silent = TRUE)
  if (inherits(hasil, "try-error")) {
    status[i] <- paste("GAGAL:", conditionMessage(attr(hasil, "condition")))
  } else {
    status[i] <- "tersimpan"
  }
}

cat("\nHasil (folder: ", rel(dir_out), ")\n", sep = "")
print(data.frame(grafik = tabel$objek, berkas = paste0(tabel$berkas, "_tanpa_teks.png"),
                 status = status), row.names = FALSE)

# =============================================================================
# F. VERSI SEUKURAN BINGKAI INFOGRAFIS (peta, SK bootstrap, scatterplot)
# =============================================================================
# Gambar disimpan dengan PERBANDINGAN lebar:tinggi yang sama dengan bingkainya, jadi
# langsung memenuhi bingkai tanpa dipotong atau menyisakan ruang kosong. Kanvas
# digambar lebih besar sebesar ukuran_dasar / font_infografis. Saat gambar
# diperkecil ke ukuran bingkai, huruf dasar menjadi kira-kira font_infografis pt.
faktor_info <- ukuran_dasar / font_infografis
dir_info    <- file.path(dir_out, "infografis")
dir.create(dir_info, recursive = TRUE, showWarnings = FALSE)

status_info <- character(nrow(bingkai))
for (i in seq_len(nrow(bingkai))) {
  g <- grafik_tanpa_teks[[bingkai$objek[i]]]
  if (is.null(g)) { status_info[i] <- "dilewati (objek tidak ada)"; next }
  berkas <- file.path(dir_info, paste0(bingkai$berkas[i], "_infografis.png"))
  hasil <- try(ggsave(berkas, g,
                      width  = bingkai$lebar_mm[i]  / 25.4 * faktor_info,
                      height = bingkai$tinggi_mm[i] / 25.4 * faktor_info,
                      dpi = 300, bg = "white", device = dev_png), silent = TRUE)
  status_info[i] <- if (inherits(hasil, "try-error")) {
    paste("GAGAL:", conditionMessage(attr(hasil, "condition")))
  } else "tersimpan"
}
cat("\nVersi infografis (folder: ", rel(dir_info), ")\n", sep = "")
print(data.frame(grafik = bingkai$objek,
                 bingkai_mm = paste(bingkai$lebar_mm, "x", bingkai$tinggi_mm),
                 status = status_info), row.names = FALSE)

# objek hasil: grafik_tanpa_teks$grafik_1, grafik_tanpa_teks$peta_tpt_2025, dst.
if (tampilkan_hasil) {
  for (g in grafik_tanpa_teks) print(g)
}
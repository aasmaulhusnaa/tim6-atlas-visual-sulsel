# grafik_bootstrap.R
# =============================================================================
# Pekerjaan A (Hari 10-11): grafik SK bootstrap TPT per kelompok wilayah (5 SWP BPS)
#
# Skrip MANDIRI: tidak perlu file fungsi lain. Cukup tema tim dan data_bersih.rds
# yang dicari otomatis di dalam repositori.
#
# Isi:
#   sk_boot()           SK bootstrap persentil 95% untuk satu kelompok (B >= 1.999)
#   hitung_sk()         bootstrap per kelompok; fungsi dengan {{ }} (nama kolom polos)
#   gambar_sk()         titik + garis galat, diurutkan dari estimasi tertinggi
#   plot_sk_bootstrap() jalan pintas: data -> grafik dalam satu panggilan
#
# Objek hasil hitung_sk() (isi yang dipakai autoplot() oleh Wafiq):
#   $hasil          tabel: kelompok, est, bawah, atas, n (+ tahun bila per_tahun = TRUE)
#   $indikator      nama kolom indikator, mis. "tpt"
#   $B              jumlah resample
#   $per_tahun      FALSE = Pilihan 1 (rata-rata semua tahun), TRUE = Pilihan 2
#   $rentang_tahun  tahun terkecil dan terbesar di data
#   $seed           bilangan acak awal
#
# Paket  : ggplot2, dplyr, rlang
# CARA MENJALANKAN: buka repositori lewat file .Rproj, lalu jalankan seluruh skrip.
# =============================================================================

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
# B. PAKET, TEMA, DAN DATA
# =============================================================================
for (p in c("ggplot2", "dplyr", "rlang")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Paket '", p, "' belum terpasang. Jalankan: install.packages('", p, "')",
         call. = FALSE)
  }
}
library(ggplot2)

# Mencari berkas di dalam repositori (semua subfolder); bila ada beberapa
# kandidat dipakai yang paling baru diubah.
cari_berkas <- function(pola, nama) {
  hasil <- list.files(dir_repo, pattern = pola, recursive = TRUE,
                      full.names = TRUE, ignore.case = TRUE)
  if (length(hasil) == 0) {
    semua <- list.files(dir_repo, pattern = "\\.(R|rds)$", recursive = TRUE, ignore.case = TRUE)
    stop("Berkas ", nama, " tidak ditemukan di dalam repositori.\n",
         "Berkas .R dan .rds yang terlihat:\n", paste0("  - ", semua, collapse = "\n"),
         call. = FALSE)
  }
  hasil <- hasil[order(file.mtime(hasil), decreasing = TRUE)]
  if (length(hasil) > 1) {
    message("Ada lebih dari satu kandidat untuk ", nama, ", dipakai yang terbaru:\n",
            paste0("  - ", rel(hasil), collapse = "\n"))
  }
  hasil[1]
}

source(cari_berkas("theme_tim.*\\.R(\\.txt)?$", "tema (theme_tim)"))

berkas_data <- cari_berkas("^data_bersih.*\\.rds$", "data_bersih.rds")
d <- as.data.frame(readRDS(berkas_data))
d <- d[, !vapply(d, function(k) inherits(k, "sfc"), logical(1)), drop = FALSE]  # buang geometri peta
d$tahun <- as.integer(d$tahun)
cat("Data:", rel(berkas_data), "|", nrow(d), "baris |", length(unique(d$kabupaten)),
    "kabupaten/kota |", paste(sort(unique(d$tahun)), collapse = ", "), "\n")

# =============================================================================
# C. PEMETAAN 5 SWP BPS SULAWESI SELATAN
# =============================================================================
# Ejaan nama HARUS sama dengan kolom kabupaten di data_bersih.rds
swp <- list(
  "Mamminasata"          = c("Makassar", "Maros", "Gowa", "Takalar"),
  "Ajatappareng"         = c("Parepare", "Sindereng Rappang", "Pinrang", "Barru",
                             "Enrekang", "Pangkajene dan Kepulauan"),
  "Bosowa"               = c("Bone", "Soppeng", "Wajo"),
  "Selatan-Selatan"      = c("Kepulauan Selayar", "Bulukumba", "Bantaeng",
                             "Jeneponto", "Sinjai"),
  "Luwu Raya dan Toraja" = c("Palopo", "Luwu", "Luwu Utara", "Luwu Timur",
                             "Tana Toraja", "Toraja Utara")
)
peta_swp <- data.frame(kabupaten = unlist(swp, use.names = FALSE),
                       kelompok  = rep(names(swp), lengths(swp)))

# pemeriksaan: 24 wilayah, tanpa duplikat, ejaan sama dengan data
stopifnot(nrow(peta_swp) == 24, !anyDuplicated(peta_swp$kabupaten))
tdk_cocok <- setdiff(unique(d$kabupaten), peta_swp$kabupaten)
if (length(tdk_cocok) > 0) {
  stop("Nama di data tetapi tidak ada di pemetaan SWP: ", paste(tdk_cocok, collapse = ", "),
       call. = FALSE)
}
d_sk <- merge(d, peta_swp, by = "kabupaten", all.x = TRUE)
stopifnot(!anyNA(d_sk$kelompok))
cat("\nJumlah kabupaten/kota per kelompok:\n"); print(table(peta_swp$kelompok))

# =============================================================================
# D. FUNGSI
# =============================================================================
# format angka dengan koma desimal
koma_sk <- function(x, d = 2) format(round(x, d), nsmall = d, decimal.mark = ",")

# label sumbu: tpt dan rls memakai label tim
label_sk <- function(nama) {
  acuan <- c(tpt = lab_tpt, rls = lab_rls)
  if (nama %in% names(acuan)) acuan[[nama]] else nama
}

# -----------------------------------------------------------------------------
# sk_boot(): SK bootstrap persentil 95% untuk rata-rata satu kelompok
#   x : nilai per unit (satu nilai per kabupaten/kota)
#   B : jumlah resample (minimal 1.999 sesuai lembar tugas)
# Persentil memakai quantile(type = 6): dengan B = 1.999, persentil 2,5% dan
# 97,5% jatuh tepat pada nilai urut ke-50 dan ke-1.950, tanpa interpolasi.
# -----------------------------------------------------------------------------
sk_boot <- function(x, B = 1999) {
  x <- x[!is.na(x)]
  if (length(x) < 2) stop("Bootstrap butuh minimal 2 unit per kelompok.", call. = FALSE)
  if (B < 1999) stop("B minimal 1999 (ketentuan lembar tugas).", call. = FALSE)
  rata  <- replicate(B, mean(sample(x, length(x), replace = TRUE)))
  batas <- stats::quantile(rata, probs = c(0.025, 0.975), type = 6, names = FALSE)
  data.frame(est = mean(x), bawah = batas[1], atas = batas[2], n = length(x))
}

# -----------------------------------------------------------------------------
# gambar_sk(): menggambar tabel hasil SK (titik + garis galat, diurutkan)
# Dipakai oleh plot_sk() dan autoplot.sk_wilayah(), jadi keduanya selalu
# menghasilkan grafik yang sama.
# -----------------------------------------------------------------------------
gambar_sk <- function(hasil, indikator, B, per_tahun = FALSE, rentang_tahun = NULL) {
  d <- as.data.frame(hasil)
  d$label <- paste0(d$kelompok, " (n = ", d$n, ")")
  
  # urutan kelompok: dari rata-rata estimasi, sama di semua panel; tertinggi di atas
  rata_label <- tapply(d$est, d$label, mean)
  d$label <- factor(d$label, levels = names(sort(rata_label)))
  
  # judul 
  rata_kel <- tapply(d$est, d$kelompok, mean)
  kel_max  <- names(which.max(rata_kel))
  kel_min  <- names(which.min(rata_kel))
  singkat  <- if (indikator %in% c("tpt", "rls")) toupper(indikator) else indikator
  # judul dan subjudul masing-masing SATU baris (tanpa pemenggalan)
  judul <- paste0(singkat, " tertinggi di ", kel_max, " (", koma_sk(max(rata_kel)),
                  "), terendah di ", kel_min, " (", koma_sk(min(rata_kel)), ")")
  
  # subjudul: berapa pasang kelompok bersebelahan yang SK-nya tumpang tindih
  subjudul <- NULL
  if (!per_tahun && nrow(d) > 1) {
    o <- d[order(d$est), ]
    tumpang <- sum(o$atas[-nrow(o)] >= o$bawah[-1])
    subjudul <- if (tumpang == 0) {
      "Tidak ada pasangan kelompok bersebelahan yang SK-nya tumpang tindih."
    } else {
      paste0(tumpang, " dari ", nrow(o) - 1,
             " pasang kelompok bersebelahan: SK tumpang tindih, peringkat belum pasti.")
    }
  }
  
  teks_x <- if (per_tahun || is.null(rentang_tahun)) {
    label_sk(indikator)
  } else {
    paste0(label_sk(indikator), ", rata-rata ", rentang_tahun[1], "-", rentang_tahun[2])
  }
  caption <- paste0(
    "Titik = rata-rata; garis = SK bootstrap persentil 95% (B = ",
    format(B, big.mark = ".", decimal.mark = ","), "; unit resample: kabupaten/kota).\n",
    if (any(d$n < 5)) "Kelompok dengan n kecil (n < 5): SK bersifat indikatif.\n" else "",
    "Sumber: BPS, diolah Tim 6.")
  
  g <- ggplot2::ggplot(d, ggplot2::aes(x = est, y = label)) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = bawah, xmax = atas), orientation = "y",
                            color = pal_tim[["garis_utama"]], linewidth = 0.9) +
    ggplot2::geom_point(color = pal_tim[["garis_utama"]], size = 3) +
    ggplot2::labs(title = judul, subtitle = subjudul, x = teks_x, y = NULL,
                  caption = caption) +
    theme_tim(grid = "x") +
    # judul sedikit lebih kecil agar muat satu baris (warna dan tebal tetap dari tema)
    ggplot2::theme(plot.title = ggplot2::element_text(size = 14))
  if (per_tahun) g <- g + ggplot2::facet_wrap(~ tahun, nrow = 1)
  g
}

# -----------------------------------------------------------------------------
# hitung_sk(): bootstrap SK 95% per kelompok wilayah. Unit resample = kabupaten/kota.
#   data       data frame: kabupaten, kelompok, tahun, dan kolom indikator
#   indikator  NAMA KOLOM tanpa tanda kutip, mis. indikator = tpt
#   B          jumlah resample (minimal 1999)
#   per_tahun  FALSE (Pilihan 1): tiap kabupaten diringkas jadi rata-rata semua
#                      tahun, lalu di-bootstrap per kelompok
#              TRUE  (Pilihan 2): bootstrap terpisah untuk tiap tahun
#   seed       bilangan acak awal supaya hasil dapat direproduksi
# Hasil: daftar (lihat daftar isi objek di bagian atas berkas ini)
# -----------------------------------------------------------------------------
hitung_sk <- function(data, indikator, B = 1999, per_tahun = FALSE, seed = 2026) {
  nama <- rlang::as_label(rlang::enquo(indikator))
  
  data <- as.data.frame(data)
  data <- data[, !vapply(data, function(k) inherits(k, "sfc"), logical(1)), drop = FALSE]
  hilang <- setdiff(c("kabupaten", "kelompok", "tahun", nama), names(data))
  if (length(hilang) > 0) {
    stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "), call. = FALSE)
  }
  if (anyNA(data$kelompok)) {
    stop("Ada kabupaten tanpa kelompok. Periksa ejaan nama pada pemetaan SWP.", call. = FALSE)
  }
  
  set.seed(seed)
  if (per_tahun) {
    hasil <- data |>
      dplyr::group_by(tahun, kelompok) |>
      dplyr::reframe(sk_boot({{ indikator }}, B))
  } else {
    hasil <- data |>
      dplyr::group_by(kabupaten, kelompok) |>
      dplyr::summarise(nilai = mean({{ indikator }}, na.rm = TRUE), .groups = "drop") |>
      dplyr::group_by(kelompok) |>
      dplyr::reframe(sk_boot(nilai, B))
  }
  
  list(hasil = as.data.frame(hasil), indikator = nama, B = B, per_tahun = per_tahun,
       rentang_tahun = range(data$tahun), seed = seed)
}

# menggambar dari objek hasil hitung_sk()
gambar_hasil_sk <- function(sk) {
  gambar_sk(sk$hasil, sk$indikator, sk$B,
            per_tahun = sk$per_tahun, rentang_tahun = sk$rentang_tahun)
}

# -----------------------------------------------------------------------------
# plot_sk_bootstrap(): data -> grafik dalam satu panggilan (nama kolom lewat {{ }})
# -----------------------------------------------------------------------------
plot_sk_bootstrap <- function(data, indikator, B = 1999, per_tahun = FALSE, seed = 2026) {
  gambar_hasil_sk(hitung_sk(data, {{ indikator }}, B = B, per_tahun = per_tahun, seed = seed))
}

# =============================================================================
# E. HITUNG DAN GAMBAR
# =============================================================================
theme_set(theme_tim())

# Pilihan 1 (grafik utama): rata-rata semua tahun per kabupaten, bootstrap per kelompok
sk1 <- hitung_sk(d_sk, tpt)
cat("\nPilihan 1: SK bootstrap 95% TPT per kelompok (B =", sk1$B, ", seed =", sk1$seed, ")\n")
print(sk1$hasil[order(-sk1$hasil$est), ], digits = 3, row.names = FALSE)
grafik_sk1 <- gambar_hasil_sk(sk1)
print(grafik_sk1)

# Pilihan 2 (grafik pendukung): satu panel per tahun
sk2 <- hitung_sk(d_sk, tpt, per_tahun = TRUE)
grafik_sk2 <- gambar_hasil_sk(sk2)
print(grafik_sk2)

#-------------------------------------------------------------------------------
# DEMO
# plot_sk_bootstrap(d_sk, tpt)
# plot_sk_bootstrap(d_sk, rls)
# plot_sk_bootstrap(d_sk, tpt, per_tahun = TRUE)

# =============================================================================
# F. PEMERIKSAAN (tidak mencetak apa pun bila lolos)
# =============================================================================
stopifnot(
  nrow(sk1$hasil) == 5,                              # 5 kelompok SWP
  sk1$B >= 1999,                                     # syarat lembar tugas
  all(sk1$hasil$bawah <= sk1$hasil$est),             # estimasi di dalam SK
  all(sk1$hasil$est   <= sk1$hasil$atas),
  all(sk1$hasil$n == c(table(peta_swp$kelompok))[sk1$hasil$kelompok]),   # n sesuai pemetaan
  isTRUE(all.equal(sk1$hasil, hitung_sk(d_sk, tpt)$hasil)),               # reproducible (seed)
  nrow(sk2$hasil) == 5 * length(unique(d_sk$tahun))  # 5 kelompok x jumlah tahun
)

# =============================================================================
# G. SIMPAN GAMBAR ke keluaran/sk_bootstrap/ (ubah ke FALSE bila tidak ingin menyimpan)
# =============================================================================
simpan_gambar <- TRUE
if (simpan_gambar) {
  dir_sk <- file.path(dir_repo, "keluaran", "sk_bootstrap")
  dir.create(dir_sk, recursive = TRUE, showWarnings = FALSE)
  
  # ragg (bila terpasang) lebih tahan terhadap galat perangkat grafik daripada
  # perangkat png bawaan; kalau belum ada, dipakai "png"
  dev_png <- if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else "png"
  
  # menyimpan satu gambar; bila gagal, tampilkan pesan galat aslinya dan lanjut
  simpan_png <- function(nama_berkas, g, lebar, tinggi) {
    hasil <- try(ggsave(file.path(dir_sk, nama_berkas), g, width = lebar, height = tinggi,
                        dpi = 300, bg = "white", device = dev_png), silent = TRUE)
    if (inherits(hasil, "try-error")) {
      message("GAGAL menyimpan ", nama_berkas, ":\n  ",
              conditionMessage(attr(hasil, "condition")))
      return(invisible(FALSE))
    }
    invisible(TRUE)
  }
  
  ok <- c(simpan_png("sk_tpt_swp_rata2.png",     grafik_sk1,  9, 5.5),
          simpan_png("sk_tpt_swp_per_tahun.png", grafik_sk2, 13, 5.5))
  if (all(ok)) message("Gambar SK tersimpan di: ", rel(dir_sk))
}
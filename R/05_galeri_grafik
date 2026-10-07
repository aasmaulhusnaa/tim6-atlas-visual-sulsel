# =============================================================================
# Ketentuan lembar tugas Hari 7:
#   - Menerima : data, kolom indikator, kolom wilayah (nama kolom via {{ }})
#   - Menghasilkan : satu objek ggplot
#   - Cara pakai   : plot_tren(d, indikator = tpt)
#   - Ganti kolom  : plot_tren(d, indikator = rls)
#   - Syarat data  : semua tahun, dengan kolom tahun
# =============================================================================

library(ggplot2)

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
# PENGATURAN PRIBADI (hanya untuk laptop ini). Bila folder ada, dipakai langsung
# sebagai folder proyek. Ganti menjadi NULL sebelum berkas ini dibagikan ke
# tim / di-push ke GitHub, supaya pencarian otomatis di bawah yang dipakai.
dir_repo_manual <- "C:/Users/ThinkPad E14/Documents/STATISTIK/PROJECT KOMSTAT TIM 6"

dir_repo <- if (!is.null(dir_repo_manual) && dir.exists(dir_repo_manual)) {
  normalizePath(dir_repo_manual, winslash = "/", mustWork = FALSE)
} else {
  cari_dir_repo()
}
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

# Mencari berkas di beberapa lokasi yang mungkin (struktur GitHub dan lokal).
# Kandidat HARUS relatif terhadap dir_repo (bukan jalur lengkap). Bila tidak ada
# di lokasi baku, dicari berdasarkan nama berkas di seluruh subfolder dir_repo.
cari_berkas <- function(kandidat) {
  ada <- kandidat[file.exists(file.path(dir_repo, kandidat))]
  if (length(ada) == 0) {
    nama <- gsub("\\.", "\\\\.", unique(basename(kandidat)))
    cari <- list.files(dir_repo,
                       pattern = paste0("^(", paste(nama, collapse = "|"), ")$"),
                       recursive = TRUE)
    if (length(cari) > 0) {
      message("Tidak ada di lokasi baku; memakai hasil pencarian nama berkas: ", cari[1])
      ada <- cari
    }
  }
  if (length(ada) == 0) {
    stop("Berkas tidak ditemukan. Sudah dicari di (relatif terhadap repositori):\n",
         paste0("  - ", kandidat, collapse = "\n"),
         "\nserta di semua subfolder dengan nama yang sama.",
         call. = FALSE)
  }
  file.path(dir_repo, ada[1])
}

# =============================================================================
# B. MUAT TEMA DAN DATA
# =============================================================================
berkas_tema <- cari_berkas(c("R/03_theme_tim.R",
                             "theme_tim/03_theme_tim.R",
                             "R/theme_tim.R",
                             "theme_tim.R"))
source(berkas_tema)
message("Tema dimuat dari: ", rel(berkas_tema))

berkas_data <- cari_berkas(c("data/data-bersih/data_bersih.rds",
                             "data-bersih/data_bersih.rds",
                             "data/bersih/data_bersih.rds",
                             "data_bersih.rds"))
d <- readRDS(berkas_data)
message("Data dimuat dari: ", rel(berkas_data))
# Kesepakatan nama kolom tim: kabupaten (versi skrip baru memakai kabkota)
if ("kabkota" %in% names(d) && !"kabupaten" %in% names(d)) {
  names(d)[names(d) == "kabkota"] <- "kabupaten"
}
cat("Baris:", nrow(d), "| Kolom:", paste(names(d), collapse = ", "), "\n")
# Harus memuat kode_wilayah, kabupaten, tahun, tpt, rls (dan geometry); 72 baris.

# =============================================================================
# C. FUNGSI GRAFIK TREN
# =============================================================================
# -----------------------------------------------------------------------------
# Pembantu: tambah kolom jenis_wilayah dari kode_wilayah
# (7371 Makassar, 7372 Parepare, 7373 Palopo = Kota; sisanya Kabupaten).
# -----------------------------------------------------------------------------
tambah_jenis_wilayah <- function(data) {
  if ("jenis_wilayah" %in% names(data)) {
    data$jenis_wilayah <- factor(as.character(data$jenis_wilayah),
                                 levels = c("Kabupaten", "Kota"))
    return(data)
  }
  if (!"kode_wilayah" %in% names(data)) {
    stop("Data harus punya kolom 'jenis_wilayah' atau 'kode_wilayah'.",
         call. = FALSE)
  }
  data$jenis_wilayah <- factor(
    ifelse(as.character(data$kode_wilayah) %in% c("7371", "7372", "7373"),
           "Kota", "Kabupaten"),
    levels = c("Kabupaten", "Kota")
  )
  data
}

# -----------------------------------------------------------------------------
# plot_tren(): tren per wilayah (small multiples, satu panel per wilayah)
#
# Argumen
#   data       data.frame atau objek sf (kolom geometri dibuang otomatis),
#              berisi SEMUA tahun (satu baris per wilayah-tahun)
#   indikator  NAMA KOLOM tanpa tanda kutip, mis. indikator = tpt
#   wilayah    kolom nama wilayah (bawaan: kabupaten)
#   waktu      kolom tahun, harus numerik (bawaan: tahun)
#   ncol       jumlah kolom panel (bawaan 6; 24 wilayah = 6 kolom x 4 baris)
#   mulai_nol  TRUE = sumbu Y mulai dari nol (bawaan); FALSE = menonjolkan
#              perubahan kecil, mis. pada rls
#   hanya      vektor nama wilayah bila hanya sebagian yang digambar
#              (NULL = semua wilayah)
#   judul, subjudul, caption   teks; NULL = dibuat otomatis (judul, caption)
#
# Panel diurutkan dari rata-rata indikator tertinggi; skala sumbu Y sama di
# semua panel agar tinggi garis antarpanel dapat dibandingkan.
#
# Hasil: objek ggplot (tidak menyimpan berkas; simpan dengan ggsave()).
# -----------------------------------------------------------------------------
plot_tren <- function(data, indikator, wilayah = kabupaten, waktu = tahun,
                      ncol = 6, mulai_nol = TRUE, hanya = NULL,
                      judul = NULL, subjudul = NULL, caption = NULL) {
  
  # 0. Prasyarat: tema dan palet tim
  if (!exists("theme_tim") || !exists("pal_tim")) {
    stop("Jalankan source(\"R/theme_tim.R\") lebih dulu.", call. = FALSE)
  }
  
  # 1. Nama kolom dari argumen. Hanya nama polos yang diterima.
  q_ind <- rlang::enquo(indikator)
  q_wil <- rlang::enquo(wilayah)
  q_wkt <- rlang::enquo(waktu)
  if (!rlang::quo_is_symbol(q_ind) || !rlang::quo_is_symbol(q_wil) ||
      !rlang::quo_is_symbol(q_wkt)) {
    stop("indikator, wilayah, dan waktu harus nama kolom tanpa tanda kutip, ",
         "mis. indikator = tpt.", call. = FALSE)
  }
  nama_ind <- rlang::as_name(q_ind)
  nama_wil <- rlang::as_name(q_wil)
  nama_wkt <- rlang::as_name(q_wkt)
  
  # 2. Siapkan data: buang geometri, cek kolom, buang baris kosong
  if (inherits(data, "sf")) data <- sf::st_drop_geometry(data)
  data <- as.data.frame(data)
  
  hilang <- setdiff(c(nama_ind, nama_wil, nama_wkt), names(data))
  if (length(hilang) > 0) {
    stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "), call. = FALSE)
  }
  if (!is.numeric(data[[nama_wkt]])) {
    stop("Kolom waktu harus numerik, misalnya 2023, 2024, 2025.", call. = FALSE)
  }
  
  if (!is.null(hanya)) {
    data <- data[data[[nama_wil]] %in% hanya, , drop = FALSE]
    if (nrow(data) == 0) {
      stop("Tidak ada data untuk wilayah yang dipilih (cek argumen hanya).",
           call. = FALSE)
    }
  }
  
  ada <- stats::complete.cases(data[, c(nama_ind, nama_wil, nama_wkt)])
  if (any(!ada)) {
    message(sum(!ada), " baris dengan nilai kosong dibuang.")
    data <- data[ada, , drop = FALSE]
  }
  
  # 3. Tren butuh lebih dari satu tahun
  awal  <- min(data[[nama_wkt]])
  akhir <- max(data[[nama_wkt]])
  if (awal == akhir) {
    stop("Tren butuh minimal dua tahun, sedangkan data hanya berisi tahun ",
         awal, ".", call. = FALSE)
  }
  
  data <- tambah_jenis_wilayah(data)
  
  # 4. Urutan panel: dari rata-rata indikator tertinggi
  rata   <- tapply(data[[nama_ind]], as.character(data[[nama_wil]]), mean)
  urutan <- names(sort(rata, decreasing = TRUE))
  data$panel <- factor(as.character(data[[nama_wil]]), levels = urutan)
  
  # Angka hanya pada tahun awal dan akhir
  ujung <- data[data[[nama_wkt]] %in% c(awal, akhir), , drop = FALSE]
  
  # Batas sumbu Y yang sama untuk semua panel
  rentang <- range(data[[nama_ind]])
  selisih <- diff(rentang)
  if (mulai_nol) {
    batas <- c(0, rentang[2] * 1.12)
  } else {
    batas <- c(rentang[1] - 0.10 * selisih, rentang[2] + 0.18 * selisih)
  }
  
  # 5. Label sumbu dan teks otomatis (kolom tpt dan rls memakai label tim)
  label_sumbu <- function(nama) {
    acuan <- c(tpt = lab_tpt, rls = lab_rls)
    if (nama %in% names(acuan)) acuan[[nama]] else nama
  }
  singkat <- function(nama) {
    if (nama %in% c("tpt", "rls")) toupper(nama) else nama
  }
  fmt <- scales::label_number(accuracy = 0.01, decimal.mark = ",")
  
  if (is.null(judul)) {
    judul <- paste0("Tren ", singkat(nama_ind), " per wilayah, ", awal, "-", akhir)
  }
  if (is.null(subjudul) && length(urutan) > 1) {
    subjudul <- "Panel diurutkan dari rata-rata tertinggi; skala sumbu Y sama di semua panel"
  }
  if (is.null(caption)) {
    caption <- paste0("Angka pada grafik: nilai tahun ", awal, " dan ", akhir,
                      ". Sumber: BPS.")
  }
  
  # 6. Gambar. Urutan lapisan: garis dulu, titik di atasnya, lalu angka.
  ggplot(data, aes(x = {{ waktu }}, y = {{ indikator }}, group = panel)) +
    geom_line(color = pal_tim[["tepi"]], linewidth = 0.6) +
    geom_point(aes(fill = jenis_wilayah, shape = jenis_wilayah),
               color = pal_tim[["tepi"]], size = 2.4, stroke = 0.5) +
    geom_text(data = ujung, aes(label = fmt({{ indikator }})),
              vjust = -1, size = 2.5, color = pal_tim[["teks"]]) +
    facet_wrap(~ panel, ncol = ncol, labeller = label_wrap_gen(width = 22)) +
    scale_fill_jenis() +
    scale_shape_jenis() +
    scale_x_continuous(breaks = awal:akhir, expand = expansion(mult = 0.18)) +
    scale_y_continuous(limits = batas,
                       breaks = scales::breaks_pretty(n = 3),
                       labels = scales::label_number(decimal.mark = ","),
                       expand = expansion(mult = c(0, 0))) +
    labs(title = judul, subtitle = subjudul, caption = caption,
         x = NULL, y = label_sumbu(nama_ind)) +
    theme_tim(base_size = 10)
}

# =============================================================================
# D. UJI COBA FUNGSI TREN
# =============================================================================

# D1. Pemakaian utama
plot_tren(d, indikator = tpt)

# D2. Ganti satu argumen, seperti saat demo
plot_tren(d, indikator = rls)
plot_tren(d, indikator = rls, mulai_nol = FALSE)   # menonjolkan perubahan kecil

# D3. Variasi tampilan
plot_tren(d, indikator = tpt, hanya = c("Makassar", "Gowa", "Wajo"), ncol = 3)

# D4. Pesan error yang diharapkan (disengaja, bukan kesalahan)
try(plot_tren(d, indikator = "tpt"))                   # tanda kutip ditolak
try(plot_tren(d, indikator = abc))                     # kolom tidak ada
try(plot_tren(d[d$tahun == 2025, ], indikator = tpt))  # tren butuh dua tahun

# D5. Simpan satu hasil (fungsi tidak menyimpan gambar sendiri)
dir_uji <- file.path(dir_repo, "keluaran", "uji")
dir.create(dir_uji, recursive = TRUE, showWarnings = FALSE)
g <- plot_tren(d, indikator = tpt)
ggsave(file.path(dir_uji, "uji_plot_tren.png"), g,
       width = 13, height = 9.5, dpi = 200, bg = "white")
message("Selesai. Gambar tersimpan di: ", rel(dir_uji))

# =============================================================================
# E. FUNGSI GRAFIK SEBAR
# =============================================================================
# -----------------------------------------------------------------------------
# Pembantu: tambah kolom jenis_wilayah dari kode_wilayah
# (7371 Makassar, 7372 Parepare, 7373 Palopo = Kota; sisanya Kabupaten).
# -----------------------------------------------------------------------------
tambah_jenis_wilayah <- function(data) {
  if ("jenis_wilayah" %in% names(data)) {
    data$jenis_wilayah <- factor(as.character(data$jenis_wilayah),
                                 levels = c("Kabupaten", "Kota"))
    return(data)
  }
  if (!"kode_wilayah" %in% names(data)) {
    stop("Data harus punya kolom 'jenis_wilayah' atau 'kode_wilayah'.",
         call. = FALSE)
  }
  data$jenis_wilayah <- factor(
    ifelse(as.character(data$kode_wilayah) %in% c("7371", "7372", "7373"),
           "Kota", "Kabupaten"),
    levels = c("Kabupaten", "Kota")
  )
  data
}

# -----------------------------------------------------------------------------
# plot_sebar(): scatterplot dua indikator + garis regresi + pita kepercayaan
#
# Argumen
#   data       data.frame atau objek sf (kolom geometri dibuang otomatis)
#   x, y       NAMA KOLOM tanpa tanda kutip, mis. x = rls, y = tpt
#   tahun      satu tahun yang digambar (wajib bila data berisi lebih dari satu
#              tahun, supaya satu wilayah tidak muncul berulang)
#   level      tingkat kepercayaan pita (bawaan 0,95)
#   garis      TRUE = tampilkan garis regresi dan pita
#   label_kota TRUE = beri nama pada titik kota
#   judul, subjudul, caption   teks; NULL = dibuat otomatis (judul, caption)
#
# Hasil: objek ggplot (tidak menyimpan berkas; simpan dengan ggsave()).
# -----------------------------------------------------------------------------
plot_sebar <- function(data, x, y, tahun = NULL, level = 0.95,
                       garis = TRUE, label_kota = TRUE,
                       judul = NULL, subjudul = NULL, caption = NULL) {
  
  # 0. Prasyarat: tema dan palet tim
  if (!exists("theme_tim") || !exists("pal_tim")) {
    stop("Jalankan source(\"R/theme_tim.R\") lebih dulu.", call. = FALSE)
  }
  
  # 1. Nama kolom dari argumen. Hanya nama polos yang diterima.
  q_x <- rlang::enquo(x)
  q_y <- rlang::enquo(y)
  if (!rlang::quo_is_symbol(q_x) || !rlang::quo_is_symbol(q_y)) {
    stop("x dan y harus nama kolom tanpa tanda kutip, mis. x = rls, y = tpt.",
         call. = FALSE)
  }
  nama_x <- rlang::as_name(q_x)
  nama_y <- rlang::as_name(q_y)
  
  # 2. Siapkan data: buang geometri, cek kolom, buang baris kosong
  if (inherits(data, "sf")) data <- sf::st_drop_geometry(data)
  data <- as.data.frame(data)
  
  hilang <- setdiff(c(nama_x, nama_y), names(data))
  if (length(hilang) > 0) {
    stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "), call. = FALSE)
  }
  
  # 3. Satu tahun saja (kebebasan titik untuk regresi)
  if ("tahun" %in% names(data)) {
    if (is.null(tahun)) {
      semua <- sort(unique(data$tahun))
      if (length(semua) > 1) {
        stop("Data berisi lebih dari satu tahun (",
             paste(semua, collapse = ", "),
             "). Pilih satu dengan argumen tahun = ..., karena wilayah yang ",
             "sama akan muncul berulang dan itu merusak asumsi regresi.",
             call. = FALSE)
      }
      tahun <- semua
    } else {
      data <- data[data$tahun == tahun, , drop = FALSE]
      if (nrow(data) == 0) {
        stop("Tidak ada data untuk tahun ", tahun, ".", call. = FALSE)
      }
    }
  }
  
  ada <- stats::complete.cases(data[, c(nama_x, nama_y)])
  if (any(!ada)) {
    message(sum(!ada), " baris dengan nilai kosong dibuang.")
    data <- data[ada, , drop = FALSE]
  }
  
  data <- tambah_jenis_wilayah(data)
  
  # 4. Label sumbu dan teks otomatis (kolom tpt dan rls memakai label tim)
  label_sumbu <- function(nama) {
    acuan <- c(tpt = lab_tpt, rls = lab_rls)
    if (nama %in% names(acuan)) acuan[[nama]] else nama
  }
  singkat <- function(nama) {
    if (nama %in% c("tpt", "rls")) toupper(nama) else nama
  }
  ket_tahun <- if (!is.null(tahun)) paste0(", ", tahun) else ""
  
  if (is.null(judul)) {
    judul <- paste0(singkat(nama_y), " menurut ", singkat(nama_x), ket_tahun)
  }
  if (is.null(caption)) {
    caption <- paste0("Sumber: BPS.",
                      if (garis) paste0(" Garis: regresi linear dengan pita kepercayaan ",
                                        round(level * 100), "%.") else "")
  }
  
  # 5. Gambar. Urutan lapisan: pita dan garis dulu, titik di atasnya.
  g <- ggplot(data, aes(x = {{ x }}, y = {{ y }}))
  
  if (garis && nrow(data) >= 3) {
    g <- g + geom_smooth(method = "lm", formula = y ~ x, level = level,
                         color = pal_tim[["garis_utama"]],
                         fill  = pal_tim[["abu_terang"]],
                         alpha = 0.8, linewidth = 1)
  }
  
  g <- g +
    geom_point(aes(fill = jenis_wilayah, shape = jenis_wilayah),
               color = pal_tim[["tepi"]], size = 3.2, stroke = 0.6) +
    scale_fill_jenis() +
    scale_shape_jenis() +
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.12)))
  
  if (label_kota && "kabupaten" %in% names(data) &&
      any(data$jenis_wilayah == "Kota")) {
    g <- g + geom_text(data = function(d) d[d$jenis_wilayah == "Kota", ],
                       aes(label = kabupaten), vjust = -1.2, size = 3.3,
                       color = pal_tim[["teks"]], check_overlap = TRUE)
  }
  
  g +
    labs(title = judul, subtitle = subjudul, caption = caption,
         x = label_sumbu(nama_x), y = label_sumbu(nama_y)) +
    theme_tim(grid = "xy")
}

# =============================================================================
# F. UJI COBA FUNGSI SEBAR
# =============================================================================

# F1. Pemakaian utama
plot_sebar(d, x = rls, y = tpt, tahun = 2025)

# F2. Ganti satu argumen, seperti saat demo
plot_sebar(d, x = rls, y = tpt, tahun = 2023)
plot_sebar(d, x = tpt, y = rls, tahun = 2025)        # sumbu dibalik

# F3. Variasi tampilan
plot_sebar(d, x = rls, y = tpt, tahun = 2025, garis = FALSE)
plot_sebar(d, x = rls, y = tpt, tahun = 2025, label_kota = FALSE)

# F4. Pesan error yang diharapkan (disengaja, bukan kesalahan)
try(plot_sebar(d, x = rls, y = tpt))                 # tahun wajib dipilih
try(plot_sebar(d, x = "rls", y = tpt, tahun = 2025)) # tanda kutip ditolak
try(plot_sebar(d, x = abc, y = tpt, tahun = 2025))   # kolom tidak ada

# F5. Simpan satu hasil (fungsi tidak menyimpan gambar sendiri)
dir_uji <- file.path(dir_repo, "keluaran", "uji")
dir.create(dir_uji, recursive = TRUE, showWarnings = FALSE)
g <- plot_sebar(d, x = rls, y = tpt, tahun = 2025)
ggsave(file.path(dir_uji, "uji_plot_sebar.png"), g,
       width = 8, height = 6, dpi = 200, bg = "white")
message("Selesai. Gambar tersimpan di: ", rel(dir_uji))

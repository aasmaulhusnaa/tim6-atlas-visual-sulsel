# =============================================================================
# 24_grafik_wilayah.R - Hari 9 (Checkpoint 3): 24 profil kabupaten/kota
# Tim 6 - Atlas Visual Sulawesi Selatan
#
# Ketentuan lembar tugas:
#   - 24 profil dari SATU perintah (purrr::walk() + ggsave())
#   - Keluaran: keluaran/profil/ (PNG, ukuran sama, nama tanpa spasi)
#   - Fungsi menerima indikator dan tahun sebagai argumen (untuk demo dosen)
#   - Memakai theme_tim() dan palet tim (tanpa paket tema siap pakai)
#   - Harus jalan dari sesi R baru, tanpa penyuntingan manual
#
# Cara pakai: buka tim6-atlas-visual-sulsel.Rproj, lalu source() berkas ini.
# =============================================================================

library(ggplot2)
library(patchwork)
library(sf)
library(purrr)

# Saklar. Ubah ke TRUE bila perlu.
jalankan_uji <- FALSE   # contoh plot_profil() + pesan error yang disengaja

# =============================================================================
# A. JALUR REPOSITORI 
# =============================================================================
cari_dir_repo <- function(mulai = getwd()) {
  d <- normalizePath(mulai, winslash = "/", mustWork = FALSE)
  repeat {
    if (length(list.files(d, pattern = "\\.Rproj$")) > 0 ||
        dir.exists(file.path(d, ".git")) ||
        dir.exists(file.path(d, "data-bersih"))) return(d)
    induk <- dirname(d)
    if (identical(induk, d)) return(NA_character_)
    d <- induk
  }
}
lokasi_skrip <- function() {
  of <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(of) && nzchar(of)) {
    return(normalizePath(dirname(of), winslash = "/", mustWork = FALSE))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
    if (!is.null(p) && nzchar(p)) {
      return(normalizePath(dirname(p), winslash = "/", mustWork = FALSE))
    }
  }
  NA_character_
}

dir_repo <- "C:/Users/ThinkPad E14/Documents/STATISTIK/PROJECT TIM 6 ATLAS VISUAL SULSEL"

if (!dir.exists(dir_repo)) {
  stop("Folder repositori tidak ditemukan: ", dir_repo, call. = FALSE)
}
rel <- function(p) substring(p, nchar(dir_repo) + 2)
cat("Repositori:", basename(dir_repo), "\n")

# Cari berkas: lokasi baku dulu (relatif ke dir_repo), lalu cari berdasarkan nama
cari_berkas <- function(kandidat) {
  ada <- kandidat[file.exists(file.path(dir_repo, kandidat))]
  if (length(ada) == 0) {
    nama  <- gsub("\\.", "\\\\.", unique(basename(kandidat)))
    cari  <- list.files(dir_repo, pattern = paste0("^(", paste(nama, collapse = "|"), ")$"),
                        recursive = TRUE)
    if (length(cari) > 0) ada <- cari
  }
  if (length(ada) == 0) {
    stop("Berkas tidak ditemukan. Dicari di:\n",
         paste0("  - ", kandidat, collapse = "\n"), call. = FALSE)
  }
  file.path(dir_repo, ada[1])
}

# =============================================================================
# B. MUAT TEMA DAN DATA
# =============================================================================
berkas_tema <- file.path(dir_repo, "theme_tim (fix).R")
if (!file.exists(berkas_tema)) {
  stop("File tema tidak ditemukan: ", berkas_tema, call. = FALSE)
}
source(berkas_tema)
message("Tema dimuat dari: ", rel(berkas_tema))

berkas_data <- file.path(dir_repo, "data_bersih.rds")
if (!file.exists(berkas_data)) {
  stop("File data tidak ditemukan: ", berkas_data, call. = FALSE)
}
d <- readRDS(berkas_data)
message("Data dimuat dari: ", rel(berkas_data))

# Kesepakatan nama kolom tim: kabupaten (data memakai kabkota)
if ("kabkota" %in% names(d) && !"kabupaten" %in% names(d)) {
  names(d)[names(d) == "kabkota"] <- "kabupaten"
}
cat("Baris:", nrow(d), "| Kolom:", paste(names(d), collapse = ", "), "\n")

# Pemeriksaan data: harus memuat kolom ini, 24 wilayah, minimal 3 tahun
stopifnot(
  "Kolom wajib: kode_wilayah, kabupaten, tahun, tpt, rls" =
    all(c("kode_wilayah", "kabupaten", "tahun", "tpt", "rls") %in% names(d)),
  "Data harus berisi 24 wilayah"  = length(unique(d$kabupaten)) == 24,
  "Data harus berisi minimal 3 tahun" = length(unique(d$tahun)) >= 3
)
if (!inherits(d, "sf")) message("PERHATIAN: data bukan objek sf, peta lokasi akan dilewati.")

# =============================================================================
# C. FUNGSI PROFIL
# =============================================================================

# Pastikan objek dari theme_tim.R tersedia
periksa_tema <- function() {
  perlu <- c("theme_tim", "pal_tim", "pal_peta", "scale_fill_jenis", "scale_shape_jenis")
  hilang <- perlu[!vapply(perlu, exists, logical(1))]
  if (length(hilang) > 0) {
    stop("Objek dari theme_tim.R belum ada: ", paste(hilang, collapse = ", "),
         ". Jalankan source() theme_tim.R lebih dulu.", call. = FALSE)
  }
  kunci <- c("abu_terang", "tepi", "teks", "garis_utama", "kabupaten", "kota")
  if (!all(kunci %in% names(pal_tim))) {
    stop("pal_tim harus punya elemen: ", paste(kunci, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

# jenis_wilayah dari kode_wilayah (7371 Makassar, 7372 Parepare, 7373 Palopo = Kota)
tambah_jenis_wilayah <- function(data) {
  if ("jenis_wilayah" %in% names(data)) {
    data$jenis_wilayah <- factor(as.character(data$jenis_wilayah),
                                 levels = c("Kabupaten", "Kota"))
    return(data)
  }
  if (!"kode_wilayah" %in% names(data)) {
    stop("Data harus punya kolom 'jenis_wilayah' atau 'kode_wilayah'.", call. = FALSE)
  }
  data$jenis_wilayah <- factor(
    ifelse(as.character(data$kode_wilayah) %in% c("7371", "7372", "7373"),
           "Kota", "Kabupaten"),
    levels = c("Kabupaten", "Kota"))
  data
}

# Label sumbu: pakai label tim (lab_tpt, lab_rls) bila ada, kalau tidak nama kolom
.label_sumbu <- function(nama) {
  if (nama == "tpt" && exists("lab_tpt")) return(lab_tpt)
  if (nama == "rls" && exists("lab_rls")) return(lab_rls)
  nama
}
.singkat <- function(nama) if (nama %in% c("tpt", "rls")) toupper(nama) else nama

# Tabel unik kode_wilayah + nama wilayah, urut menurut kode
.tabel_wilayah <- function(data, nama_wil) {
  tab <- as.data.frame(if (inherits(data, "sf")) sf::st_drop_geometry(data) else data)
  if (!all(c(nama_wil, "kode_wilayah") %in% names(tab))) {
    stop("Data harus punya kolom '", nama_wil, "' dan 'kode_wilayah'.", call. = FALSE)
  }
  tabel <- unique(tab[, c("kode_wilayah", nama_wil)])
  tabel[order(as.character(tabel$kode_wilayah)), , drop = FALSE]
}

# Satu panel tren: garis abu terang = wilayah lain, garis vermilion (garis_utama)
# + titik jenis wilayah = terpilih
.panel_profil <- function(data, nama, indikator, wilayah, waktu, batas) {
  nama_ind <- rlang::as_name(rlang::enquo(indikator))
  nama_wil <- rlang::as_name(rlang::enquo(wilayah))
  nama_wkt <- rlang::as_name(rlang::enquo(waktu))
  
  lain  <- data[data[[nama_wil]] != nama, , drop = FALSE]
  pilih <- data[data[[nama_wil]] == nama, , drop = FALSE]
  awal  <- min(data[[nama_wkt]])
  akhir <- max(data[[nama_wkt]])
  ujung <- pilih[pilih[[nama_wkt]] %in% c(awal, akhir), , drop = FALSE]
  fmt   <- scales::label_number(accuracy = 0.01, decimal.mark = ",")
  
  ggplot(mapping = aes(x = {{ waktu }}, y = {{ indikator }})) +
    geom_line(data = lain, aes(group = {{ wilayah }}),
              color = pal_tim[["abu_terang"]], linewidth = 0.5) +
    geom_line(data = pilih, color = pal_tim[["garis_utama"]], linewidth = 1.1) +
    geom_point(data = pilih, aes(fill = jenis_wilayah, shape = jenis_wilayah),
               color = pal_tim[["tepi"]], size = 3.4, stroke = 0.6) +
    geom_text(data = ujung, aes(label = fmt({{ indikator }})),
              vjust = -1.1, size = 3, color = pal_tim[["teks"]]) +
    scale_fill_jenis(guide = "none") +
    scale_shape_jenis(guide = "none") +
    scale_x_continuous(breaks = awal:akhir, expand = expansion(mult = 0.12)) +
    scale_y_continuous(limits = batas,
                       labels = scales::label_number(decimal.mark = ","),
                       expand = expansion(mult = c(0, 0.12))) +
    coord_cartesian(clip = "off") +
    labs(x = NULL, y = .label_sumbu(nama_ind)) +
    theme_tim() +
    theme(legend.position = "none")
}

# Peta kecil lokasi (tanpa titik penanda), warna dari palet peta tim (pal_peta,
# Blues): wilayah terpilih = kelas tergelap, wilayah lain = kelas ke-2 (terang),
# garis batas abu gelap (pal_tim[["tepi"]]) sesuai catatan di theme_tim.R.
.peta_lokasi <- function(peta, nama, nama_wil) {
  pilih <- peta[as.character(peta[[nama_wil]]) == nama, ]
  lain  <- peta[as.character(peta[[nama_wil]]) != nama, ]
  
  ggplot() +
    geom_sf(data = lain,  fill = pal_peta[2], color = pal_tim[["tepi"]],
            linewidth = 0.2) +
    geom_sf(data = pilih, fill = pal_peta[length(pal_peta)],
            color = pal_tim[["tepi"]], linewidth = 0.5) +
    labs(title = "Lokasi", x = NULL, y = NULL) +
    theme_tim(grid = "none") +
    theme(axis.text = element_blank(), axis.title = element_blank(),
          legend.position = "none",
          plot.title = element_text(size = 10, face = "bold"))
}

# -----------------------------------------------------------------------------
# plot_profil(): profil satu wilayah = tren dua indikator berdampingan
#
#   data        data.frame / sf, SEMUA wilayah dan SEMUA tahun
#   nama        nama satu wilayah (teks), mis. "Makassar"
#   kiri,kanan  NAMA KOLOM tanpa kutip (bawaan: tpt dan rls)
#   wilayah     kolom nama wilayah (bawaan: kabupaten)
#   waktu       kolom tahun, numerik (bawaan: tahun)
#   tahun       vektor tahun yang ditampilkan di tren, mis. 2024:2025
#               (NULL = semua tahun)
#   tahun_rank  tahun untuk peringkat di subjudul (NULL = tahun terakhir)
#   nol_kiri    sumbu Y panel kiri mulai dari nol? (bawaan TRUE)
#   nol_kanan   sumbu Y panel kanan mulai dari nol? (bawaan FALSE)
#   peta_lokasi TRUE = tambah peta kecil lokasi (data harus sf)
#
# Sumbu Y dihitung dari SEMUA wilayah, jadi sama di semua profil.
# Hasil: objek patchwork; tidak menyimpan berkas.
# -----------------------------------------------------------------------------
plot_profil <- function(data, nama, kiri = tpt, kanan = rls,
                        wilayah = kabupaten, waktu = tahun,
                        tahun = NULL, tahun_rank = NULL,
                        nol_kiri = TRUE, nol_kanan = FALSE, peta_lokasi = TRUE) {
  periksa_tema()
  
  # 1. Nama kolom dari argumen (hanya nama polos)
  q_kiri  <- rlang::enquo(kiri)
  q_kanan <- rlang::enquo(kanan)
  q_wil   <- rlang::enquo(wilayah)
  q_wkt   <- rlang::enquo(waktu)
  if (!all(vapply(list(q_kiri, q_kanan, q_wil, q_wkt), rlang::quo_is_symbol, logical(1)))) {
    stop("kiri, kanan, wilayah, dan waktu harus nama kolom tanpa tanda kutip, ",
         "mis. kiri = tpt.", call. = FALSE)
  }
  nama_kiri  <- rlang::as_name(q_kiri)
  nama_kanan <- rlang::as_name(q_kanan)
  nama_wil   <- rlang::as_name(q_wil)
  nama_wkt   <- rlang::as_name(q_wkt)
  
  # 2. Siapkan data
  peta_sf <- NULL
  if (inherits(data, "sf")) {
    peta_sf <- data
    data    <- sf::st_drop_geometry(data)
  }
  data <- as.data.frame(data)
  
  hilang <- setdiff(c(nama_kiri, nama_kanan, nama_wil, nama_wkt), names(data))
  if (length(hilang) > 0) {
    stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "), call. = FALSE)
  }
  if (!is.numeric(data[[nama_wkt]])) {
    stop("Kolom waktu harus numerik, misalnya 2023, 2024, 2025.", call. = FALSE)
  }
  if (!is.null(tahun)) {
    data <- data[data[[nama_wkt]] %in% tahun, , drop = FALSE]
    if (nrow(data) == 0) stop("Tidak ada data untuk tahun yang diminta.", call. = FALSE)
  }
  ada <- stats::complete.cases(data[, c(nama_kiri, nama_kanan, nama_wil, nama_wkt)])
  if (any(!ada)) {
    message(sum(!ada), " baris dengan nilai kosong dibuang.")
    data <- data[ada, , drop = FALSE]
  }
  data <- tambah_jenis_wilayah(data)
  
  # 3. Wilayah terpilih harus satu dan ada di data
  if (length(nama) != 1 || !is.character(nama)) {
    stop("nama harus satu nama wilayah (teks), mis. \"Makassar\".", call. = FALSE)
  }
  if (!nama %in% data[[nama_wil]]) {
    stop("Wilayah '", nama, "' tidak ditemukan. Contoh nama yang ada: ",
         paste(utils::head(sort(unique(as.character(data[[nama_wil]]))), 5),
               collapse = ", "), ", ...", call. = FALSE)
  }
  
  awal  <- min(data[[nama_wkt]])
  akhir <- max(data[[nama_wkt]])
  if (awal == akhir) {
    stop("Profil butuh minimal dua tahun, sedangkan data hanya berisi tahun ",
         awal, ".", call. = FALSE)
  }
  if (is.null(tahun_rank)) tahun_rank <- akhir
  th <- data[data[[nama_wkt]] == tahun_rank, , drop = FALSE]
  if (nrow(th) == 0 || !nama %in% th[[nama_wil]]) {
    stop("Tidak ada data '", nama, "' untuk tahun_rank = ", tahun_rank, ".",
         call. = FALSE)
  }
  
  # 4. Batas sumbu Y sama untuk semua profil
  hitung_batas <- function(v, dari_nol) {
    c(if (dari_nol) 0 else floor(min(v)) - 1, ceiling(max(v)))
  }
  batas_kiri  <- hitung_batas(data[[nama_kiri]],  nol_kiri)
  batas_kanan <- hitung_batas(data[[nama_kanan]], nol_kanan)
  
  # 5. Teks
  jenis  <- as.character(data$jenis_wilayah[data[[nama_wil]] == nama][1])
  urutan <- function(kol) {
    r <- rank(-th[[kol]], ties.method = "min")
    r[th[[nama_wil]] == nama][1]
  }
  n_wil <- nrow(th)
  judul <- paste0(nama, " (", jenis, ")")
  subjudul <- paste0(tahun_rank, ": ",
                     .singkat(nama_kiri),  " urutan ke-", urutan(nama_kiri),  ", ",
                     .singkat(nama_kanan), " urutan ke-", urutan(nama_kanan),
                     " dari ", n_wil, " (1 = tertinggi)")
  caption <- paste0("Garis abu = ", n_wil - 1, " wilayah lain. Sumber: BPS diolah Tim 6.")
  
  # 6. Dua panel
  p_kiri  <- .panel_profil(data, nama, {{ kiri }},  {{ wilayah }}, {{ waktu }}, batas_kiri)
  p_kanan <- .panel_profil(data, nama, {{ kanan }}, {{ wilayah }}, {{ waktu }}, batas_kanan)
  
  # 7. Peta lokasi (opsional)
  if (peta_lokasi && is.null(peta_sf)) {
    message("Data bukan objek sf: peta lokasi dilewati.")
    peta_lokasi <- FALSE
  }
  if (peta_lokasi) {
    peta_sf <- peta_sf[!duplicated(as.character(peta_sf[[nama_wil]])), nama_wil]
    p_peta  <- .peta_lokasi(peta_sf, nama, nama_wil)
    susunan <- (p_kiri | p_kanan | p_peta) + plot_layout(widths = c(1, 1, 0.5))
  } else {
    susunan <- p_kiri | p_kanan
  }
  
  susunan +
    plot_annotation(title = judul, subtitle = subjudul, caption = caption,
                    theme = theme_tim())
}

# -----------------------------------------------------------------------------
# buat_semua_profil(): SATU perintah untuk 24 berkas (purrr::walk2 + ggsave)
#
#   data      sama seperti plot_profil() (pakai objek sf agar ada peta lokasi)
#   ...       argumen lain diteruskan ke plot_profil(): kiri, kanan, tahun,
#             tahun_rank, nol_kiri, nol_kanan, peta_lokasi, waktu
#   wilayah   kolom nama wilayah (bawaan kabupaten)
#   tampilkan TRUE = tiap profil juga ditampilkan di panel Plots
#   folder    folder keluaran (bawaan: keluaran/profil di repositori)
#   lebar, tinggi, dpi   ukuran sama untuk semua berkas
#
# Nama berkas: profil_<kode>_<nama-wilayah>.png (tanpa spasi).
# Mengembalikan (tanpa mencetak) vektor jalur 24 berkas.
#
# Contoh demo:
#   buat_semua_profil(d, tahun_rank = 2023)
#   buat_semua_profil(d, kiri = rls, kanan = tpt, nol_kiri = FALSE, nol_kanan = TRUE)
# -----------------------------------------------------------------------------
buat_semua_profil <- function(data, ..., wilayah = kabupaten, tampilkan = FALSE,
                              folder = file.path(dir_repo, "keluaran", "profil"),
                              lebar = 13, tinggi = 5, dpi = 150) {
  q_wil    <- rlang::enquo(wilayah)
  nama_wil <- rlang::as_name(q_wil)
  tabel    <- .tabel_wilayah(data, nama_wil)
  
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  slug   <- function(w) gsub("^-|-$", "", gsub("[^a-z0-9]+", "-", tolower(w)))
  berkas <- file.path(folder, paste0("profil_", tabel$kode_wilayah, "_",
                                     slug(tabel[[nama_wil]]), ".png"))
  
  # Satu perintah untuk semua wilayah, tanpa kode berulang
  purrr::walk2(tabel[[nama_wil]], berkas, function(w, f) {
    g <- plot_profil(data, nama = w, wilayah = !!q_wil, ...)
    if (tampilkan) print(g)
    ggplot2::ggsave(f, g, width = lebar, height = tinggi, dpi = dpi, bg = "white")
  })
  
  stopifnot("Ada berkas profil yang tidak terbentuk." = all(file.exists(berkas)))
  message(length(berkas), " profil tersimpan di: ", rel(folder))
  invisible(berkas)
}

# =============================================================================
# D. UJI COBA (hanya jalan bila jalankan_uji <- TRUE di bagian atas)
# =============================================================================
if (jalankan_uji) {
  print(plot_profil(d, "Makassar"))                       # kota, dengan peta
  print(plot_profil(d, "Bulukumba"))                      # kabupaten
  print(plot_profil(d, "Makassar", peta_lokasi = FALSE))  # tanpa peta
  print(plot_profil(d, "Gowa", tahun_rank = 2023))        # ganti tahun peringkat
  print(plot_profil(d, "Gowa", kiri = rls, kanan = tpt,
                    nol_kiri = FALSE, nol_kanan = TRUE))
  
  # Pesan error yang diharapkan (disengaja)
  try(plot_profil(d, "Atlantis"))
  try(plot_profil(d, "Makassar", kiri = "tpt"))
  try(plot_profil(d, c("Gowa", "Wajo")))
}

# =============================================================================
# E. SATU PERINTAH, 24 BERKAS
# =============================================================================
berkas_profil <- buat_semua_profil(d)

# Pemeriksaan: tepat 24 berkas PNG
dir_profil <- file.path(dir_repo, "keluaran", "profil")
n_berkas   <- length(list.files(dir_profil, pattern = "^profil_.*\\.png$"))
cat("Jumlah berkas profil:", n_berkas, "(harus 24)\n")
stopifnot(n_berkas == 24, length(unique(berkas_profil)) == 24)


#-------------------------------------------------------------------------------
# DEMO

# buat_semua_profil(d, tahun_rank = 2023)
# buat_semua_profil(d, tahun = 2024:2025)
# buat_semua_profil(d, kiri = rls, kanan = tpt, nol_kiri = FALSE, nol_kanan = TRUE)

#-------------------------------------------------------------------------------

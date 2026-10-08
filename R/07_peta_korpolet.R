# peta_koroplet.R
# =============================================================================
# Hari 9: Peta koroplet Sulawesi Selatan (sf) + uji buta warna (colorspace)
#
# Isi:
#   plot_peta()             fungsi peta koroplet; indikator dan tahun = argumen
#   bagi_kelas()            pembagi nilai menjadi kelas (kuantil / interval sama)
#   cek_palet_peta()        uji palet: urutan terang-gelap tetap terbaca pada
#                           deuteranopia, protanopia, tritanopia, dan grayscale
#   uji_buta_warna_peta()   peta yang sama dalam 3 tampilan: normal, deuteranopia,
#                           protanopia (bukti uji untuk atlas)
#
# Memakai: 03_theme_tim.R (pal_tim, pal_peta, scale_fill_peta, theme_tim, lab_*)
#          data-bersih/data_bersih.rds (objek sf: kode_wilayah, kabupaten, tahun,
#          tpt, rls, geometry)
# Paket  : ggplot2, sf, colorspace, patchwork, rlang
#   install.packages(c("sf", "colorspace", "patchwork"))
#
# CARA MENJALANKAN: buka repositori lewat file .Rproj (atau pastikan folder kerja
# di dalam repositori), lalu jalankan seluruh skrip. Jalur dicari otomatis.
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
for (p in c("ggplot2", "sf", "colorspace", "patchwork", "rlang")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    stop("Paket '", p, "' belum terpasang. Jalankan: install.packages('", p, "')",
         call. = FALSE)
  }
}
library(ggplot2)
library(sf)

# Mencari berkas di beberapa lokasi yang mungkin (relatif terhadap repositori)
cari_berkas <- function(kandidat) {
  ada <- kandidat[file.exists(file.path(dir_repo, kandidat))]
  if (length(ada) == 0) {
    stop("Berkas tidak ditemukan. Sudah dicari di (relatif terhadap repositori):\n",
         paste0("  - ", kandidat, collapse = "\n"), call. = FALSE)
  }
  file.path(dir_repo, ada[1])
}

berkas_tema <- cari_berkas(c("R/03_theme_tim.R",
                             "theme_tim/03_theme_tim.R",
                             "R/theme_tim.R"))
source(berkas_tema)
message("Tema dimuat dari: ", rel(berkas_tema))

berkas_data <- cari_berkas(c("data-bersih/data_bersih.rds",
                             "data/data-bersih/data_bersih.rds"))
d <- readRDS(berkas_data)
message("Data dimuat dari: ", rel(berkas_data))
if (!inherits(d, "sf")) {
  stop("data_bersih.rds bukan objek sf (tidak memuat geometri peta).", call. = FALSE)
}
cat("Baris:", nrow(d), "| Kolom:", paste(names(d), collapse = ", "), "\n")

# =============================================================================
# C. FUNGSI PETA
# =============================================================================

# format angka dengan koma desimal
koma <- function(x, d = 2) format(round(x, d), nsmall = d, decimal.mark = ",")

# label sumbu/legenda: tpt dan rls memakai label tim
label_indikator <- function(nama) {
  acuan <- c(tpt = lab_tpt, rls = lab_rls)
  if (nama %in% names(acuan)) acuan[[nama]] else nama
}
singkat_indikator <- function(nama) {
  if (nama %in% c("tpt", "rls")) toupper(nama) else nama
}

# NULL = teks otomatis; NA = tanpa teks; selain itu dipakai apa adanya
atur_teks <- function(x, otomatis) {
  if (is.null(x)) otomatis else if (length(x) == 1 && is.na(x)) NULL else x
}

# -----------------------------------------------------------------------------
# bagi_kelas(): membagi nilai numerik menjadi kelas berlabel (faktor berurutan)
#   metode "kuantil": tiap kelas memuat kira-kira jumlah wilayah yang sama
#   metode "sama"   : lebar interval tiap kelas sama
# -----------------------------------------------------------------------------
bagi_kelas <- function(x, n = 5, metode = c("kuantil", "sama"), digit = 2) {
  metode <- match.arg(metode)
  stopifnot(n >= 3, n <= 7)
  br <- if (metode == "kuantil") {
    unique(stats::quantile(x, probs = seq(0, 1, length.out = n + 1),
                           na.rm = TRUE, names = FALSE))
  } else {
    seq(min(x, na.rm = TRUE), max(x, na.rm = TRUE), length.out = n + 1)
  }
  k <- length(br) - 1
  if (k < 3) {
    stop("Nilai terlalu sedikit yang berbeda untuk dibagi menjadi minimal 3 kelas.",
         call. = FALSE)
  }
  if (k < n) {
    warning("Batas kelas kembar; jumlah kelas dikurangi menjadi ", k, ".", call. = FALSE)
  }
  lab <- paste0(koma(br[-length(br)], digit), " - ", koma(br[-1], digit))
  cut(x, breaks = br, include.lowest = TRUE, labels = lab)
}

# -----------------------------------------------------------------------------
# warna_kelas_peta(): warna n kelas persis seperti yang dipakai scale_fill_peta()
# (diambil dari plot bantu, jadi selalu sama dengan skala tim)
# -----------------------------------------------------------------------------
warna_kelas_peta <- function(n) {
  tmp <- data.frame(k = factor(seq_len(n)), y = 1)
  g <- ggplot(tmp, aes(k, y, fill = k)) + geom_col() +
    scale_fill_peta("kelas", n = n)
  ggplot_build(g)$data[[1]]$fill
}

# -----------------------------------------------------------------------------
# titik_label_peta(): posisi label untuk wilayah yang ingin ditandai.
# Label digeser ke area kosong (laut) dan dihubungkan dengan garis tipis ke titik
# di dalam wilayahnya. Teks label: nama wilayah dan nilainya, mis. "Makassar (9,60)".
#   dat    : sf satu tahun   |   nilai : vektor nilai (sejajar dengan baris dat)
#   pilih  : nama kabupaten yang diberi label
# -----------------------------------------------------------------------------
titik_label_peta <- function(dat, nilai, pilih) {
  idx <- match(pilih, as.character(dat$kabupaten))
  idx <- idx[!is.na(idx)]
  if (length(idx) == 0) return(NULL)
  geom <- sf::st_geometry(dat)[idx]
  # jangkar = titik di dalam poligon terbesar (kota punya banyak pulau kecil)
  jangkar <- t(vapply(seq_along(geom), function(i) {
    bagian <- suppressWarnings(sf::st_cast(geom[i], "POLYGON"))
    besar  <- bagian[which.max(as.numeric(sf::st_area(bagian)))]
    as.numeric(sf::st_coordinates(suppressWarnings(sf::st_point_on_surface(besar)))[1, 1:2])
  }, numeric(2)))
  lab <- data.frame(kabupaten = as.character(dat$kabupaten)[idx],
                    x = jangkar[, 1], y = jangkar[, 2], nilai = nilai[idx])
  lab$teks <- paste0(lab$kabupaten, " (", koma(lab$nilai), ")")
  
  # pergeseran label (derajat bujur/lintang) untuk kota di pesisir
  geser <- data.frame(kabupaten = c("Makassar", "Parepare", "Palopo"),
                      dx = c(-1.10, -1.15, 0.95),
                      dy = c(-0.25,  0.00, -0.25))
  lab <- merge(lab, geser, by = "kabupaten", all.x = TRUE, sort = FALSE)
  # wilayah lain: label di sisi barat (laut Selat Makassar) bila wilayahnya di
  # separuh barat, atau di sisi timur (Teluk Bone) bila di separuh timur
  oto <- is.na(lab$dx)
  lab$dx[oto] <- ifelse(lab$x[oto] < 120.4, -1.15, 0.95)
  lab$dy[is.na(lab$dy)] <- 0
  lab$xl <- lab$x + lab$dx
  lab$yl <- lab$y + lab$dy
  lab
}

# -----------------------------------------------------------------------------
# plot_peta(): peta koroplet satu indikator, satu tahun
#
# Argumen
#   data        objek sf (data_bersih.rds), memuat kabupaten, tahun, kode_wilayah
#   indikator   NAMA KOLOM tanpa tanda kutip, mis. indikator = tpt
#   tahun       satu tahun yang digambar
#   tipe        "kelas" (bawaan; warna per kelas) atau "kontinu"
#   n_kelas     jumlah kelas, 3 sampai 7 (hanya untuk tipe = "kelas")
#   metode      "kuantil" (bawaan) atau "sama" (interval sama)
#   label_kota  TRUE = tampilkan label panah pada wilayah terpilih; FALSE = tanpa label
#   label_wilayah  wilayah yang diberi label: "tertinggi_terendah" (bawaan: satu wilayah
#               dengan nilai tertinggi dan satu terendah, sesuai judul peta),
#               "kota" (Makassar, Parepare, Palopo), atau "tiga_tertinggi"
#   simulasi    "normal" (bawaan), "deutan", "protan", atau "tritan":
#               menggambar peta dengan warna hasil simulasi buta warna
#   legenda     posisi legenda: "kanan" (bawaan; kelas disusun ke bawah di kanan
#               peta) atau "bawah" (kelas disusun mendatar di bawah peta)
#   nrow_legenda  jumlah baris legenda kelas; NULL = otomatis (1 baris, atau 2 baris
#               bila kelas lebih dari 4). Naikkan bila label legenda terpotong.
#               Hanya berlaku bila legenda = "bawah".
#   judul_legenda  judul legenda; NULL = otomatis (label indikator tim). Bisa diberi
#               "\n" agar judul turun baris (berguna untuk panel yang sempit).
#   ukuran_legenda  pengali ukuran legenda (kotak warna dan huruf); 1 = ukuran tema tim,
#               0.85 = sedikit lebih kecil (dipakai di gambar uji buta warna)
#   judul, subjudul, caption   NULL = otomatis; NA = tanpa teks; atau teks sendiri
#
# Hasil: objek ggplot (tidak menyimpan berkas; simpan dengan ggsave()).
# -----------------------------------------------------------------------------
plot_peta <- function(data, indikator, tahun,
                      tipe = c("kelas", "kontinu"),
                      n_kelas = 5,
                      metode = c("kuantil", "sama"),
                      label_kota = TRUE,
                      label_wilayah = c("tertinggi_terendah", "kota", "tiga_tertinggi"),
                      simulasi = c("normal", "deutan", "protan", "tritan"),
                      legenda = c("kanan", "bawah"),
                      judul_legenda = NULL,
                      ukuran_legenda = 1,
                      nrow_legenda = NULL,
                      judul = NULL, subjudul = NULL, caption = NULL) {
  tipe     <- match.arg(tipe)
  metode   <- match.arg(metode)
  simulasi <- match.arg(simulasi)
  label_wilayah <- match.arg(label_wilayah)
  legenda  <- match.arg(legenda)
  
  # 0. Prasyarat: tema dan palet tim
  if (!exists("theme_tim") || !exists("pal_tim") || !exists("scale_fill_peta")) {
    stop("Muat tema tim lebih dulu: source(\"theme_tim/03_theme_tim.R\").", call. = FALSE)
  }
  
  # 1. Nama kolom dari argumen (hanya nama polos)
  q <- rlang::enquo(indikator)
  if (!rlang::quo_is_symbol(q)) {
    stop("indikator harus nama kolom tanpa tanda kutip, mis. indikator = tpt.",
         call. = FALSE)
  }
  nama <- rlang::as_name(q)
  
  # 2. Data: harus sf, kolom lengkap, satu tahun, tiap wilayah sekali
  if (!inherits(data, "sf")) {
    stop("data harus objek sf (data_bersih.rds memuat geometri peta).", call. = FALSE)
  }
  hilang <- setdiff(c(nama, "kabupaten", "tahun"), names(data))
  if (length(hilang) > 0) {
    stop("Kolom tidak ditemukan: ", paste(hilang, collapse = ", "), call. = FALSE)
  }
  dat <- data[data$tahun == tahun, ]
  if (nrow(dat) == 0) stop("Tidak ada data untuk tahun ", tahun, ".", call. = FALSE)
  if (anyDuplicated(dat$kabupaten)) {
    stop("Ada wilayah yang muncul lebih dari sekali pada tahun ", tahun, ".", call. = FALSE)
  }
  
  nilai <- dat[[nama]]
  if (all(is.na(nilai))) stop("Semua nilai ", nama, " kosong pada tahun ", tahun, ".", call. = FALSE)
  if (any(is.na(nilai))) message(sum(is.na(nilai)), " wilayah tanpa data (diberi warna abu terang).")
  
  # 3. Kelas (bila tipe = "kelas")
  if (tipe == "kelas") {
    dat$kelas <- bagi_kelas(nilai, n = n_kelas, metode = metode)
    n_eff <- nlevels(dat$kelas)
  }
  
  # 4. Skala warna: skala tim, atau versi simulasi buta warna
  nama_legend <- if (is.null(judul_legenda)) label_indikator(nama) else judul_legenda
  if (simulasi == "normal") {
    skala <- if (tipe == "kelas") {
      scale_fill_peta("kelas", n = n_eff, name = nama_legend)
    } else {
      scale_fill_peta("kontinu", name = nama_legend)
    }
  } else {
    f_sim <- switch(simulasi,
                    deutan = colorspace::deutan,
                    protan = colorspace::protan,
                    tritan = colorspace::tritan)
    abu <- f_sim(pal_tim[["abu_terang"]])
    skala <- if (tipe == "kelas") {
      ggplot2::scale_fill_manual(values = f_sim(warna_kelas_peta(n_eff)),
                                 name = nama_legend, drop = FALSE, na.value = abu)
    } else {
      ggplot2::scale_fill_gradientn(colours = f_sim(pal_peta),
                                    name = nama_legend, na.value = abu)
    }
  }
  
  # 5. Teks otomatis 
  i_max <- which.max(nilai)
  i_min <- which.min(nilai)

  judul_oto <- paste0(singkat_indikator(nama), " ", tahun, ": Tertinggi di ", dat$kabupaten[i_max],
                      " (", koma(nilai[i_max]), "), Terendah di ", dat$kabupaten[i_min],
                      " (", koma(nilai[i_min]), ")")
  subjudul_oto <- if (tipe == "kelas") {
    paste0(n_eff, " kelas ",
           if (metode == "kuantil") "kuantil (tiap kelas memuat kira-kira jumlah wilayah yang sama)"
           else "dengan interval sama")
  } else {
    "Skala warna kontinu. Semakin gelap, Semakin tinggi."
  }
  caption_oto <- paste0("Sumber: BPS, diolah Tim 6.",
                        if (any(is.na(nilai))) " Abu terang: tidak ada data." else "")
  
  # 6. Gambar: poligon wilayah dengan garis batas abu gelap
  g <- ggplot(dat)
  if (tipe == "kelas") {
    g <- g + geom_sf(aes(fill = kelas), color = pal_tim[["tepi"]], linewidth = 0.3)
  } else {
    g <- g + geom_sf(aes(fill = {{ indikator }}), color = pal_tim[["tepi"]], linewidth = 0.3)
  }
  g <- g + skala
  
  # label wilayah terpilih: garis penghubung, titik jangkar, lalu kotak label putih
  if (label_kota) {
    pilih <- switch(
      label_wilayah,
      tertinggi_terendah = unique(as.character(dat$kabupaten[c(i_max, i_min)])),
      kota = if ("kode_wilayah" %in% names(dat)) {
        as.character(dat$kabupaten[as.character(dat$kode_wilayah) %in% c("7371", "7372", "7373")])
      } else {
        character(0)
      },
      tiga_tertinggi = as.character(dat$kabupaten[
        order(nilai, decreasing = TRUE)[seq_len(min(3, sum(!is.na(nilai))))]])
    )
    lab <- titik_label_peta(dat, nilai, pilih)
    if (!is.null(lab)) {
      g <- g +
        geom_segment(data = lab, aes(x = x, y = y, xend = xl, yend = yl),
                     inherit.aes = FALSE, color = pal_tim[["tepi"]], linewidth = 0.3) +
        geom_point(data = lab, aes(x = x, y = y), inherit.aes = FALSE,
                   color = pal_tim[["tepi"]], size = 0.9) +
        geom_label(data = lab, aes(x = xl, y = yl, label = teks),
                   inherit.aes = FALSE, fill = "white", color = pal_tim[["teks"]],
                   size = 3, fontface = "bold")
    }
  }
  
  # Ukuran kotak warna legenda: bila legenda di kanan, kotak kecil dan disusun ke
  # bawah (satu kolom); bila di bawah, kotak memanjang dan disusun mendatar.
  kanan        <- legenda == "kanan"
  lebar_kunci  <- if (kanan) 1.8 else if (tipe == "kelas") 2.4 else 12
  tinggi_kunci <- if (kanan) { if (tipe == "kelas") 1.3 else 9 } else 0.9
  # huruf legenda ikut diskalakan hanya bila ukuran_legenda bukan 1
  # (9,35 dan 9,9 pt = ukuran tema tim untuk base_size 11)
  tema_legenda <- if (ukuran_legenda != 1) {
    theme(legend.text  = element_text(size = 9.35 * ukuran_legenda, color = pal_tim[["teks"]]),
          legend.title = element_text(size = 9.9 * ukuran_legenda, face = "bold",
                                      color = pal_tim[["teks"]]))
  } else {
    theme()
  }
  g +
    guides(fill = if (tipe == "kelas") {
      if (kanan) {
        guide_legend(ncol = 1)
      } else {
        guide_legend(nrow = if (!is.null(nrow_legenda)) nrow_legenda else if (n_eff > 4) 2 else 1,
                     byrow = TRUE)
      }
    } else {
      guide_colourbar()
    }) +
    labs(title    = atur_teks(judul, judul_oto),
         subtitle = atur_teks(subjudul, subjudul_oto),
         caption  = atur_teks(caption, caption_oto),
         x = NULL, y = NULL) +
    theme_tim(grid = "none", legend = if (kanan) "right" else "bottom") +
    theme(axis.text  = element_blank(),
          axis.title = element_blank(),
          legend.title.position = "top",
          legend.key.width  = grid::unit(lebar_kunci * ukuran_legenda, "lines"),
          legend.key.height = grid::unit(tinggi_kunci * ukuran_legenda, "lines")) +
    tema_legenda
}

# =============================================================================
# D. UJI BUTA WARNA
# =============================================================================

# -----------------------------------------------------------------------------
# cek_palet_peta(): uji angka. Peta sekuensial dibaca lewat tingkat terang, jadi
# yang diuji: apakah urutan terang ke gelap antarkelas tetap terjaga, dan seberapa
# besar selisih terang (L*) terkecil antara dua kelas bersebelahan, pada tiap
# simulasi. Kriteria tim: urutan tetap menurun dan selisih terkecil >= ambang.
#   n_kelas : jumlah kelas peta   |   warna : vektor warna sendiri (mis. pal_peta)
# -----------------------------------------------------------------------------
cek_palet_peta <- function(n_kelas = 5, warna = NULL, ambang = 4) {
  if (is.null(warna)) warna <- warna_kelas_peta(n_kelas)
  kond <- list(
    "Normal"       = warna,
    "Deuteranopia" = colorspace::deutan(warna),
    "Protanopia"   = colorspace::protan(warna),
    "Tritanopia"   = colorspace::tritan(warna),
    "Grayscale"    = colorspace::desaturate(warna, 1)
  )
  terang <- function(hex) {
    as.numeric(colorspace::coords(methods::as(colorspace::hex2RGB(hex), "LAB"))[, "L"])
  }
  hasil <- do.call(rbind, lapply(names(kond), function(k) {
    sel <- diff(terang(kond[[k]]))
    data.frame(kondisi = k,
               urutan_terjaga = all(sel < 0),
               selisih_L_terkecil = round(min(abs(sel)), 1),
               lolos = all(sel < 0) && min(abs(sel)) >= ambang)
  }))
  cat("\nUji palet peta (", length(warna), " warna; ambang selisih L* = ", ambang, ")\n", sep = "")
  print(hasil, row.names = FALSE)
  wajib <- hasil$lolos[hasil$kondisi %in% c("Deuteranopia", "Protanopia")]
  cat("\nHasil untuk syarat tugas (deuteranopia dan protanopia): ",
      if (all(wajib)) "LOLOS" else "TIDAK LOLOS", "\n", sep = "")
  invisible(hasil)
}

# -----------------------------------------------------------------------------
# uji_buta_warna_peta()
# -----------------------------------------------------------------------------
uji_buta_warna_peta <- function(data, indikator, tahun,
                                tipe = c("kelas", "kontinu"),
                                n_kelas = 5,
                                metode = c("kuantil", "sama")) {
  tipe   <- match.arg(tipe)
  metode <- match.arg(metode)
  nama   <- rlang::as_name(rlang::enquo(indikator))
  
  gaya   <- theme(plot.title = element_text(size = 12, color = pal_tim[["teks"]],
                                            margin = margin(b = 10)),
                  plot.margin = margin(t = 6, r = 18, b = 6, l = 6),
                  legend.box.spacing = grid::unit(1, "lines"))
  # judul legenda dipecah 2 baris agar peta di tiap panel tetap besar
  jl     <- paste(strwrap(label_indikator(nama), width = 20), collapse = "\n")
  
  p1 <- plot_peta(data, {{ indikator }}, tahun = tahun, tipe = tipe, n_kelas = n_kelas,
                  metode = metode, label_kota = FALSE, simulasi = "normal", legenda = "kanan", judul_legenda = jl, ukuran_legenda = 0.85,
                  judul = "Penglihatan normal", subjudul = NA, caption = NA) + gaya
  p2 <- plot_peta(data, {{ indikator }}, tahun = tahun, tipe = tipe, n_kelas = n_kelas,
                  metode = metode, label_kota = FALSE, simulasi = "deutan", legenda = "kanan", judul_legenda = jl, ukuran_legenda = 0.85,
                  judul = "Deuteranopia (simulasi)", subjudul = NA, caption = NA) + gaya
  p3 <- plot_peta(data, {{ indikator }}, tahun = tahun, tipe = tipe, n_kelas = n_kelas,
                  metode = metode, label_kota = FALSE, simulasi = "protan", legenda = "kanan", judul_legenda = jl, ukuran_legenda = 0.85,
                  judul = "Protanopia (simulasi)", subjudul = NA, caption = NA) + gaya
  
  patchwork::wrap_plots(p1, p2, p3, nrow = 1) +
    patchwork::plot_annotation(
      title   = paste0("Uji Buta Warna: Peta ", singkat_indikator(nama), " ", tahun),
      caption = paste0("Simulasi dengan colorspace::deutan() dan colorspace::protan(). ",
                       "Urutan kelas dari terang ke gelap harus tetap terbaca."),
      theme   = theme(plot.title   = element_text(face = "bold", size = 16,
                                                  color = pal_tim[["judul"]],
                                                  margin = margin(b = 10)),
                      plot.caption = element_text(size = 9, color = pal_tim[["teks"]],
                                                  hjust = 0, margin = margin(t = 14)),
                      plot.margin  = margin(10, 12, 10, 12)))
}

# =============================================================================
# E. PEMAKAIAN
# =============================================================================

# E1. Peta utama: TPT 2025, 5 kelas kuantil
peta_tpt_2025 <- plot_peta(d, indikator = tpt, tahun = 2025)
print(peta_tpt_2025)

# Batas kelas dan jumlah wilayah per kelas (catatan untuk atlas)
d2025 <- d[d$tahun == 2025, ]
cat("\nJumlah wilayah per kelas, TPT 2025:\n")
print(table(bagi_kelas(d2025$tpt, n = 5, metode = "kuantil")))

#-------------------------------------------------------------------------------
# DEMO

# plot_peta(d, indikator = rls, tahun = 2025)
# plot_peta(d, indikator = tpt, tahun = 2023)
# plot_peta(d, indikator = tpt, tahun = 2025, tipe = "kontinu")
# plot_peta(d, indikator = tpt, tahun = 2025, n_kelas = 4, metode = "sama")
# plot_peta(d, indikator = tpt, tahun = 2025, label_kota = FALSE)
# plot_peta(d, indikator = tpt, tahun = 2025, label_wilayah = "kota")
# plot_peta(d, indikator = tpt, tahun = 2025, label_wilayah = "tiga_tertinggi")
#-------------------------------------------------------------------------------

# E2. Uji buta warna: tabel angka + peta dalam 3 tampilan
cek_palet_peta(n_kelas = 5)
uji_peta <- uji_buta_warna_peta(d, indikator = tpt, tahun = 2025)
print(uji_peta)

# E3. Simpan gambar ke keluaran/peta/ 
simpan_gambar <- TRUE
if (simpan_gambar) {
  dir_peta <- file.path(dir_repo, "keluaran", "peta")
  dir.create(dir_peta, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(dir_peta, "peta_tpt_2025.png"), peta_tpt_2025,
         width = 9, height = 8, dpi = 300, bg = "white")   # untuk legenda = "bawah": width = 7, height = 9
  ggsave(file.path(dir_peta, "uji_buta_warna_peta_tpt_2025.png"), uji_peta,
         width = 15, height = 6.5, dpi = 300, bg = "white")   # 3 peta, legenda di kanan tiap peta
  message("Gambar peta tersimpan di: ", rel(dir_peta))
}
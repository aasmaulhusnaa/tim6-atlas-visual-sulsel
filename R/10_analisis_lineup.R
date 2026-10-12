# analisis_lineup.R
# =============================================================================
# Hari 10-11: analisis hasil lineup (p-value visual)
#
# Alur: baca jawaban pengamat -> bersihkan -> buang anggota Tim 6 -> hitung n dan k
#       -> p-value visual (binomial) -> gambar -> ringkasan tertulis untuk atlas.
#
# Memakai : jawaban_pengamat.csv  (ekspor Google Form)
#           kunci_lineup.txt      (nomor panel asli, dari skrip lineup)
#           03_theme_tim.R        (pal_tim, theme_tim)
# Keluaran: data-lineup/jawaban_pengamat_anonim.csv   (tanpa nama; aman untuk GitHub)
#           keluaran/lineup/hasil_lineup.png          (gambar)
#           keluaran/lineup/ringkasan_hasil_lineup.txt (teks untuk atlas)
#
# CARA MENJALANKAN: buka repositori lewat file .Rproj, lalu jalankan seluruh skrip.
# Berkas dicari otomatis berdasarkan nama di seluruh folder repositori.
# =============================================================================

# =============================================================================
# A. PENGATURAN
# =============================================================================
# Jika kunci tidak terbaca otomatis dari kunci_lineup.txt, isi nomornya di sini
# (angka 1-20), mis. panel_asli_manual <- 2. Biarkan NULL bila ingin dibaca otomatis.
panel_asli_manual <- NULL

jumlah_panel <- 20          # lineup: 1 panel asli + 19 panel acak
min_pengamat <- 10          # syarat lembar tugas
alpha        <- 0.05        # taraf signifikansi

# ---- mencari folder repositori --------------------------------------------
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
  if (!is.null(of) && nzchar(of)) return(normalizePath(dirname(of), winslash = "/", mustWork = FALSE))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
    if (!is.null(p) && nzchar(p)) return(normalizePath(dirname(p), winslash = "/", mustWork = FALSE))
  }
  NA_character_
}
dir_repo <- cari_dir_repo()
if (is.na(dir_repo)) {
  ls_skrip <- lokasi_skrip()
  if (!is.na(ls_skrip)) dir_repo <- cari_dir_repo(ls_skrip)
}
if (is.na(dir_repo)) {
  stop("Folder repositori tidak ditemukan. Buka repositori sebagai RStudio Project ",
       "(File > New Project > Existing Directory) lalu jalankan ulang.", call. = FALSE)
}
jalur_rel <- function(p) substring(p, nchar(dir_repo) + 2)
cat("Repositori:", basename(dir_repo), "\n")

# lokasi baku dulu; bila tidak ada, cari berdasarkan NAMA berkas di seluruh repositori
cari_berkas <- function(kandidat) {
  ada <- kandidat[file.exists(file.path(dir_repo, kandidat))]
  if (length(ada) > 0) return(file.path(dir_repo, ada[1]))
  for (nama in unique(basename(kandidat))) {
    pola   <- paste0("^", gsub(".", "\\.", nama, fixed = TRUE), "$")
    ketemu <- list.files(dir_repo, pattern = pola, recursive = TRUE, full.names = TRUE)
    ketemu <- ketemu[!grepl("/(keluaran|\\.git|\\.Rproj\\.user)/", ketemu)]
    if (length(ketemu) > 0) {
      ketemu <- ketemu[order(nchar(ketemu))]
      message(nama, " dipakai dari: ", jalur_rel(ketemu[1]),
              if (length(ketemu) > 1) paste0("  (ada ", length(ketemu), " salinan; dipakai yang jalurnya terpendek)") else "")
      return(ketemu[1])
    }
  }
  stop("Berkas tidak ditemukan: ", paste(kandidat, collapse = " / "), call. = FALSE)
}

library(ggplot2)
source(cari_berkas(c("R/03_theme_tim.R", "theme_tim/03_theme_tim.R", "R/theme_tim.R")))

# =============================================================================
# B. BACA DAN BERSIHKAN JAWABAN
# =============================================================================
berkas_csv <- cari_berkas(c("data-lineup/jawaban_pengamat.csv", "jawaban_pengamat.csv"))
mentah <- read.csv(berkas_csv, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE,
                   check.names = FALSE, header = TRUE)

# Ekspor Google Form sering membawa kolom kosong di kanan dan baris kosong di bawah
mentah <- mentah[, 1:5, drop = FALSE]
names(mentah) <- c("waktu", "nama", "asal_tim", "panel_teks", "alasan")
mentah <- mentah[nzchar(trimws(mentah$panel_teks)), , drop = FALSE]
cat("Jawaban terbaca dari berkas:", nrow(mentah), "\n")

mentah$nama     <- trimws(gsub("\\s+", " ", mentah$nama))
mentah$asal_tim <- trimws(mentah$asal_tim)
mentah$panel    <- suppressWarnings(as.integer(gsub("\\D", "", mentah$panel_teks)))
stopifnot("Ada jawaban yang nomor panelnya tidak terbaca" = !anyNA(mentah$panel),
          "Ada nomor panel di luar 1-20" = all(mentah$panel %in% seq_len(jumlah_panel)))

# Aturan penyaringan (tulis juga di atlas):
#  1) jawaban anggota Tim 6 (pembuat lineup) dibuang
#  2) bila satu nama mengisi lebih dari sekali, hanya jawaban PERTAMA yang dipakai
tim_pembuat <- grepl("(^|[^0-9])6([^0-9]|$)|pembuat", mentah$asal_tim, ignore.case = TRUE)
ganda       <- duplicated(tolower(mentah$nama))
cat("Dibuang karena anggota Tim 6 :", sum(tim_pembuat), "\n")
cat("Dibuang karena isian ganda   :", sum(ganda & !tim_pembuat), "\n")
sah <- mentah[!tim_pembuat & !ganda, , drop = FALSE]
n   <- nrow(sah)
cat("Pengamat sah (n)             :", n, "\n")
if (n < min_pengamat) {
  warning("Pengamat sah kurang dari ", min_pengamat, " (syarat lembar tugas).", call. = FALSE)
}

# =============================================================================
# C. KUNCI JAWABAN DAN PERHITUNGAN
# =============================================================================
panel_asli <- panel_asli_manual
if (is.null(panel_asli)) {
  berkas_kunci <- cari_berkas(c("kunci_lineup.txt", "berkas_lineup/kunci_lineup.txt"))
  # menerima "Panel asli : 2" maupun "panel_asli : 2" (huruf besar/kecil, spasi atau garis bawah)
  baris <- grep("^\\s*panel[ _]asli", readLines(berkas_kunci, warn = FALSE),
                value = TRUE, ignore.case = TRUE)
  panel_asli <- suppressWarnings(as.integer(sub(".*:\\s*", "", baris[1])))
}
if (is.na(panel_asli) || !panel_asli %in% seq_len(jumlah_panel)) {
  stop("Nomor panel asli tidak terbaca. Isi `panel_asli_manual` di bagian A.", call. = FALSE)
}

sah$benar <- sah$panel == panel_asli
k <- sum(sah$benar)
peluang <- 1 / jumlah_panel
p_visual <- if (k <= 0) 1 else 1 - pbinom(k - 1, n, peluang)   # P(X >= k), X ~ Binomial(n, 1/20)
harapan  <- n * peluang                                         # k yang diharapkan bila hanya menebak

koma <- function(x, d = 3) format(round(x, d), nsmall = d, decimal.mark = ",")
p_teks <- if (p_visual < 0.001) "< 0,001" else paste0("= ", koma(p_visual))

# teks p-value untuk subjudul grafik: tampilkan angka eksaknya (notasi ilmiah bila
# sangat kecil) bersama keterangan "< 0,001", supaya pembaca bisa memeriksanya
p_sub <- if (p_visual >= 0.001) {
  paste0("= ", koma(p_visual))
} else {
  paste0("= ", sub(".", ",", format(p_visual, scientific = TRUE, digits = 3), fixed = TRUE),
         " (< 0,001)")
}

cat("\n--- HASIL ---------------------------------------------------\n")
cat("Panel asli (kunci)        :", panel_asli, "\n")
cat("n (pengamat sah)          :", n, "\n")
cat("k (memilih panel asli)    : ", k, " (", round(100 * k / n), "%)\n", sep = "")
cat("Harapan bila hanya menebak:", koma(harapan, 2), "orang\n")
cat("p-value visual            : P(X >= ", k, ") ", p_teks, "  [eksak: ",
    format(p_visual, scientific = TRUE, digits = 3), "]\n", sep = "")
cat("Keputusan (alpha ", format(alpha, decimal.mark = ","), ")     : ", if (p_visual < alpha) "SIGNIFIKAN" else "TIDAK SIGNIFIKAN", "\n", sep = "")

# Uji ketahanan: apakah kesimpulan bertahan bila 1-2 jawaban benar dikeluarkan?
# (mis. karena alasannya tidak cocok dengan gambar). Hanya untuk pemeriksaan.
if (k >= 2) {
  keluar <- 0:min(2, k - 1)
  tahan <- data.frame(dikeluarkan = keluar, n = n - keluar, k = k - keluar)
  tahan$p_visual <- ifelse(tahan$k <= 0, 1, 1 - pbinom(tahan$k - 1, tahan$n, peluang))
  tahan$p_visual <- format(tahan$p_visual, scientific = TRUE, digits = 3)
  cat("\nUji ketahanan (jawaban benar yang dikeluarkan):\n")
  print(tahan, row.names = FALSE)
}

pilihan <- table(factor(sah$panel, levels = seq_len(jumlah_panel)))
cat("\nPilihan pengamat per panel (hanya yang dipilih):\n")
print(pilihan[pilihan > 0])

# alasan: penghitungan kata kunci sederhana (indikatif, bukan analisis isi yang ketat)
a <- tolower(sah$alasan)
alasan_tab <- c(
  "menyebut kemiringan/kecuraman garis regresi" = sum(grepl("miring|curam|tajam|menanjak|naik|tren|regresi", a)),
  "menyebut titik kota"                         = sum(grepl("kota", a)),
  "menyebut pita (selang) yang sempit"          = sum(grepl("pita", a))
)
cat("\nAlasan yang disebut (pencarian kata kunci, satu jawaban bisa masuk lebih dari satu):\n")
print(alasan_tab)

# =============================================================================
# D. GAMBAR: pilihan pengamat per panel
# =============================================================================
g <- data.frame(panel = seq_len(jumlah_panel), jumlah = as.integer(pilihan))
g$jenis   <- factor(ifelse(g$panel == panel_asli, "Panel asli", "Panel acak"),
                    levels = c("Panel acak", "Panel asli"))
g$panel_f <- factor(g$panel, levels = seq_len(jumlah_panel))   # semua 20 nomor panel tampil

judul_g <- paste0(k, " dari ", n, " pengamat memilih panel asli (panel ", panel_asli, ")")
sub_g   <- paste0("p-value visual ", p_sub, ". Bila hanya menebak, diharapkan sekitar ",
                  koma(harapan, 1), " orang per panel.")

# Garis tepi batang memakai warna tepi tema tim (abu gelap). Batang kosong (0 pengamat)
# tidak digambar, supaya tidak muncul garis gelap di dasar grafik. Untuk mengganti
# warna garis tepi, ubah nilai di bawah (mis. pal_tim[["garis_utama"]]).
warna_tepi_batang <- pal_tim[["tepi"]]

grafik <- ggplot(g, aes(x = panel_f, y = jumlah, fill = jenis)) +
  geom_col(data = g[g$jumlah > 0, ], width = 0.75,
           color = warna_tepi_batang, linewidth = 0.3) +
  geom_hline(yintercept = harapan, linetype = "dashed", color = pal_tim[["tepi"]]) +
  geom_text(aes(label = ifelse(jumlah > 0, jumlah, "")), vjust = -0.5, size = 3.4,
            color = pal_tim[["teks"]]) +
  scale_fill_manual(values = c("Panel asli" = pal_tim[["garis_utama"]],
                               "Panel acak" = pal_tim[["abu_terang"]]),
                    limits = c("Panel acak", "Panel asli"), drop = FALSE, name = NULL) +
  scale_x_discrete(drop = FALSE) +
  scale_y_continuous(breaks = seq(0, n, by = 2), limits = c(0, n + 1), expand = c(0, 0)) +
  labs(title = judul_g, subtitle = sub_g,
       x = "Nomor panel", y = "Jumlah pengamat yang memilih",
       caption = paste0("Garis putus-putus: harapan bila hanya menebak (n/", jumlah_panel,
                        "). Jumlah Pengamat: n = ", n, ".\nSumber: Data Jawaban Pengamat, diolah Tim 6.")) +
  theme_tim(grid = "y", legend = "top")
print(grafik)

# =============================================================================
# E. SIMPAN GAMBAR
# =============================================================================
dir_gambar <- file.path(dir_repo, "keluaran", "lineup")
dir_data   <- file.path(dir_repo, "data-lineup")
dir.create(dir_gambar, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_data,   recursive = TRUE, showWarnings = FALSE)

ggsave(file.path(dir_gambar, "hasil_lineup.png"), grafik,
       width = 10, height = 5.5, dpi = 300, bg = "white")

# Kalimat laporan untuk atlas
kalimat <- paste0(
  "Dari ", n, " pengamat, ", k, " memilih panel asli (", round(100 * k / n), "%). ",
  "Dengan peluang tebakan 1/", jumlah_panel, " per orang, p-value visual ", p_teks, ". ",
  if (p_visual < alpha)
    paste0("Pola pada data asli tampak berbeda dari panel acak pada taraf ", 100 * alpha, "%.")
  else
    "Tidak cukup bukti bahwa pola pada data asli terlihat berbeda dari data acak."
)

# Simpan ringkasan ke berkas teks
writeLines(c(
  "RINGKASAN HASIL LINEUP",
  paste0("Panel asli: ", panel_asli, " | n = ", n, " | k = ", k,
         " | p-value visual = ", format(p_visual, scientific = TRUE, digits = 3)),
  paste0("Dibuang: ", sum(tim_pembuat), " jawaban Tim 6, ",
         sum(ganda & !tim_pembuat), " isian ganda."),
  "", kalimat), file.path(dir_gambar, "ringkasan_hasil_lineup.txt"))


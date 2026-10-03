library(tidyverse)
library(readxl)
library(sf)

# ==== 1. Menentukan Jalur folder ========================================================
folder_proyek <- "D:/magister/SEMESTER 1/KOMPUTASI STATISTIKA LANJUT/tim6-atlas-visual-sulsel"
dir_mentah    <- file.path(folder_proyek, "data-mentah")
dir_kode      <- file.path(folder_proyek, "data-kode-wilayah")
dir_peta      <- file.path(folder_proyek, "data-batas-peta")
dir_bersih    <- file.path(folder_proyek, "data-bersih")
dir.create(dir_bersih, showWarnings = FALSE)    # Membuat Folder Data Bersih

# ==== 2. TPT dan RLS: baca semua tahun =======================================
# Baris 1-3 file BPS hanya judul dan tahun, data mulai baris 4.
baca_indikator <- function(berkas, nama_indikator) {
  read_excel(berkas,
             skip = 3,
             col_names = c("wilayah", nama_indikator),
             col_types = "text") |>
    mutate(
      wilayah = str_squish(wilayah),
      across(all_of(nama_indikator), as.numeric),
      tahun = as.integer(str_extract(basename(berkas), "\\d{4}"))
    ) |>
    filter(!is.na(wilayah),
           str_to_lower(wilayah) != "sulawesi selatan")   # buang baris provinsi
}

tpt <- list.files(dir_mentah, pattern = "^TPT_\\d{4}\\.xlsx$",
                  full.names = TRUE, ignore.case = TRUE) |>
  map_dfr(baca_indikator, nama_indikator = "tpt")

rls <- list.files(dir_mentah, pattern = "^RLS_\\d{4}\\.xlsx$",
                  full.names = TRUE, ignore.case = TRUE) |>
  map_dfr(baca_indikator, nama_indikator = "rls")

# ==== 3. Menyamakan nama Wilayah dengan Tabel Kode Wilayah ======================
nama_baku <- c(
  "Pangkep"   = "Pangkajene dan Kepulauan",
  "Sidrap"    = "Sindereng Rappang",
  "Pare Pare" = "Parepare"
)
tpt <- tpt |> mutate(wilayah = recode(wilayah, !!!nama_baku))
rls <- rls |> mutate(wilayah = recode(wilayah, !!!nama_baku))

# ==== 4. Kode wilayah: 73.0799999 -> "7308" ==================================
kode <- read_excel(file.path(dir_kode, "kode_wilayah.xlsx"),
                   col_types = "text") |>
  rename(wilayah = 1, kode_asal = 2) |>
  mutate(
    wilayah      = str_squish(wilayah),
    kode_wilayah = sprintf("%04d", as.integer(round(as.numeric(kode_asal) * 100)))
  ) |>
  select(kode_wilayah, wilayah)

# ==== 5. Gabungkan TPT + RLS + kode (tabel sementara, tidak disimpan) ========
data_tabel <- tpt |>
  inner_join(rls, by = c("wilayah", "tahun")) |>
  left_join(kode, by = "wilayah") |>
  rename(kabupaten = wilayah) |>
  select(kode_wilayah, kabupaten, tahun, tpt, rls) |>
  arrange(kode_wilayah, tahun)

cat("Wilayah:", n_distinct(data_tabel$kabupaten), "(harus 24) | ",
    "Baris:", nrow(data_tabel), "(harus 72)\n")
stopifnot(
  n_distinct(data_tabel$kabupaten) == 24,
  nrow(data_tabel) == 24 * n_distinct(data_tabel$tahun),
  !anyNA(data_tabel$kode_wilayah),
  !anyNA(data_tabel$tpt),
  !anyNA(data_tabel$rls)
)

# ==== 6. Peta: Membaca Peta dan Menyaring ke Sulsel =====================================
peta_asli <- st_read(
  file.path(dir_peta, "geoBoundaries-IDN-ADM2_simplified.geojson"),
  quiet = TRUE
)

# Penyeragam nama: huruf kecil, tanpa awalan "Kota/Kabupaten", tanpa spasi
alias <- c(
  "sidenrengrappang"    = "sinderengrappang",
  "sidrap"              = "sinderengrappang",
  "pangkajenekepulauan" = "pangkajenedankepulauan",
  "pangkep"             = "pangkajenedankepulauan",
  "selayar"             = "kepulauanselayar",
  "eastluwu"            = "luwutimur",
  "northluwu"           = "luwuutara",
  "northtoraja"         = "torajautara"
)
buat_kunci <- function(x) {
  x |>
    str_to_lower() |>
    str_remove("^(kota|kabupaten|kab\\.?)\\s+") |>
    str_remove_all("[^a-z]") |>
    recode(!!!alias)
}

# Penyaringan kasar dengan kotak koordinat Sulsel
titik <- st_coordinates(suppressWarnings(st_centroid(st_geometry(peta_asli))))
calon <- peta_asli |>
  mutate(kunci = buat_kunci(shapeName)) |>
  filter(titik[, 1] > 118.5, titik[, 1] < 122.5,
         titik[, 2] > -8.2,  titik[, 2] < -2.3)

daftar_data <- data_tabel |>
  distinct(kode_wilayah, kabupaten) |>
  mutate(kunci = buat_kunci(kabupaten))

hilang <- setdiff(daftar_data$kunci, calon$kunci)
if (length(hilang) > 0) {
  cat("\nTIDAK COCOK dengan peta:\n")
  print(daftar_data |> filter(kunci %in% hilang) |> pull(kabupaten))
  cat("\nNama poligon kandidat di peta (kirim daftar ini ke saya):\n")
  print(sort(calon$shapeName))
  stop("Ada wilayah yang belum cocok. Tambahkan ke 'alias' di bagian 6.")
}

peta_sulsel <- calon |>
  inner_join(daftar_data, by = "kunci") |>
  select(kode_wilayah, geometry) |>
  st_make_valid() |>
  arrange(kode_wilayah)

cat("Poligon:", nrow(peta_sulsel), "(harus 24) | Valid:",
    all(st_is_valid(peta_sulsel)), "\n")
stopifnot(nrow(peta_sulsel) == 24,
          n_distinct(peta_sulsel$kode_wilayah) == 24)

# ==== 7. Gabungkan Semuanya (TPT + RLS + Kode Wilayah + Batas Peta) -> data_bersih ===================================
data_bersih <- peta_sulsel |>
  inner_join(data_tabel, by = "kode_wilayah") |>
  select(kode_wilayah, kabupaten, tahun, tpt, rls, geometry) |>
  arrange(kode_wilayah, tahun)

cat("Baris data_bersih:", nrow(data_bersih), "(harus 72)\n")
stopifnot(nrow(data_bersih) == nrow(data_tabel))

# ==== 8. Menyimpan File ==============================================
saveRDS(data_bersih, file.path(dir_bersih, "data_bersih.rds"))
tabel_bersih <- st_drop_geometry(data_bersih)
writexl::write_xlsx(tabel_bersih, file.path(dir_bersih, "data_bersih.xlsx"))
write_csv(tabel_bersih, file.path(dir_bersih, "data_bersih.csv"))
data_bersih

# ==== 9. Cek visual Batas Peta =================================
ggplot(filter(data_bersih, tahun == 2025)) +
  geom_sf(aes(fill = tpt)) +
  labs(title = "Tingkat Pengangguran Terbuka 2025")

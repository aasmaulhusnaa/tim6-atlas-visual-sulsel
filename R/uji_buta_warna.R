library(colorspace)


#__________Uji Palet Peta_________
pal_peta <- c("#eff3ff", "#c6dbef", "#9ecae1", "#6baed6",
              "#4292c6", "#2171b5", "#084594")

# 1. Simulasi buta warna + grayscale
swatchplot(
  Normal    = pal_peta,
  Deutan    = deutan(pal_peta),
  Protan    = protan(pal_peta),
  Tritan    = tritan(pal_peta),
  Grayscale = desaturate(pal_peta, 1)
)

# 2. Cek urutan terang-gelap (harus turun terus agar urutan kelas terbaca)
L <- coords(as(hex2RGB(pal_peta), "polarLUV"))[, "L"]
round(L)
all(diff(L) < 0)   # TRUE = urutan terang ke gelap konsisten

# 3. Lihat tampilannya pada peta contoh, normal vs simulasi
demoplot(pal_peta,         type = "map")
demoplot(deutan(pal_peta), type = "map")
demoplot(protan(pal_peta), type = "map")
library(colorspace)


#__________Uji Palet Tim__________
cols <- c(
  kota        = "#F0E442",
  kabupaten   = "#CC79A7",
  garis_utama = "#D55E00",   # vermilion
  judul       = "#0072B2",   # biru judul
  tepi        = "#4D4D4D",
  abu_terang  = "#D9D9D9",
  titik_2023  = "#F7F7F7"
)

# 1. Simulasi buta warna + grayscale
swatchplot(
  Normal    = cols,
  Deutan    = deutan(cols),
  Protan    = protan(cols),
  Tritan    = tritan(cols),
  Grayscale = desaturate(cols, 1)
)

# 2. Kontras judul biru terhadap latar putih (harus >= 4,5)
contrast_ratio("#0072B2", "#FFFFFF")

# 3. Simpan sebagai bukti uji
dir.create("gambar", showWarnings = FALSE)
png("gambar/uji_palet_tim.png", width = 1600, height = 1000, res = 200)
swatchplot(
  Normal    = cols,
  Deutan    = deutan(cols),
  Protan    = protan(cols),
  Tritan    = tritan(cols),
  Grayscale = desaturate(cols, 1)
)
dev.off()
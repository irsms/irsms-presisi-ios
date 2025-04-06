class LakaModelPetugas {
  final int id;
  final String tanggal;
  final String namaJalan;
  final String pelaksanaTugas;
  // final String petugasPelapor;
  // final int jumlahKorban;
  final String deskripsi;
  final String gambar;
  final String? statusLaporan;
  final String? kategori;

  LakaModelPetugas({
    required this.id,
    required this.tanggal,
    required this.namaJalan,
    required this.pelaksanaTugas,
    // required this.petugasPelapor,
    // required this.jumlahKorban,
    required this.deskripsi,
    required this.gambar,
    this.statusLaporan,
    this.kategori,
  });
}

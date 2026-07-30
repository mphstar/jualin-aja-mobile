/// Model data Sesi Shift Kasir (Buka Kasir & Tutup Kasir).
class SesiKasir {
  const SesiKasir({
    required this.id,
    required this.namaKasir,
    required this.waktuBuka,
    this.waktuTutup,
    this.kasAwalTunai = 0,
    this.kasAwalQris = 0,
    this.kasAwalTransfer = 0,
    this.totalTunai = 0,
    this.totalQris = 0,
    this.totalTransfer = 0,
    this.jumlahTransaksi = 0,
    this.kasFisikTunai,
    this.kasFisikQris,
    this.kasFisikTransfer,
    this.catatan,
  });

  final String id;
  final String namaKasir;
  final DateTime waktuBuka;
  final DateTime? waktuTutup;

  /// Kas/Saldo Awal
  final int kasAwalTunai;
  final int kasAwalQris;
  final int kasAwalTransfer;

  /// Omzet Penjualan Terkumpul Selama Shift
  final int totalTunai;
  final int totalQris;
  final int totalTransfer;
  final int jumlahTransaksi;

  /// Kas Fisik/Aktual yang Dihitung Kasir Saat Tutup Kasir
  final int? kasFisikTunai;
  final int? kasFisikQris;
  final int? kasFisikTransfer;
  final String? catatan;

  bool get isOpen => waktuTutup == null;

  int get totalKasAwal => kasAwalTunai + kasAwalQris + kasAwalTransfer;
  int get totalPenjualan => totalTunai + totalQris + totalTransfer;

  int get ekspektasiTunai => kasAwalTunai + totalTunai;
  int get ekspektasiQris => kasAwalQris + totalQris;
  int get ekspektasiTransfer => kasAwalTransfer + totalTransfer;
  int get totalEkspektasi =>
      ekspektasiTunai + ekspektasiQris + ekspektasiTransfer;

  int get totalKasFisik =>
      (kasFisikTunai ?? ekspektasiTunai) +
      (kasFisikQris ?? ekspektasiQris) +
      (kasFisikTransfer ?? ekspektasiTransfer);

  int get selisihTunai => (kasFisikTunai ?? ekspektasiTunai) - ekspektasiTunai;
  int get selisihQris => (kasFisikQris ?? ekspektasiQris) - ekspektasiQris;
  int get selisihTransfer =>
      (kasFisikTransfer ?? ekspektasiTransfer) - ekspektasiTransfer;
  int get totalSelisih => selisihTunai + selisihQris + selisihTransfer;

  SesiKasir copyWith({
    String? namaKasir,
    DateTime? waktuTutup,
    int? kasAwalTunai,
    int? kasAwalQris,
    int? kasAwalTransfer,
    int? totalTunai,
    int? totalQris,
    int? totalTransfer,
    int? jumlahTransaksi,
    int? kasFisikTunai,
    int? kasFisikQris,
    int? kasFisikTransfer,
    String? catatan,
  }) {
    return SesiKasir(
      id: id,
      namaKasir: namaKasir ?? this.namaKasir,
      waktuBuka: waktuBuka,
      waktuTutup: waktuTutup ?? this.waktuTutup,
      kasAwalTunai: kasAwalTunai ?? this.kasAwalTunai,
      kasAwalQris: kasAwalQris ?? this.kasAwalQris,
      kasAwalTransfer: kasAwalTransfer ?? this.kasAwalTransfer,
      totalTunai: totalTunai ?? this.totalTunai,
      totalQris: totalQris ?? this.totalQris,
      totalTransfer: totalTransfer ?? this.totalTransfer,
      jumlahTransaksi: jumlahTransaksi ?? this.jumlahTransaksi,
      kasFisikTunai: kasFisikTunai ?? this.kasFisikTunai,
      kasFisikQris: kasFisikQris ?? this.kasFisikQris,
      kasFisikTransfer: kasFisikTransfer ?? this.kasFisikTransfer,
      catatan: catatan ?? this.catatan,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'namaKasir': namaKasir,
        'waktuBuka': waktuBuka.toIso8601String(),
        'waktuTutup': waktuTutup?.toIso8601String(),
        'kasAwalTunai': kasAwalTunai,
        'kasAwalQris': kasAwalQris,
        'kasAwalTransfer': kasAwalTransfer,
        'totalTunai': totalTunai,
        'totalQris': totalQris,
        'totalTransfer': totalTransfer,
        'jumlahTransaksi': jumlahTransaksi,
        'kasFisikTunai': kasFisikTunai,
        'kasFisikQris': kasFisikQris,
        'kasFisikTransfer': kasFisikTransfer,
        'catatan': catatan,
      };

  factory SesiKasir.fromJson(Map<String, dynamic> json) => SesiKasir(
        id: json['id'] as String,
        namaKasir: json['namaKasir'] as String? ?? 'Kasir',
        waktuBuka: DateTime.parse(json['waktuBuka'] as String),
        waktuTutup: json['waktuTutup'] != null
            ? DateTime.parse(json['waktuTutup'] as String)
            : null,
        kasAwalTunai: (json['kasAwalTunai'] as num?)?.toInt() ?? 0,
        kasAwalQris: (json['kasAwalQris'] as num?)?.toInt() ?? 0,
        kasAwalTransfer: (json['kasAwalTransfer'] as num?)?.toInt() ?? 0,
        totalTunai: (json['totalTunai'] as num?)?.toInt() ?? 0,
        totalQris: (json['totalQris'] as num?)?.toInt() ?? 0,
        totalTransfer: (json['totalTransfer'] as num?)?.toInt() ?? 0,
        jumlahTransaksi: (json['jumlahTransaksi'] as num?)?.toInt() ?? 0,
        kasFisikTunai: (json['kasFisikTunai'] as num?)?.toInt(),
        kasFisikQris: (json['kasFisikQris'] as num?)?.toInt(),
        kasFisikTransfer: (json['kasFisikTransfer'] as num?)?.toInt(),
        catatan: json['catatan'] as String?,
      );
}

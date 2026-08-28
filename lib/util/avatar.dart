/// URL avatar online yang dibangkitkan dari nama.
///
/// Dipakai sebagai pengganti placeholder inisial: setiap pemiliki mendapat
/// avatar yang konsisten berdasarkan namanya, dan bisa diarahkan ke
/// tampilan laki/perempuan lewat parameter [perempuan].
library;

/// Bangun URL avatar dari nama. Kalau [perempuan] tidak diberikan, gender
/// ditentukan deterministik dari nama (supaya tiap nama tetap konsisten).
String avatarUrl(String nama, {bool? perempuan}) {
  final p = perempuan ?? (nama.codeUnits.fold(0, (a, b) => a + b).isEven);
  final seed = Uri.encodeComponent('${p ? 'f' : 'm'}-$nama');
  return 'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=$seed&size=128';
}

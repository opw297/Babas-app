import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:babas_app/services/quran_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Quran service loads complete surah catalog and full verse details', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final service = QuranService();

    final surahs = await service.fetchSurahs();
    expect(surahs.length, 114);

    final fatihah = await service.fetchSurahDetail(1);
    expect(fatihah.summary.number, 1);
    expect(fatihah.arabicAyahs.length, 7);
    expect(fatihah.transliterationAyahs.length, 7);
    expect(fatihah.translationAyahs.length, 7);

    final baqarah = await service.fetchSurahDetail(2);
    expect(baqarah.summary.number, 2);
    expect(baqarah.arabicAyahs.length, 286);
    expect(baqarah.transliterationAyahs.length, 286);
    expect(baqarah.translationAyahs.length, 286);
  });
}

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_model.dart';

class QuranService {
  static const String _lastReadSurahKey = 'last_read_surah_number';
  static const String _lastReadAyahKey = 'last_read_ayah_number';
  static const String _lastReadNameKey = 'last_read_surah_name';
  static const String _bookmarkedSurahKey = 'bookmarked_surahs';
  static const String _bookmarkedAyahKey = 'bookmarked_ayahs';

  Future<List<QuranSurahSummary>> fetchSurahs() async {
    try {
      final raw = await rootBundle.loadString('assets/data/quran_complete.json');
      final decoded = jsonDecode(raw);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(QuranSurahSummary.fromJson)
            .toList();
      }
    } catch (_) {
      // If the complete dataset is unavailable, return an empty catalog.
    }

    return <QuranSurahSummary>[];
  }

  Future<SurahDetail> fetchSurahDetail(int number) async {
    final summaryList = await fetchSurahs();
    final summary = summaryList.firstWhere(
      (surah) => surah.number == number,
      orElse: () => QuranSurahSummary(
        number: number,
        name: 'Surah $number',
        englishName: 'Surah $number',
        englishNameTranslation: '',
        revelationType: '',
        numberOfAyahs: 0,
      ),
    );

    try {
      final raw = await rootBundle.loadString('assets/data/quran_complete.json');
      final decoded = jsonDecode(raw);
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is List) {
        final surahJson = data.whereType<Map<String, dynamic>>().firstWhere(
          (entry) => _parseInt(entry['number']) == number,
          orElse: () => <String, dynamic>{},
        );

        if (surahJson.isNotEmpty) {
          final ayahs = surahJson['ayahs'] is List ? surahJson['ayahs'] as List : <dynamic>[];
          final arabic = ayahs
              .whereType<Map<String, dynamic>>()
              .map(
                (entry) {
                  final numberInSurah = _parseInt(entry['numberInSurah']);
                  return QuranAyah(
                    number: _parseInt(entry['number']),
                    numberInSurah: numberInSurah > 0 ? numberInSurah : _parseInt(entry['number']),
                    juz: _parseInt(entry['juz']),
                    text: entry['arab']?.toString() ?? '',
                  );
                },
              )
              .toList();

          final translit = ayahs
              .whereType<Map<String, dynamic>>()
              .map(
                (entry) {
                  final numberInSurah = _parseInt(entry['numberInSurah']);
                  return QuranAyah(
                    number: _parseInt(entry['number']),
                    numberInSurah: numberInSurah > 0 ? numberInSurah : _parseInt(entry['number']),
                    juz: _parseInt(entry['juz']),
                    text: entry['latin']?.toString() ?? '',
                  );
                },
              )
              .toList();

          final translation = ayahs
              .whereType<Map<String, dynamic>>()
              .map(
                (entry) {
                  final numberInSurah = _parseInt(entry['numberInSurah']);
                  return QuranAyah(
                    number: _parseInt(entry['number']),
                    numberInSurah: numberInSurah > 0 ? numberInSurah : _parseInt(entry['number']),
                    juz: _parseInt(entry['juz']),
                    text: entry['translation']?.toString() ?? '',
                  );
                },
              )
              .toList();

          return SurahDetail(
            summary: summary,
            arabicAyahs: arabic,
            transliterationAyahs: translit,
            translationAyahs: translation,
          );
        }
      }
    } catch (_) {
      // Keep the surah summary if the detail data cannot be loaded.
    }

    return SurahDetail(
      summary: summary,
      arabicAyahs: const <QuranAyah>[],
      transliterationAyahs: const <QuranAyah>[],
      translationAyahs: const <QuranAyah>[],
    );
  }

  Future<void> saveLastRead(int surahNumber, int ayahNumber, String surahName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadSurahKey, surahNumber);
    await prefs.setInt(_lastReadAyahKey, ayahNumber);
    await prefs.setString(_lastReadNameKey, surahName);
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surahNumber = prefs.getInt(_lastReadSurahKey);
    if (surahNumber == null) {
      return null;
    }
    return <String, dynamic>{
      'surahNumber': surahNumber,
      'ayahNumber': prefs.getInt(_lastReadAyahKey) ?? 1,
      'surahName': prefs.getString(_lastReadNameKey) ?? 'Surah $surahNumber',
    };
  }

  Future<void> toggleSurahBookmark(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarkedSurahKey) ?? <String>[];
    final key = surahNumber.toString();
    if (bookmarks.contains(key)) {
      bookmarks.remove(key);
    } else {
      bookmarks.add(key);
    }
    await prefs.setStringList(_bookmarkedSurahKey, bookmarks);
  }

  Future<bool> isSurahBookmarked(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarkedSurahKey) ?? <String>[];
    return bookmarks.contains(surahNumber.toString());
  }

  Future<Set<int>> getBookmarkedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarkedSurahKey) ?? <String>[];
    return bookmarks.map(int.parse).toSet();
  }

  Future<void> toggleAyahBookmark(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarkedAyahKey) ?? <String>[];
    final key = '$surahNumber:$ayahNumber';
    if (bookmarks.contains(key)) {
      bookmarks.remove(key);
    } else {
      bookmarks.add(key);
    }
    await prefs.setStringList(_bookmarkedAyahKey, bookmarks);
  }

  Future<bool> isAyahBookmarked(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList(_bookmarkedAyahKey) ?? <String>[];
    return bookmarks.contains('$surahNumber:$ayahNumber');
  }

  Future<Set<String>> getBookmarkedAyahs() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_bookmarkedAyahKey) ?? <String>[]).toSet();
  }

  Future<void> dispose() async {}

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

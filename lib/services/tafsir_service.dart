import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tafsir_model.dart';

class TafsirService {
  Future<List<TafsirEntry>> fetchTafsirForSurah(int surahNumber) async {
    try {
      final path = 'assets/data/tafsir_$surahNumber.json';
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(TafsirEntry.fromJson)
            .where((entry) => entry.surahNumber == surahNumber)
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final entries = decoded['data'];
        if (entries is List) {
          return entries
              .whereType<Map<String, dynamic>>()
              .map(TafsirEntry.fromJson)
              .where((entry) => entry.surahNumber == surahNumber)
              .toList();
        }
      }
    } catch (_) {
      // Tafsir dataset belum tersedia; UI akan menampilkan placeholder yang aman.
    }

    return const <TafsirEntry>[];
  }
}

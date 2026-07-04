import 'package:flutter/material.dart';

import '../models/quran_model.dart';
import '../services/quran_service.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final QuranService _service = QuranService();
  late final Future<List<QuranSurahSummary>> _surahsFuture;
  String _searchQuery = '';
  Set<int> _bookmarkedSurahs = <int>{};
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _service.fetchSurahs();
    _refreshPersistedState();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _refreshPersistedState() async {
    final bookmarkedSurahs = await _service.getBookmarkedSurahs();
    final lastRead = await _service.getLastRead();
    if (!mounted) {
      return;
    }
    setState(() {
      _bookmarkedSurahs = bookmarkedSurahs;
      _lastRead = lastRead;
    });
  }

  Future<void> _toggleSurahBookmark(int surahNumber) async {
    await _service.toggleSurahBookmark(surahNumber);
    await _refreshPersistedState();
  }

  Future<void> _openSurahDetail(int surahNumber, {int? initialAyahNumber}) async {
    final detail = await _service.fetchSurahDetail(surahNumber);
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailScreen(
          detail: detail,
          initialAyahNumber: initialAyahNumber,
        ),
      ),
    );
    await _refreshPersistedState();
  }

  Future<void> _openLastRead() async {
    final surahNumber = _lastRead?['surahNumber'] as int?;
    if (surahNumber == null) {
      return;
    }
    await _openSurahDetail(surahNumber, initialAyahNumber: _lastRead?['ayahNumber'] as int? ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Al-Qur\'an')),
      body: FutureBuilder<List<QuranSurahSummary>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat daftar surah. ${snapshot.error}'));
          }

          final surahs = snapshot.data ?? <QuranSurahSummary>[];
          final filtered = _searchQuery.isEmpty
              ? surahs
              : surahs.where((surah) {
                  final query = _searchQuery.toLowerCase();
                  return surah.name.toLowerCase().contains(query) ||
                      surah.englishName.toLowerCase().contains(query) ||
                      surah.englishNameTranslation.toLowerCase().contains(query) ||
                      surah.revelationType.toLowerCase().contains(query) ||
                      surah.number.toString().contains(query);
                }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama latin, arab, atau arti...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              if (_lastRead != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.history, color: Colors.green),
                      title: Text('Lanjutkan ${_lastRead!['surahName']}'),
                      subtitle: Text('Ayat ${_lastRead!['ayahNumber']}'),
                      trailing: FilledButton.tonal(
                        onPressed: _openLastRead,
                        child: const Text('Buka'),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Tidak ada surah yang cocok dengan pencarian.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final surah = filtered[index];
                          final isBookmarked = _bookmarkedSurahs.contains(surah.number);
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 20,
                                child: Text(surah.number.toString(), style: const TextStyle(fontSize: 14)),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      surah.englishName,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (isBookmarked)
                                    const Icon(Icons.bookmark, color: Colors.amber, size: 18),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(surah.name, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${surah.englishNameTranslation} • ${surah.revelationType} • ${surah.numberOfAyahs} ayat',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                                onPressed: () => _toggleSurahBookmark(surah.number),
                              ),
                              onTap: () => _openSurahDetail(surah.number),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

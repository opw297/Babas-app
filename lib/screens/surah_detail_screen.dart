import 'package:flutter/material.dart';

import '../models/quran_model.dart';
import '../services/quran_service.dart';
import 'tafsir_screen.dart';

class SurahDetailScreen extends StatefulWidget {
  final SurahDetail detail;
  final int? initialAyahNumber;

  const SurahDetailScreen({super.key, required this.detail, this.initialAyahNumber});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranService _service = QuranService();
  final ScrollController _scrollController = ScrollController();
  bool _isSurahBookmarked = false;
  Set<String> _bookmarkedAyahs = <String>{};
  int _currentAyah = 1;

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  @override
  void dispose() {
    _service.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedState() async {
    final isBookmarked = await _service.isSurahBookmarked(widget.detail.summary.number);
    final bookmarkedAyahs = await _service.getBookmarkedAyahs();
    final lastRead = await _service.getLastRead();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSurahBookmarked = isBookmarked;
      _bookmarkedAyahs = bookmarkedAyahs;
      _currentAyah = (lastRead?['ayahNumber'] as int? ?? widget.initialAyahNumber ?? 1);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentAyah > 0) {
        _scrollToAyah(_currentAyah);
      }
    });
  }

  Future<void> _toggleSurahBookmark() async {
    await _service.toggleSurahBookmark(widget.detail.summary.number);
    final isBookmarked = await _service.isSurahBookmarked(widget.detail.summary.number);
    if (!mounted) {
      return;
    }
    setState(() => _isSurahBookmarked = isBookmarked);
  }

  Future<void> _toggleAyahBookmark(int ayahNumber) async {
    await _service.toggleAyahBookmark(widget.detail.summary.number, ayahNumber);
    final bookmarkedAyahs = await _service.getBookmarkedAyahs();
    if (!mounted) {
      return;
    }
    setState(() => _bookmarkedAyahs = bookmarkedAyahs);
  }

  Future<void> _markLastRead(int ayahNumber) async {
    await _service.saveLastRead(widget.detail.summary.number, ayahNumber, widget.detail.summary.englishName);
    if (!mounted) {
      return;
    }
    setState(() => _currentAyah = ayahNumber);
  }

  void _scrollToAyah(int ayahNumber) {
    final index = ayahNumber - 1;
    if (index < 0 || index >= widget.detail.arabicAyahs.length) {
      return;
    }
    _scrollController.animateTo(
      index * 140.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.detail.summary;
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.englishName),
        actions: [
          IconButton(
            icon: Icon(_isSurahBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSurahBookmark,
            tooltip: 'Bookmark surah',
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TafsirScreen(
                    surahNumber: summary.number,
                    surahName: summary.englishName,
                  ),
                ),
              );
            },
            tooltip: 'Tafsir',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.englishName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(summary.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Arti: ${summary.englishNameTranslation}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text('Jumlah ayat: ${summary.numberOfAyahs}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text('Makkiyah/Madaniyah: ${summary.revelationType}', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TafsirScreen(
                          surahNumber: summary.number,
                          surahName: summary.englishName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Lihat Tafsir'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.detail.arabicAyahs.isEmpty
                ? const Center(child: Text('Data teks surah belum tersedia untuk surah ini.'))
                : Scrollbar(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: widget.detail.arabicAyahs.length,
                      itemBuilder: (context, index) {
                        final arab = widget.detail.arabicAyahs[index];
                        final translit = index < widget.detail.transliterationAyahs.length
                            ? widget.detail.transliterationAyahs[index]
                            : QuranAyah(number: index + 1, numberInSurah: index + 1, juz: 0, text: '');
                        final translation = index < widget.detail.translationAyahs.length
                            ? widget.detail.translationAyahs[index]
                            : QuranAyah(number: index + 1, numberInSurah: index + 1, juz: 0, text: '');
                        final isAyahBookmarked = _bookmarkedAyahs.contains('${summary.number}:${arab.numberInSurah}');

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            onTap: () => _markLastRead(arab.numberInSurah),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Ayat ${arab.numberInSurah}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isAyahBookmarked ? Icons.bookmark : Icons.bookmark_border),
                                        onPressed: () => _toggleAyahBookmark(arab.numberInSurah),
                                        tooltip: 'Bookmark ayat',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(arab.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 20, height: 1.6)),
                                  const SizedBox(height: 8),
                                  Text(translit.text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                  const SizedBox(height: 6),
                                  Text(translation.text, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

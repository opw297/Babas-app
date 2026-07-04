import 'package:flutter/material.dart';

import '../models/quran_model.dart';
import '../services/app_settings_service.dart';
import '../services/quran_audio_service.dart';
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
  final AppSettingsService _settingsService = AppSettingsService.instance;
  final QuranAudioService _audioService = QuranAudioService();
  late final List<GlobalKey> _ayahKeys;
  bool _isSurahBookmarked = false;
  Set<String> _bookmarkedAyahs = <String>{};
  int _currentAyah = 1;
  bool _isAudioAvailableOffline = false;

  @override
  void initState() {
    super.initState();
    _ayahKeys = List.generate(widget.detail.arabicAyahs.length, (_) => GlobalKey());
    _settingsService.addListener(_refreshSettings);
    _audioService.onPlaybackStateChanged = _refreshAudioUi;
    _audioService.onPlaybackCompleted = _handlePlaybackCompleted;
    _audioService.onPositionChanged = (position) {
      if (mounted) {
        setState(() => _audioService.position = position);
      }
    };
    _audioService.onDurationChanged = (duration) {
      if (mounted) {
        setState(() => _audioService.duration = duration);
      }
    };
    _loadPersistedState();
    _applyPersistedAudioPreferences();
  }

  @override
  void dispose() {
    _settingsService.removeListener(_refreshSettings);
    _service.dispose();
    _audioService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshSettings() {
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshAudioUi() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPersistedState() async {
    final isBookmarked = await _service.isSurahBookmarked(widget.detail.summary.number);
    final bookmarkedAyahs = await _service.getBookmarkedAyahs();
    final lastRead = await _service.getLastRead();

    final initialAyah = widget.initialAyahNumber ?? 1;
    final currentAyah = (lastRead != null && lastRead['surahNumber'] == widget.detail.summary.number)
        ? (lastRead['ayahNumber'] as int? ?? initialAyah)
        : initialAyah;

    if (!mounted) {
      return;
    }

    setState(() {
      _isSurahBookmarked = isBookmarked;
      _bookmarkedAyahs = bookmarkedAyahs;
      _currentAyah = currentAyah;
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

  Future<void> _playAyah(int ayahNumber) async {
    await _audioService.playAyah(
      surahNumber: widget.detail.summary.number,
      ayahNumber: ayahNumber,
      totalAyahs: widget.detail.summary.numberOfAyahs,
    );
    await _markLastRead(ayahNumber);
    _scrollToAyah(ayahNumber);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkOfflineAvailability() async {
    final available = await _audioService.isCurrentAudioAvailableOffline();
    if (mounted) {
      setState(() => _isAudioAvailableOffline = available);
    }
  }

  Future<void> _applyPersistedAudioPreferences() async {
    final settings = _settingsService.currentSettings;
    await _audioService.setQari(settings.qariCode, settings.qariName);
    await _audioService.setPlaybackSpeed(settings.playbackSpeed);
    await _checkOfflineAvailability();
  }

  Future<void> _handlePlaybackCompleted() async {
    if (_audioService.repeatSurah) {
      await _audioService.playAyah(
        surahNumber: widget.detail.summary.number,
        ayahNumber: 1,
        totalAyahs: widget.detail.summary.numberOfAyahs,
      );
      return;
    }
    if (_audioService.autoPlay && _audioService.currentAyahNumber < widget.detail.summary.numberOfAyahs) {
      await _playAyah(_audioService.currentAyahNumber + 1);
    }
  }

  Future<void> _openSurahByNumber(int surahNumber) async {
    final detail = await _service.fetchSurahDetail(surahNumber);
    if (!mounted) {
      return;
    }
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SurahDetailScreen(detail: detail, initialAyahNumber: 1)),
    );
  }

  void _scrollToAyah(int ayahNumber) {
    final index = ayahNumber - 1;
    if (index < 0 || index >= _ayahKeys.length) {
      return;
    }

    final targetContext = _ayahKeys[index].currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
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
    final settings = _settingsService.currentSettings;
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
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Qari: ${_audioService.qariName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(onPressed: _audioService.togglePlayPause, icon: Icon(_audioService.isPlaying ? Icons.pause : Icons.play_arrow)),
                    IconButton(onPressed: _audioService.stop, icon: const Icon(Icons.stop)),
                    IconButton(onPressed: () => _audioService.previousAyah(totalAyahs: widget.detail.summary.numberOfAyahs), icon: const Icon(Icons.skip_previous)),
                    IconButton(onPressed: () => _audioService.nextAyah(totalAyahs: widget.detail.summary.numberOfAyahs), icon: const Icon(Icons.skip_next)),
                    IconButton(onPressed: () async { final surahs = await _service.fetchSurahs(); final index = surahs.indexWhere((s) => s.number == widget.detail.summary.number); if (index > 0) { await _openSurahByNumber(surahs[index - 1].number); } }, icon: const Icon(Icons.arrow_back_ios_new)),
                    IconButton(onPressed: () async { final surahs = await _service.fetchSurahs(); final index = surahs.indexWhere((s) => s.number == widget.detail.summary.number); if (index >= 0 && index < surahs.length - 1) { await _openSurahByNumber(surahs[index + 1].number); } }, icon: const Icon(Icons.arrow_forward_ios)),
                  ],
                ),
                Slider(
                  value: _audioService.position.inMilliseconds.toDouble().clamp(0, (_audioService.duration?.inMilliseconds.toDouble() ?? 1)),
                  max: (_audioService.duration?.inMilliseconds.toDouble() ?? 1),
                  onChanged: (value) async {
                    await _audioService.seekTo(Duration(milliseconds: value.toInt()));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_audioService.position.toString().split('.').first),
                    Text((_audioService.duration ?? Duration.zero).toString().split('.').first),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Auto play'), selected: _audioService.autoPlay, onSelected: (value) async => _audioService.setAutoPlay(value)),
                    ChoiceChip(label: const Text('Repeat ayat'), selected: _audioService.repeatAyah, onSelected: (value) async => _audioService.setRepeatAyah(value)),
                    ChoiceChip(label: const Text('Repeat surah'), selected: _audioService.repeatSurah, onSelected: (value) async => _audioService.setRepeatSurah(value)),
                    ChoiceChip(label: const Text('Shuffle off'), selected: _audioService.shuffle, onSelected: (value) async => _audioService.setShuffle(value)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final speed in <double>[0.75, 1.0, 1.25, 1.5, 2.0])
                      ChoiceChip(
                        label: Text('${speed.toStringAsFixed(2).replaceAll('.00', '')}x'),
                        selected: (_audioService.playbackSpeed - speed).abs() < 0.001,
                        onSelected: (_) async => _audioService.setPlaybackSpeed(speed),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _audioService.qariCode,
                        decoration: const InputDecoration(labelText: 'Pilih Qari'),
                        items: const [
                          DropdownMenuItem(value: 'abdullah_basfar', child: Text('Abdullah Basfar')),
                          DropdownMenuItem(value: 'mishary_alafasy', child: Text('Mishary Alafasy')),
                          DropdownMenuItem(value: 'sahl_yassin', child: Text('Sahl Yassin')),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            final name = value == 'abdullah_basfar'
                                ? 'Abdullah Basfar'
                                : value == 'mishary_alafasy'
                                    ? 'Mishary Alafasy'
                                    : 'Sahl Yassin';
                            await _audioService.setQari(value, name);
                            await _settingsService.updateQari(value, name);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await _audioService.downloadCurrentAudio();
                        await _checkOfflineAvailability();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _audioService.deleteCurrentAudio();
                        await _checkOfflineAvailability();
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus'),
                    ),
                  ],
                ),
                if (_isAudioAvailableOffline)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Audio tersedia offline', style: TextStyle(color: Colors.green)),
                  ),
              ],
            ),
          ),
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

                        final isCurrentPlayingAyah = _audioService.currentSurahNumber == widget.detail.summary.number && _audioService.currentAyahNumber == arab.numberInSurah;
                        return Container(
                          key: _ayahKeys[index],
                          child: Card(
                            color: isCurrentPlayingAyah ? Theme.of(context).colorScheme.primaryContainer : null,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: InkWell(
                              onTap: () async {
                                await _markLastRead(arab.numberInSurah);
                                await _playAyah(arab.numberInSurah);
                              },
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
                                    Text(
                                      arab.text,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: settings.fontSizeArabic,
                                        height: 1.6,
                                        fontFamily: settings.arabicFontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      translit.text,
                                      style: TextStyle(
                                        fontSize: settings.fontSizeLatin,
                                        color: Colors.black87,
                                        fontFamily: settings.appFontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      translation.text,
                                      style: TextStyle(
                                        fontSize: settings.fontSizeTranslation,
                                        color: Colors.black54,
                                        fontFamily: settings.appFontFamily,
                                      ),
                                    ),
                                  ],
                                ),
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

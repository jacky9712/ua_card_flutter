import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewModels/card_library_view_model.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/recommended_deck_view_model.dart';
import 'deck_detail_screen.dart';
import 'test_connection_screen.dart';

class RecommendedDecksScreen extends ConsumerStatefulWidget {
  const RecommendedDecksScreen({super.key});

  @override
  ConsumerState<RecommendedDecksScreen> createState() => _RecommendedDecksScreenState();
}

class _RecommendedDecksScreenState extends ConsumerState<RecommendedDecksScreen> {
  int? _openingDeckId;

  // 篩選條件：系列/顏色/T級都是 null 或空集合代表「不篩選」，跟 CardLibraryViewModel
  // 的篩選欄位同一套習慣。「只看我的卡組」則是額外的布林開關。
  String? _selectedSeriesCode;
  Set<String> _selectedColors = {};
  String? _selectedTier;
  bool _onlyMySeries = false;

  // 跟 test_connection_screen.dart 用同一套顏色/中文標籤對照，維持全站一致。
  static const Map<String, String> _colorLabels = {
    'RED': '紅',
    'BLUE': '藍',
    'GREEN': '綠',
    'YELLOW': '黃',
    'PURPLE': '紫',
  };

  Color _getCardColor(String colorStr) {
    switch (colorStr.toUpperCase()) {
      case 'RED': return const Color(0xFFE53935);
      case 'BLUE': return const Color(0xFF1E88E5);
      case 'GREEN': return const Color(0xFF43A047);
      case 'YELLOW': return const Color(0xFFFFB300);
      case 'PURPLE': return const Color(0xFF8E24AA);
      default: return const Color(0xFF757575);
    }
  }

  bool get _hasActiveFilter =>
      _selectedSeriesCode != null || _selectedColors.isNotEmpty || _selectedTier != null || _onlyMySeries;

  // 對應來源網站的 "Tier1" / "Tier1.5" / "Tier2" ... 分級字串
  Color _tierColor(String tier) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(tier);
    final double rank = match != null ? double.tryParse(match.group(1)!) ?? 99 : 99;
    if (rank <= 1) return const Color(0xFFE53935);
    if (rank <= 2) return const Color(0xFFFF9800);
    if (rank <= 3) return const Color(0xFF1E88E5);
    return Colors.grey;
  }

  double _tierRank(String tier) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(tier);
    return match != null ? double.tryParse(match.group(1)!) ?? 99 : 99;
  }

  /// 從目前已載入的推薦牌組裡反推可選的系列清單（(series_id, code, name_zh)），
  /// 只列出真的有牌組的系列，不用另外去查全系列表。
  List<Map<String, dynamic>> _availableSeries(List<Map<String, dynamic>> decks) {
    final Map<int, Map<String, dynamic>> byId = {};
    for (final deck in decks) {
      final int? seriesId = deck['series_id'] as int?;
      final series = deck['series'];
      if (seriesId == null || series == null) continue;
      byId[seriesId] = {
        'id': seriesId,
        'code': series['series_code'] ?? '',
        'name': series['name_zh'] ?? series['series_code'] ?? '未分類',
      };
    }
    final list = byId.values.toList();
    list.sort((a, b) => (a['code'] as String).compareTo(b['code'] as String));
    return list;
  }

  List<String> _availableTiers(List<Map<String, dynamic>> decks) {
    final Set<String> tiers = {};
    for (final deck in decks) {
      final tier = (deck['tier'] ?? '').toString();
      if (tier.isNotEmpty) tiers.add(tier);
    }
    final list = tiers.toList();
    list.sort((a, b) => _tierRank(a).compareTo(_tierRank(b)));
    return list;
  }

  /// 「只看我的卡組」比對的是系列 id：我的牌組(本地+雲端)不管哪個來源，
  /// 存檔時都會帶 series_id（見 deck_view_model.dart 的 saveCurrentDeck），
  /// 這裡直接拿來跟推薦牌組的 series_id 對。
  Set<int> _mySeriesIds(List<Map<String, dynamic>> myDecks) {
    return myDecks.map((d) => d['series_id'] as int?).whereType<int>().toSet();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> decks, Set<int> mySeriesIds) {
    return decks.where((deck) {
      if (_selectedSeriesCode != null &&
          (deck['series']?['series_code'] ?? '') != _selectedSeriesCode) {
        return false;
      }
      if (_selectedTier != null && (deck['tier'] ?? '').toString() != _selectedTier) {
        return false;
      }
      if (_selectedColors.isNotEmpty) {
        final List<dynamic> deckColors = deck['colors'] ?? [];
        final hasOverlap = deckColors.any((c) => _selectedColors.contains(c));
        if (!hasOverlap) return false;
      }
      if (_onlyMySeries) {
        final int? seriesId = deck['series_id'] as int?;
        if (seriesId == null || !mySeriesIds.contains(seriesId)) return false;
      }
      return true;
    }).toList();
  }

  void _showFilterSheet(List<Map<String, dynamic>> decks, bool isDarkMode) {
    final seriesOptions = _availableSeries(decks);
    final tierOptions = _availableTiers(decks);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('篩選', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedSeriesCode = null;
                                _selectedColors = {};
                                _selectedTier = null;
                                _onlyMySeries = false;
                              });
                              setState(() {});
                            },
                            child: const Text('清除篩選'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('只看我的卡組系列', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('只顯示「我的牌組」頁面裡有的系列', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _onlyMySeries,
                        onChanged: (v) {
                          setSheetState(() => _onlyMySeries = v);
                          setState(() => _onlyMySeries = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('系列', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: seriesOptions.map((s) {
                          final String code = s['code'];
                          final bool selected = _selectedSeriesCode == code;
                          return ChoiceChip(
                            label: Text(s['name']),
                            selected: selected,
                            onSelected: (_) {
                              final newValue = selected ? null : code;
                              setSheetState(() => _selectedSeriesCode = newValue);
                              setState(() => _selectedSeriesCode = newValue);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('顏色', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _colorLabels.entries.map((entry) {
                          final bool selected = _selectedColors.contains(entry.key);
                          return ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: _getCardColor(entry.key), radius: 6),
                            label: Text(entry.value),
                            selected: selected,
                            onSelected: (_) {
                              final newColors = Set<String>.from(_selectedColors);
                              if (selected) {
                                newColors.remove(entry.key);
                              } else {
                                newColors.add(entry.key);
                              }
                              setSheetState(() => _selectedColors = newColors);
                              setState(() => _selectedColors = newColors);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('T 級', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tierOptions.map((tier) {
                          final bool selected = _selectedTier == tier;
                          return ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: _tierColor(tier), radius: 6),
                            label: Text(tier),
                            selected: selected,
                            onSelected: (_) {
                              final newValue = selected ? null : tier;
                              setSheetState(() => _selectedTier = newValue);
                              setState(() => _selectedTier = newValue);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openDeck(Map<String, dynamic> deck) async {
    final int deckId = deck['id'];
    setState(() => _openingDeckId = deckId);

    final cards = await ref.read(recommendedDeckViewModelProvider.notifier).fetchCardsForDeck(deckId);

    if (!mounted) return;
    setState(() => _openingDeckId = null);

    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('這組牌組尚未建立完整卡表')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(
          deckName: deck['name'] ?? '推薦牌組',
          cardsInDeck: cards,
          saveButtonLabel: '複製到組牌編輯器',
          onSavePressed: () {
            ref.read(deckViewModelProvider.notifier).loadCardsForNewDeck(cards);

            // 複製過去的牌組通常整組都是同一系列，組牌頁面預設顯示「全部系列」
            // 反而要使用者自己再找一次系列，這裡直接把卡池篩選對齊該牌組的系列。
            final String seriesCode = (deck['series']?['series_code'] ?? '').toString().toUpperCase();
            if (seriesCode.isNotEmpty) {
              ref.read(cardLibraryViewModelProvider.notifier).updateSelectedSeries(seriesCode);
            }

            // 牌組本身可能是雙色，直接從已經抓到的卡表推導顏色集合，一併套用篩選。
            final Set<String> colors = cards
                .map((c) => (c.color ?? '').toUpperCase())
                .where((c) => c.isNotEmpty)
                .toSet();
            if (colors.isNotEmpty) {
              ref.read(cardLibraryViewModelProvider.notifier).updateSelectedColors(colors);
            }

            Navigator.push(context, MaterialPageRoute(builder: (_) => const TestConnectionScreen()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendedDeckViewModelProvider);
    // 「只看我的卡組」要跟「我的牌組」頁面的系列比對，這裡直接讀同一個 provider，
    // 不用另外開一支查詢——decks 頁面本來就會被逛過、資料通常已經在了。
    final myDecks = ref.watch(deckViewModelProvider).myDecks;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mySeriesIds = _mySeriesIds(myDecks);
    final filteredDecks = _applyFilters(state.decks, mySeriesIds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('上位卡組推薦', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: '篩選',
                onPressed: () => _showFilterSheet(state.decks, isDarkMode),
              ),
              if (_hasActiveFilter)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recommendedDeckViewModelProvider.notifier).fetchRecommendedDecks(),
        child: state.isLoading && state.decks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.decks.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('目前尚無推薦牌組', style: TextStyle(color: Colors.grey))),
                      ),
                    ],
                  )
                : filteredDecks.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: Text('沒有符合篩選條件的牌組', style: TextStyle(color: Colors.grey))),
                          ),
                        ],
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDecks.length,
                    itemBuilder: (context, index) {
                      final deck = filteredDecks[index];
                      final String tier = (deck['tier'] ?? '').toString();
                      // 圓形徽章空間有限，"Tier1.5" 這種字串只取數字部分顯示
                      final tierMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(tier);
                      final String tierBadge = tierMatch?.group(1) ?? '?';
                      final String seriesName = deck['series']?['name_zh'] ?? '未分類系列';
                      final winRate = deck['win_rate'];
                      final int totalPrice = deck['total_price'] ?? 0;
                      final int deckId = deck['id'];
                      final bool opening = _openingDeckId == deckId;
                      final String? coverImageUrl = deck['cover_image_url'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: opening ? null : () => _openDeck(deck),
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: coverImageUrl != null && coverImageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: coverImageUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            width: 48,
                                            height: 48,
                                            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                            child: const Icon(Icons.style, color: Colors.grey, size: 20),
                                          ),
                                        )
                                      : Container(
                                          width: 48,
                                          height: 48,
                                          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                          child: const Icon(Icons.style, color: Colors.grey, size: 20),
                                        ),
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _tierColor(tier),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white, width: 1.5),
                                    ),
                                    child: Text(
                                      tierBadge,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(deck['name'] ?? '未命名牌組', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '$seriesName'
                            '${tier.isNotEmpty ? ' · $tier' : ''}'
                            '${winRate != null ? ' · 勝率 $winRate%' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: opening
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '¥ $totalPrice',
                                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

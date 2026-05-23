// lib/screens/test_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/deck_exporter.dart';
import '../viewmodels/card_view_model.dart';
import 'card_detail_dialog.dart';

class TestConnectionScreen extends ConsumerStatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  ConsumerState<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends ConsumerState<TestConnectionScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // 從 ViewModel 獲取初始搜尋文字
    _searchController = TextEditingController(text: ref.read(cardViewModelProvider).searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🎨 卡片屬性顏色
  Color _getCardColor(String? colorStr) {
    switch (colorStr?.toUpperCase()) {
      case 'RED': return const Color(0xFFE53935);
      case 'BLUE': return const Color(0xFF1E88E5);
      case 'GREEN': return const Color(0xFF43A047);
      case 'YELLOW': return const Color(0xFFFFB300);
      case 'PURPLE': return const Color(0xFF8E24AA);
      default: return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(cardViewModelProvider);
    final isSeriesSelected = uiState.selectedSeries.isNotEmpty;

    // 🌗 自動偵測系統/主題是黑色版還是白色版
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 🎨 根據黑/白版動態設定 UI 顏色
    final Color backgroundColor = isDarkMode ? const Color(0xFF141419) : const Color(0xFFF5F5F7);
    final Color appBarColor = isDarkMode ? const Color(0xFF1E1E24) : Colors.white;
    final Color searchBoxColor = isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E24) : Colors.white;
    final Color cardTextColor = isDarkMode ? Colors.white : Colors.black87;
    final Color controlPanelColor = isDarkMode ? const Color(0xFF22222A) : const Color(0xFFF0F0F4);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('組牌模式', style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 18)),
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: appBarColor,
            padding: const EdgeInsets.only(left: 12.0, right: 8.0, bottom: 10.0, top: 4.0),
            child: Row(
              children: [
                // 🔍 搜尋框
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: isSeriesSelected
                          ? '在 ${uiState.selectedSeries.toUpperCase()} 中搜尋...'
                          : '搜尋卡號或名稱...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: searchBoxColor,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(cardViewModelProvider.notifier).updateSearchQuery('');
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (text) => ref.read(cardViewModelProvider.notifier).updateSearchQuery(text),
                  ),
                ),

                const SizedBox(width: 4),

                // ☰ 三條槓系列網格篩選按鈕
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    // 有選系列就亮金/橘色，沒選就依照黑白版顯示黑或白
                    color: isSeriesSelected
                        ? (isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700)
                        : (isDarkMode ? Colors.white : Colors.black87),
                    size: 24,
                  ),
                  onPressed: () => _showSeriesGridPicker(context, ref, uiState, isDarkMode),
                ),
              ],
            ),
          ),
        ),
      ),

      // 🎛️ 底部結算面板
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appBarColor,
          border: Border(top: BorderSide(color: isDarkMode ? const Color(0xFF2C2C35) : Colors.grey.shade300, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '目前張數: ${uiState.totalDeckCount} / 50',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: uiState.totalDeckCount > 50 ? Colors.redAccent : (isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '總金額: ¥ ${uiState.totalDeckPrice}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.share, color: isDarkMode ? Colors.white70 : Colors.black54),
                      onPressed: uiState.totalDeckCount > 0 ? () {
                        DeckExporter.exportAndShareDeck(
                          context: context,
                          deckMap: uiState.deckMap,
                          allCards: uiState.allCards,
                        );
                      } : null,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: uiState.totalDeckCount == 50 ? () {
                        _showSaveDialog(context, ref, isDarkMode);
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700,
                        disabledBackgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        foregroundColor: isDarkMode ? Colors.black : Colors.white,
                        disabledForegroundColor: Colors.white30,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.save, size: 18),
                          SizedBox(width: 4),
                          Text('儲存牌組', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: uiState.isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700)))
          : uiState.filteredCards.isEmpty
          ? Center(child: Text('找不到符合的卡片', style: TextStyle(color: isDarkMode ? Colors.grey : Colors.grey.shade600)))
          : GridView.builder(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.54,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: uiState.filteredCards.length,
        itemBuilder: (context, index) {
          final card = uiState.filteredCards[index];
          final quantity = uiState.deckMap[card.id] ?? 0;
          final cardAccentColor = _getCardColor(card.color);

          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: quantity > 0 ? cardAccentColor : (isDarkMode ? const Color(0xFF2C2C35) : Colors.grey.shade300),
                width: quantity > 0 ? 2.0 : 1.0,
              ),
              boxShadow: quantity > 0 ? [
                BoxShadow(color: cardAccentColor.withOpacity(0.2), blurRadius: 6, spreadRadius: 1)
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🖼️ 圖片區
                Expanded(
                  flex: 74,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => CardDetailDialog(card: card),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                          child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: card.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                          )
                              : const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                      if (quantity > 0)
                        Positioned(
                          top: 0, left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: cardAccentColor,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                            ),
                            child: Text('x$quantity', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      if (card.price != null && card.price! > 0)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 0.8),
                            ),
                            child: Text(
                              '¥${card.price}',
                              style: const TextStyle(color: Color(0xFFFFE082), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 📝 文字區
                Expanded(
                  flex: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: isDarkMode ? const Color(0xFF15151A) : const Color(0xFFF8F8FA),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, child: Text(card.cardNumber, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold))),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(card.name ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cardTextColor))),
                      ],
                    ),
                  ),
                ),

                // 🎛️ 控制面板
                Expanded(
                  flex: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: controlPanelColor,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: quantity > 0 ? () => ref.read(cardViewModelProvider.notifier).updateCardQuantity(card.id!, -1) : null,
                            child: Container(alignment: Alignment.center, child: Icon(Icons.remove, color: quantity > 0 ? Colors.redAccent : Colors.white10, size: 24)),
                          ),
                        ),
                        Text('$quantity', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: quantity > 0 ? cardAccentColor : Colors.white38)),
                        Expanded(
                          child: InkWell(
                            onTap: quantity < 4 ? () => ref.read(cardViewModelProvider.notifier).updateCardQuantity(card.id!, 1) : null,
                            child: Container(alignment: Alignment.center, child: Icon(Icons.add, color: quantity < 4 ? Colors.greenAccent : Colors.white10, size: 24)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 Kadoraba 核心改動：橫向網格彈出式 BottomSheet，完美支援黑白雙色
  void _showSeriesGridPicker(BuildContext context, WidgetRef ref, dynamic uiState, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.45, // 限制高度在螢幕的 45%，防止過長
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '選擇系列代碼',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black87)
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Text('關閉', style: TextStyle(color: isDarkMode ? Colors.grey : Colors.blue)),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // 網格矩陣：一橫排顯示 4 個系列
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,         // 4 欄並排
                    childAspectRatio: 2.2,     // 控制格子寬高比，使其扁平好看
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: uiState.availableSeries.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final seriesValue = isAll ? '' : uiState.availableSeries[index - 1];
                    final displayLabel = isAll ? 'ALL' : seriesValue.toUpperCase();
                    final isSelected = uiState.selectedSeries == seriesValue;

                    // 依據選中狀態與黑白版動態給色
                    Color itemBg;
                    Color itemText;
                    if (isSelected) {
                      itemBg = isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700;
                      itemText = isDarkMode ? Colors.black : Colors.white;
                    } else {
                      itemBg = isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4);
                      itemText = isDarkMode ? Colors.white70 : Colors.black87;
                    }

                    return InkWell(
                      onTap: () {
                        ref.read(cardViewModelProvider.notifier).updateSelectedSeries(seriesValue);
                        Navigator.pop(context); // 點擊選完自動關閉選單
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: itemBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          displayLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: itemText),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // lib/screens/test_connection_screen.dart 內

  void _showSaveDialog(BuildContext context, WidgetRef ref, bool isDarkMode) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
          title: Text('儲存牌組', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: '請輸入牌組名稱...',
              hintStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDarkMode ? const Color(0xFF2C2C35) : Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final String deckName = nameController.text.trim();
                if (deckName.isEmpty) return;

                // 1. 先關閉輸入名字的對話框
                Navigator.pop(context);

                // 2. 呼叫 ViewModel 儲存，並「接住」它的成功/失敗布林值
                final bool isSuccess = await ref.read(cardViewModelProvider.notifier).saveCurrentDeck(deckName);

                // 3. 根據真實現況，彈出正確的 SnackBar 提示
                if (context.mounted) {
                  if (isSuccess) {
                    // 真正成功了！
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 牌組「$deckName」已成功同步至 Supabase 雲端！', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFFFFD700),
                      ),
                    );
                  } else {
                    // 慘遭滑鐵盧，把 ViewModel 裡的錯誤訊息抓出來噴在畫面上
                    final errorMsg = ref.read(cardViewModelProvider).errorMessage ?? '未知錯誤';
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('❌ 儲存失敗'),
                        content: Text(errorMsg),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('確定')),
                        ],
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: isDarkMode ? const Color(0xFFFFD700) : Colors.orange.shade700),
              child: Text('確認儲存', style: TextStyle(color: isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
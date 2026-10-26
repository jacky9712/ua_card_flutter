// lib/screens/deck_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ua_card.dart';
import '../utils/deck_exporter.dart';
import '../utils/deck_qr_codec.dart';
import '../utils/deck_stats.dart';
import '../widgets/deck_distribution_charts.dart';
import '../viewModels/card_library_view_model.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/deck_share_code_view_model.dart';
import 'deck_builder_screen.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

class DeckDetailScreen extends ConsumerStatefulWidget {
  final int? deckId; // 🔥 新增：牌組 ID，用於編輯模式
  final String deckName;
  final List<UACard> cardsInDeck; // 50張展開的卡片
  final VoidCallback? onSavePressed;
  /// null 時用預設的「儲存至我的牌組」（跟著介面語言）
  final String? saveButtonLabel;
  /// 一開始停在哪個分頁（0: 圖像, 1: 文字/QR）
  final int initialTabIndex;

  const DeckDetailScreen({
    super.key,
    this.deckId,
    required this.deckName,
    required this.cardsInDeck,
    this.onSavePressed,
    this.saveButtonLabel,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  late int _activeTabIndex; // 0: 圖像, 1: 文字/QR

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    final deckData = DeckQrCodec.encodeDeck(_getDeckMap(), widget.cardsInDeck);
    if (deckData != DeckQrCodec.prefix) {
      // 不能在 initState 裡同步改 provider，排到下一個 microtask。
      Future.microtask(() {
        if (!mounted) return;
        ref.read(deckShareCodeViewModelProvider.notifier).loadExisting(deckData);
      });
    }
  }

  Map<int, int> _getDeckMap() {
    final Map<int, int> map = {};
    for (var card in widget.cardsInDeck) {
      if (card.id != null) {
        map[card.id!] = (map[card.id!] ?? 0) + 1;
      }
    }
    return map;
  }

  // 🧮 數據處理：將 50 張卡片按卡號分組，用於顯示卡表
  Map<String, Map<String, dynamic>> _getGroupedCards() {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var card in widget.cardsInDeck) {
      if (!grouped.containsKey(card.cardNumber)) {
        grouped[card.cardNumber] = {'card': card, 'count': 1};
      } else {
        grouped[card.cardNumber]!['count']++;
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedCards = _getGroupedCards();
    final energyData = DeckStats.energyDistribution(widget.cardsInDeck);
    final triggerData = DeckStats.triggerDistribution(widget.cardsInDeck);
    final int totalPrice = widget.cardsInDeck.fold(
      0,
      (sum, card) => sum + (card.price ?? 0),
    );

    // 🎨 統一從主題獲取顏色，確保跟隨系統切換
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color surfaceColor = Theme.of(context).cardColor;

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 處理
      appBar: AppBar(
        title: Text(
          widget.onSavePressed != null ? context.l10n.previewBeforeSave : widget.deckName,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: textColor,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          if (widget.onSavePressed == null)
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.amber),
              onPressed: () {
                ref
                    .read(deckViewModelProvider.notifier)
                    .loadDeckForEditing(widget.deckId, widget.cardsInDeck);
                ref
                    .read(cardLibraryViewModelProvider.notifier)
                    .selectSeriesForDeck(widget.cardsInDeck);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeckBuilderScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.ios_share, size: 20, color: textColor),
            onPressed: () {
              DeckExporter.exportAndShareDeck(
                context: context,
                deckMap: _getDeckMap(),
                allCards: widget.cardsInDeck.toSet().toList(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: widget.onSavePressed != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: widget.onSavePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.saveButtonLabel ?? context.l10n.saveToMyDecks,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(textColor),

            _activeTabIndex == 0
                ? _buildCardImageGrid(groupedCards)
                : _buildTextAndQRSection(surfaceColor, textColor),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeckHeaderOverview(totalPrice, surfaceColor, textColor),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.costDistribution,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EnergyDistributionChart(
                    data: energyData,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.triggerDistribution,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TriggerDistributionGrid(
                    data: triggerData,
                    surfaceColor: surfaceColor,
                    textColor: textColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _tabItem(context.l10n.tabCardImages, 0, textColor),
          const SizedBox(width: 20),
          _tabItem(context.l10n.tabImportQr, 1, textColor),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index, Color textColor) {
    bool isActive = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? textColor : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 20,
              color: Colors.redAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildTextAndQRSection(Color surfaceColor, Color textColor) {
    final String deckData = DeckQrCodec.encodeDeck(_getDeckMap(), widget.cardsInDeck);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.deckImportQrTitle,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: deckData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.deckImportQrHint,
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildShareCodeSection(deckData, textColor),
        ],
      ),
    );
  }

  Widget _buildShareCodeSection(String deckData, Color textColor) {
    final shareState = ref.watch(deckShareCodeViewModelProvider);
    final shareCode = shareState.shareCode;
    return Column(
      children: [
        ElevatedButton(
          key: const Key('deckShareCodeGenerate'),
          onPressed: shareState.isLoading || deckData == DeckQrCodec.prefix
              ? null
              : () => ref.read(deckShareCodeViewModelProvider.notifier).generate(deckData),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionRed,
            foregroundColor: Colors.white,
          ),
          child: shareState.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.l10n.generateShareCode),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.shareCodeHint,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        if (shareCode != null) ...[
          const SizedBox(height: 12),
          Text(
            shareCode.code,
            key: const Key('deckShareCodeText'),
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          Text(
            context.l10n.shareCodeExpiresAt(
              DateFormat('yyyy/MM/dd HH:mm').format(shareCode.expiresAt.toLocal()),
            ),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          TextButton.icon(
            key: const Key('deckShareCodeCopy'),
            icon: const Icon(Icons.copy, size: 18),
            label: Text(context.l10n.copyShareCode),
            onPressed: () async {
              // await 之前先取好 messenger 與文字，await 之後不再碰 context。
              final messenger = ScaffoldMessenger.of(context);
              final copiedText = context.l10n.shareCodeCopied;
              await Clipboard.setData(ClipboardData(text: shareCode.code));
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(content: Text(copiedText)));
            },
          ),
        ],
        if (shareState.error != null) ...[
          const SizedBox(height: 12),
          Text(
            shareState.error!.localize(context.l10n),
            key: const Key('deckShareCodeError'),
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCardImageGrid(
    Map<String, Map<String, dynamic>> groupedCards,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.68,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: groupedCards.length,
        itemBuilder: (context, index) {
          final item = groupedCards.values.elementAt(index);
          final UACard card = item['card'];
          final int count = item['count'];

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: card.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade900,
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Text(
                    'x$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeckHeaderOverview(
    int totalPrice,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.totalCards,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.cardCount(widget.cardsInDeck.length),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.l10n.estimatedPrice,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                '¥ $totalPrice',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

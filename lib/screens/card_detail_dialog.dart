// lib/screens/card_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:translator/translator.dart'; // 🔥 引入翻譯套件
import '../models/ua_card.dart';

class CardDetailDialog extends StatefulWidget {
  final UACard card;

  const CardDetailDialog({super.key, required this.card});

  @override
  State<CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends State<CardDetailDialog> {
  // 建立翻譯機實例
  final _translator = GoogleTranslator();

  // 狀態變數
  bool _isTranslating = false;
  bool _showTranslation = false;

  String? _translatedEffect;
  String? _translatedTrigger;

  // 🔥 執行翻譯的非同步函式
  Future<void> _translateTexts() async {
    // 如果已經翻過了，就只要切換顯示狀態就好
    if (_translatedEffect != null || _translatedTrigger != null) {
      setState(() {
        _showTranslation = !_showTranslation;
      });
      return;
    }

    // 開始翻譯
    setState(() {
      _isTranslating = true;
    });

    try {
      // 同時翻譯效果文與觸發文 (翻成繁體中文 zh-tw)
      if (widget.card.effectText != null && widget.card.effectText!.isNotEmpty) {
        final effectResult = await _translator.translate(widget.card.effectText!, to: 'zh-tw');
        _translatedEffect = effectResult.text;
      }

      if (widget.card.triggerText != null && widget.card.triggerText!.isNotEmpty) {
        final triggerResult = await _translator.translate(widget.card.triggerText!, to: 'zh-tw');
        _translatedTrigger = triggerResult.text;
      }

      setState(() {
        _showTranslation = true;
      });
    } catch (e) {
      // 翻譯失敗的錯誤處理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('翻譯失敗，請檢查網路連線')),
        );
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🌟 頂部工具列：包含關閉按鈕與翻譯按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 翻譯按鈕
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextButton.icon(
                    onPressed: _isTranslating ? null : _translateTexts,
                    icon: _isTranslating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_showTranslation ? Icons.g_translate : Icons.translate),
                    label: Text(_showTranslation ? '顯示原文' : '中文翻譯'),
                  ),
                ),
                // 關閉按鈕
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // 📜 可滾動的內容區
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.card.imageUrl != null && widget.card.imageUrl!.isNotEmpty)
                      Center(
                        child: SizedBox(
                          height: 300,
                          child: CachedNetworkImage(
                            imageUrl: widget.card.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    Text(widget.card.name ?? '未知名稱', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.card.cardNumber, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const Divider(height: 24, thickness: 1),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('BP', widget.card.bp?.toString() ?? '-'),
                        _buildStatBadge('AP 消耗', widget.card.apCost?.toString() ?? '-'),
                        _buildStatBadge('顏色', widget.card.color ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ⚔️ 效果文 (根據狀態切換顯示原文或譯文)
                    if (widget.card.effectText != null && widget.card.effectText!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('效果', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          if (_showTranslation) const Text(' (已翻譯)', style: TextStyle(fontSize: 12, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          _showTranslation ? (_translatedEffect ?? '翻譯失敗') : widget.card.effectText!,
                          style: const TextStyle(height: 1.5)
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ⚡ 觸發效果 (根據狀態切換顯示原文或譯文)
                    if (widget.card.triggerText != null && widget.card.triggerText!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('觸發 (Trigger)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          if (_showTranslation) const Text(' (已翻譯)', style: TextStyle(fontSize: 12, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          _showTranslation ? (_translatedTrigger ?? '翻譯失敗') : widget.card.triggerText!,
                          style: const TextStyle(height: 1.5)
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/opponent_view_model.dart';
import '../models/ua_card.dart';
import 'deck_detail_screen.dart';
import '../l10n/l10n_ext.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessed = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.scanQrTitle),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.unavailable:
                    return const Icon(Icons.flash_off, color: Colors.red);
                  default:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessed) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code == null) continue;

                if (code.startsWith('UA_DECK|')) {
                  setState(() => _isProcessed = true);

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  final success = await ref.read(deckViewModelProvider.notifier).importDeckFromQR(code);

                  if (!mounted) return;

                  if (success) {
                    // 1. 準備展開後的卡片清單供預覽頁面使用
                    final deckState = ref.read(deckViewModelProvider);
                    final List<UACard> expandedCards = [];
                    deckState.deckMap.forEach((cardId, quantity) {
                      final card = deckState.deckCardDetails[cardId];
                      if (card != null) {
                        for (int i = 0; i < quantity; i++) {
                          expandedCards.add(card);
                        }
                      }
                    });

                    // 2. ✨ 直接跳轉至預覽畫面，並取代目前的掃描頁面
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => DeckDetailScreen(
                          deckName: context.l10n.importedDeckName,
                          cardsInDeck: expandedCards,
                        ),
                      ),
                    );

                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.deckImported), backgroundColor: Colors.green),
                    );
                  } else {
                    setState(() => _isProcessed = false);
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.importFailed), backgroundColor: Colors.redAccent),
                    );
                  }
                  break;
                } else if (code.startsWith('UA_PLAYER|')) {
                  setState(() => _isProcessed = true);

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  final displayName = await ref.read(opponentViewModelProvider.notifier).addOpponentFromQr(code);

                  if (!mounted) return;

                  if (displayName != null) {
                    navigator.pop(); // 掃到人就直接退回上一頁，不用像牌組那樣跳預覽頁
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.opponentAdded(displayName)), backgroundColor: Colors.green),
                    );
                  } else {
                    setState(() => _isProcessed = false);
                    final error = ref.read(opponentViewModelProvider).errorMessage ?? l10n.addOpponentFailed;
                    messenger.showSnackBar(
                      SnackBar(content: Text('❌ $error'), backgroundColor: Colors.redAccent),
                    );
                  }
                  break;
                }
              }
            },
          ),
          // 掃描框輔助視覺
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              context.l10n.scanQrHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/screens/match_records_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewModels/match_record_view_model.dart';
import 'create_match_record_screen.dart';
import '../l10n/l10n_ext.dart';

class MatchRecordsScreen extends ConsumerWidget {
  const MatchRecordsScreen({super.key});

  /// match_records 的 result 是從「記錄的那個人（player）」的角度存的。
  /// 如果我是 opponent（別人幫我記的），要把結果反過來看才是「我」的勝敗。
  String _resultFromMyPerspective(Map<String, dynamic> record, String myUserId) {
    final String result = record['result'];
    if (record['player_id'] == myUserId) return result;
    switch (result) {
      case 'win':
        return 'loss';
      case 'loss':
        return 'win';
      default:
        return 'draw';
    }
  }

  String _opponentNameFromMyPerspective(BuildContext context, Map<String, dynamic> record, String myUserId) {
    if (record['player_id'] == myUserId) {
      // 自行輸入名字的對手沒有帳號、也就沒有 opponent_profile 可以 join，退回文字欄位。
      return record['opponent_profile']?['display_name'] ?? record['opponent_name_text'] ?? context.l10n.unnamedPlayer;
    }
    return record['player_profile']?['display_name'] ?? context.l10n.unnamedPlayer;
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return Colors.green;
      case 'loss':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _resultLabel(BuildContext context, String result) {
    switch (result) {
      case 'win':
        return context.l10n.win;
      case 'loss':
        return context.l10n.loss;
      default:
        return context.l10n.draw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchState = ref.watch(matchRecordViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final myUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.actionMatchRecords, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMatchRecordScreen())),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: matchState.isLoading && matchState.records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(matchRecordViewModelProvider.notifier).fetchMyMatchRecords(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsHeader(context, matchState, isDarkMode)),
                  if (matchState.records.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text(context.l10n.noMatchRecords, style: TextStyle(color: Colors.grey))),
                      ),
                    )
                  else if (myUserId != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = matchState.records[index];
                            return _buildRecordTile(context, ref, record, myUserId, isDarkMode);
                          },
                          childCount: matchState.records.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, MatchRecordState state, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context.l10n.totalMatches, '${state.totalCount}', isDarkMode),
          _buildStatItem(context.l10n.win, '${state.winCount}', isDarkMode, color: Colors.green),
          _buildStatItem(context.l10n.loss, '${state.lossCount}', isDarkMode, color: Colors.redAccent),
          _buildStatItem(context.l10n.winRate, '${state.winRate.toStringAsFixed(0)}%', isDarkMode, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDarkMode, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color ?? (isDarkMode ? Colors.white : Colors.black))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecordTile(BuildContext context, WidgetRef ref, Map<String, dynamic> record, String myUserId, bool isDarkMode) {
    final result = _resultFromMyPerspective(record, myUserId);
    final opponentName = _opponentNameFromMyPerspective(context, record, myUserId);
    final deckName = record['deck_name_snapshot'] as String?;
    final deckTier = record['deck_tier'] as String?;
    final playedAt = DateTime.tryParse(record['played_at'] ?? '');
    final note = record['note'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showRecordDetail(context, ref, record, myUserId, isDarkMode),
        leading: CircleAvatar(
          backgroundColor: _resultColor(result).withValues(alpha: 0.15),
          child: Text(_resultLabel(context, result), style: TextStyle(color: _resultColor(result), fontWeight: FontWeight.bold)),
        ),
        title: Text('vs $opponentName', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          [
            if (deckName != null) '$deckName${deckTier != null && deckTier.isNotEmpty ? '($deckTier)' : ''}',
            if (playedAt != null) DateFormat('yyyy/MM/dd HH:mm').format(playedAt.toLocal()),
            if (note != null && note.isNotEmpty) note,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _showRecordDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> record,
    String myUserId,
    bool isDarkMode,
  ) {
    final result = _resultFromMyPerspective(record, myUserId);
    final opponentName = _opponentNameFromMyPerspective(context, record, myUserId);
    final deckName = record['deck_name_snapshot'] as String?;
    final deckTier = record['deck_tier'] as String?;
    final playedAt = DateTime.tryParse(record['played_at'] ?? '');
    final note = record['note'] as String?;
    // 只有記錄的那個人（player）能刪；被記錄的對手是唯讀身分，見 match_records 的 RLS。
    final canDelete = record['player_id'] == myUserId;
    final recordId = record['id'] as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _resultColor(result).withValues(alpha: 0.15),
                      child: Text(_resultLabel(context, result),
                          style: TextStyle(color: _resultColor(result), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('vs $opponentName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (deckName != null) ...[
                  _detailRow(Icons.style_outlined, context.l10n.deckUsed,
                      '$deckName${deckTier != null && deckTier.isNotEmpty ? '（$deckTier）' : ''}'),
                  const SizedBox(height: 8),
                ],
                if (playedAt != null) ...[
                  _detailRow(Icons.event, context.l10n.playedAt, DateFormat('yyyy/MM/dd HH:mm').format(playedAt.toLocal())),
                  const SizedBox(height: 8),
                ],
                if (note != null && note.isNotEmpty) ...[
                  _detailRow(Icons.notes, context.l10n.note, note),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                if (canDelete)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(context.l10n.deleteThisRecord),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (dialogCtx) => AlertDialog(
                            title: Text(context.l10n.deleteRecordTitle),
                            content: Text(context.l10n.deleteRecordConfirm),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text(context.l10n.cancel)),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: Text(context.l10n.delete, style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        await ref.read(matchRecordViewModelProvider.notifier).deleteMatchRecord(recordId);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

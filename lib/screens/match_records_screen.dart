// lib/screens/match_records_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/app_error.dart';
import '../utils/match_record_stats.dart';
import '../viewModels/match_record_view_model.dart';
import 'create_match_record_screen.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

class MatchRecordsScreen extends ConsumerWidget {
  const MatchRecordsScreen({super.key});

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
    final myUserId = matchState.myUserId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.actionMatchRecords, style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.matchTabRecords),
              Tab(text: context.l10n.matchTabByDeck),
              Tab(text: context.l10n.matchTabByOpponent),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.amber,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMatchRecordScreen())),
          child: const Icon(Icons.add, color: Colors.black),
        ),
        body: matchState.isLoading && matchState.records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRecordsTab(context, ref, matchState, myUserId),
                  _buildGroupTab(context, ref, matchState.statsByDeck, isDeck: true),
                  _buildGroupTab(context, ref, matchState.statsByOpponent, isDeck: false),
                ],
              ),
      ),
    );
  }

  Widget _buildRecordsTab(BuildContext context, WidgetRef ref, MatchRecordState matchState, String? myUserId) {
    return RefreshIndicator(
      onRefresh: () => ref.read(matchRecordViewModelProvider.notifier).fetchMyMatchRecords(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildStatsHeader(context, matchState)),
          if (matchState.records.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: matchState.error?.code == AppErrorCode.loadMatchesFailed
                      ? Column(
                          children: [
                            Text(matchState.error!.localize(context.l10n), style: TextStyle(color: Colors.grey)),
                            TextButton.icon(
                              onPressed: () => ref.read(matchRecordViewModelProvider.notifier).fetchMyMatchRecords(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(context.l10n.retry),
                            ),
                          ],
                        )
                      : Text(context.l10n.noMatchRecords, style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else if (myUserId != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = matchState.records[index];
                    return _buildRecordTile(context, ref, record, myUserId);
                  },
                  childCount: matchState.records.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildGroupTab(
    BuildContext context,
    WidgetRef ref,
    List<MatchStatsGroup> groups, {
    required bool isDeck,
  }) {
    return RefreshIndicator(
      onRefresh: () => ref.read(matchRecordViewModelProvider.notifier).fetchMyMatchRecords(),
      // AlwaysScrollableScrollPhysics：內容不滿一頁（或空清單）時仍可下拉刷新。
      child: groups.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text(context.l10n.noMatchRecords, style: TextStyle(color: Colors.grey))),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: groups.length,
              itemBuilder: (context, index) => _buildGroupTile(context, groups[index], isDeck: isDeck),
            ),
    );
  }

  Widget _buildGroupTile(BuildContext context, MatchStatsGroup group, {required bool isDeck}) {
    final stats = group.stats;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          group.label ?? (isDeck ? context.l10n.unspecifiedDeck : context.l10n.unnamedPlayer),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(context.l10n.matchWinLossDraw(stats.win, stats.loss, stats.draw), style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${context.l10n.winRate} ${stats.winRate.toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, MatchRecordState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context.l10n.totalMatches, '${state.totalCount}'),
          _buildStatItem(context.l10n.win, '${state.winCount}', color: Colors.green),
          _buildStatItem(context.l10n.loss, '${state.lossCount}', color: Colors.redAccent),
          _buildStatItem(context.l10n.winRate, '${state.winRate.toStringAsFixed(0)}%', color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color ?? (Colors.white))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecordTile(BuildContext context, WidgetRef ref, Map<String, dynamic> record, String myUserId) {
    final result = resultFromMyPerspective(record, myUserId);
    final opponentName = _opponentNameFromMyPerspective(context, record, myUserId);
    final deckName = record['deck_name_snapshot'] as String?;
    final deckTier = record['deck_tier'] as String?;
    final playedAt = DateTime.tryParse(record['played_at'] ?? '');
    final note = record['note'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showRecordDetail(context, ref, record, myUserId),
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
  ) {
    final result = resultFromMyPerspective(record, myUserId);
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
      backgroundColor: AppColors.surface,
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
                        final success = await ref.read(matchRecordViewModelProvider.notifier).deleteMatchRecord(recordId);
                        if (!ctx.mounted) return;
                        if (success) {
                          Navigator.pop(ctx);
                        } else {
                          // 刪除失敗就留在選單上並提示，原本不管成功與否都直接關掉。
                          final error = ref.read(matchRecordViewModelProvider).error!.localize(context.l10n);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                          );
                        }
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

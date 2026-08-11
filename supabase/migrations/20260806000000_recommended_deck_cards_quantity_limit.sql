-- 修正 recommended_deck_cards 的張數上限
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行
--
-- 背景：Union Arena 有少數特例卡（卡面文字寫明「このカードはデッキに12枚まで入れられる」，
-- 例如「陰の実力者になりたくて！」的「影の兵士」SLG-1-030），單張卡合法可以放到 12 張，
-- 不受一般「同名卡最多 4 張」規則限制。原本的 `quantity between 1 and 4` 限制太嚴，
-- 把「シェリル＆ランカ」以外的「影の軍団」牌組匯入卡在這裡（詳見
-- recommended_decks_import_report_20260806_013722.csv 的 error_writing_deck）。
--
-- 這裡把上限放寬到 12（目前已知的特例卡上限），冪等、可重複執行。

alter table public.recommended_deck_cards drop constraint if exists recommended_deck_cards_quantity_check;
alter table public.recommended_deck_cards add constraint recommended_deck_cards_quantity_check
  check (quantity between 1 and 12);

-- 上位卡組推薦 - 初始資料（來源：torecards.com Tier 表 + 各系列頁的「サンプルデッキレシピ」牌組圖）
-- 執行前提：先執行過 supabase/migrations/20260801000000_recommended_decks.sql
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行
--
-- 卡號 -> card_id 皆已對照現有 cards 表核對過（含價格）。
-- 少數卡片是「限定商品」（Starter Deck 等）版本，目前 cards 表尚未收錄，
-- 該卡會直接略過不放進 recommended_deck_cards，因此下面兩組牌組的實際卡片數
-- 會少於 50（summary 欄位已註記），估價僅供參考、非完整 50 張總價。

-- ============================================================
-- 1. ファウルバウト（コードギアス 奪還のZ / UA34BT）
--    來源時間點：2025-03-07 的 Tier1 認定，非本次「目前最新」Tier 表的名單，
--    但仍是官方認可過的強力牌組，先收錄。
-- ============================================================
WITH d AS (
  INSERT INTO public.recommended_decks (name, series_id, tier, summary, source)
  VALUES (
    'ファウルバウト(ノーランド軸)',
    51,
    'Tier1',
    '2025/3/7 時點被認定 Tier1 的可道理・奪還のZ牌組，核心為ノーランド・フォン・リューネベルク疊卡＋ファウルバウト・タイタンモード終結。50/50 張全數對照成功。',
    'https://torecards.com/2025/03/07/foulbout/'
  )
  RETURNING id
)
INSERT INTO public.recommended_deck_cards (recommended_deck_id, card_id, quantity)
SELECT d.id, v.card_id, v.quantity
FROM d, (VALUES
  (5861, 12), (5841, 2), (5810, 4), (5808, 2), (5857, 4),
  (5888, 4), (5823, 4), (5833, 3), (5802, 1), (5793, 4),
  (5893, 4), (5832, 4), (5897, 2)
) AS v(card_id, quantity);

-- ============================================================
-- 2. シャドウ（陰の実力者になりたくて！/ UA52BT）
--    目前 Tier 表現役 Tier1。50/50 張全數對照成功。
-- ============================================================
WITH d AS (
  INSERT INTO public.recommended_decks (name, series_id, tier, summary, source)
  VALUES (
    'シャドウ(シド・カゲノー)',
    69,
    'Tier1',
    '主角シド・カゲノー／シャドウ的レイド疊卡牌組，SR「シャドウ」為終結核心。50/50 張全數對照成功。',
    'https://torecards.com/kjn/'
  )
  RETURNING id
)
INSERT INTO public.recommended_deck_cards (recommended_deck_id, card_id, quantity)
SELECT d.id, v.card_id, v.quantity
FROM d, (VALUES
  (8192, 4), (8214, 4), (8183, 4), (8187, 4), (8217, 4),
  (8251, 4), (8150, 4), (8236, 2), (8178, 4), (8153, 4),
  (8249, 4), (8129, 4), (8171, 4)
) AS v(card_id, quantity);

-- ============================================================
-- 3. シェリル&ランカ（超時空要塞 Delta / UA36BT，對應 Tier 表「トライアングラー」）
--    目前 Tier 表現役 Tier1。48/50 張（1 種卡「MCR-1-111」為 Starter 商品限定，
--    cards 表尚無資料，故該 2 張未列入，估價為 48 張的合計）。
-- ============================================================
WITH d AS (
  INSERT INTO public.recommended_decks (name, series_id, tier, summary, source)
  VALUES (
    'シェリル&ランカ(トライアングラー)',
    53,
    'Tier1',
    'シェリル・ノーム與ランカ・リー雙偶像併用牌組。48/50 張已對照（另 2 張為 Starter 限定商品版本，資料庫尚未收錄，估價未計入）。',
    'https://torecards.com/mcr/'
  )
  RETURNING id
)
INSERT INTO public.recommended_deck_cards (recommended_deck_id, card_id, quantity)
SELECT d.id, v.card_id, v.quantity
FROM d, (VALUES
  (6118, 4), (6123, 4), (6182, 3), (6136, 4), (6160, 4),
  (6092, 4), (6133, 4), (6088, 4), (6053, 3), (6071, 3),
  (6105, 4), (6176, 3), (6148, 4)
) AS v(card_id, quantity);

-- ============================================================
-- 4. CoMETIK（アイドルマスター シャイニーカラーズ / PC01BT + EX03BT）
--    目前 Tier 表現役 Tier1。50/50 張全數對照成功。
-- ============================================================
WITH d AS (
  INSERT INTO public.recommended_decks (name, series_id, tier, summary, source)
  VALUES (
    'CoMETIK',
    10,
    'Tier1',
    '鈴木羽那・郁田はるき・斑鳩ルカ三人組合「CoMETIK」牌組，リムーブエリア（移除區）資源運用為核心。50/50 張全數對照成功。',
    'https://torecards.com/shinycolors/'
  )
  RETURNING id
)
INSERT INTO public.recommended_deck_cards (recommended_deck_id, card_id, quantity)
SELECT d.id, v.card_id, v.quantity
FROM d, (VALUES
  (1008, 4), (991, 4), (990, 4), (1039, 4), (1055, 4),
  (980, 4), (1057, 4), (1035, 4), (966, 2), (1042, 4),
  (982, 4), (860, 4), (1006, 4)
) AS v(card_id, quantity);

-- ============================================================
-- 5. 式波・アスカ&真希波・マリ（新世紀福音戰士 / UA44BT）
--    取自 EVA 系列頁「サンプルデッキレシピ」輪播，內容以 WILLE 特徵為主軸，
--    無法百分之百確認是否對應 Tier 表上「迷宮攻略」或「シンジ&レイ」的確切命名，
--    先不標記為目前 Tier 表認定的 Tier1，僅標示為系列推薦牌組。
--    46/50 張（1 種卡「EVA-1-113」為 Starter 商品限定，cards 表尚無資料，
--    該 4 張未列入，估價為 46 張的合計）。
-- ============================================================
WITH d AS (
  INSERT INTO public.recommended_decks (name, series_id, tier, summary, source)
  VALUES (
    '式波・アスカ&真希波・マリ(WILLE)',
    61,
    NULL,
    'EVA 系列頁推薦牌組之一，[特徴:WILLE] 疊卡＋エヴァンゲリオン改8号機／新2号機終結。與 Tier 表命名「迷宮攻略」「シンジ&レイ」的對應關係未百分之百確認。46/50 張已對照（另 4 張為 Starter 限定商品版本，資料庫尚未收錄，估價未計入）。',
    'https://torecards.com/eva/'
  )
  RETURNING id
)
INSERT INTO public.recommended_deck_cards (recommended_deck_id, card_id, quantity)
SELECT d.id, v.card_id, v.quantity
FROM d, (VALUES
  (7204, 4), (7144, 4), (7117, 2), (7127, 2), (7226, 4),
  (7104, 4), (7190, 4), (7108, 4), (7230, 2), (7211, 4),
  (7135, 4), (7167, 4), (7215, 4)
) AS v(card_id, quantity);

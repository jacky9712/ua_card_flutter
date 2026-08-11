-- 初始資料庫結構（series / cards / price_history / decks / deck_cards）
-- 這份是「回填」進 repo 的歷史基準：這份 SQL 早在 20260801 那批 recommended_decks
-- migration 之前就已經在 Supabase Dashboard 手動執行過、正式跑在 production 上了，
-- 只是原本沒有存進版本控制。現在補進來，讓 supabase/migrations/ 底下有完整、可從
-- 頭重播的歷史紀錄。
--
-- ⚠️ 這份刻意保留「當初實際執行的樣子」，包含已知但當下還沒修的兩個問題：
--   1. series_popularity 用 COUNT(dc.id)（而非 SUM(dc.quantity)）
--   2. 沒有在 seed 之後校正 series 的 SERIAL sequence
-- 這兩個問題已經由後續的 20260803000000_fix_series_sequence_and_popularity.sql
-- 修正，照檔名順序重播即可得到正確的最終狀態。唯一主動修正的地方是 series 種子
-- 資料的 ON CONFLICT 目標，從 (id) 改成 (series_code)——這不影響这份檔案單獨重播
-- 的結果（76 筆資料一樣會照樣插入、id 一樣是 1~76，因為 series_code 本來就有
-- UNIQUE 約束、不會撞突），純粹是讓「之後想比照這個寫法手動加新系列」的人不會
-- 再踩進 SERIAL 序列撞主鍵的坑。
--
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。

-- ==========================================
-- 1. 系列表 (Series)
-- ==========================================
CREATE TABLE IF NOT EXISTS series (
  id SERIAL PRIMARY KEY,
  series_code TEXT UNIQUE NOT NULL,
  name_zh TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 2. 卡片表 (Cards)
-- ==========================================
CREATE TABLE IF NOT EXISTS cards (
  id SERIAL PRIMARY KEY,
  series_id INTEGER REFERENCES series(id),
  card_number TEXT NOT NULL,
  name TEXT NOT NULL,
  rarity TEXT,

  -- 🔥 稀有度補強欄位 (用於區分星卡、平行卡)
  is_parallel BOOLEAN DEFAULT FALSE,    -- 是否為 パラレル
  star_count INTEGER DEFAULT 0,         -- 星級 (★1, ★2, ★3)
  has_signature BOOLEAN DEFAULT FALSE,  -- 是否為 サイン (簽名)

  color TEXT,
  image_url TEXT,

  -- 遊戲數值
  card_type TEXT,
  bp INTEGER,
  ap_cost INTEGER DEFAULT 1,
  energy_req INTEGER DEFAULT 0,
  energy_generated INTEGER DEFAULT 0,
  tags TEXT[],
  effect_text TEXT,
  trigger_text TEXT,

  -- 唯一約束：卡號 + 稀有度 + 平行狀態 + 星數 + 簽名狀態 必須唯一
  -- 這樣同一個卡號才能同時存在「普通版」與「星卡版」
  CONSTRAINT cards_version_unique UNIQUE(card_number, rarity, is_parallel, star_count, has_signature)
);

-- 若表已存在，強制補上缺失欄位 (預防 Error 42703)
ALTER TABLE cards ADD COLUMN IF NOT EXISTS is_parallel BOOLEAN DEFAULT FALSE;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS star_count INTEGER DEFAULT 0;
ALTER TABLE cards ADD COLUMN IF NOT EXISTS has_signature BOOLEAN DEFAULT FALSE;

ALTER TABLE cards DROP CONSTRAINT IF EXISTS cards_version_unique;
ALTER TABLE cards ADD CONSTRAINT cards_version_unique UNIQUE (card_number, rarity, is_parallel, star_count, has_signature);

-- ==========================================
-- 3. 價格系統 (Price History)
-- ==========================================
CREATE TABLE IF NOT EXISTS price_history (
  id SERIAL PRIMARY KEY,
  card_id INTEGER REFERENCES cards(id),
  price_jpy REAL NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 最新價格視圖 (方便 Flutter 直接調用)
CREATE OR REPLACE VIEW latest_prices AS
SELECT DISTINCT ON (card_id)
    card_id,
    price_jpy,
    created_at
FROM price_history
ORDER BY card_id, created_at DESC;

-- 對戰環境排行視圖 (用於首頁 Dashboard)
-- ⚠️ 這裡刻意保留原始版本（COUNT(dc.id)），由
-- 20260803000000_fix_series_sequence_and_popularity.sql 接手改成 SUM(dc.quantity)。
CREATE OR REPLACE VIEW series_popularity AS
SELECT
  s.name_zh,
  s.series_code,
  COUNT(dc.id) as use_count,
  ROUND(COUNT(dc.id) * 100.0 / NULLIF(SUM(COUNT(dc.id)) OVER(), 0), 1) as share_rate
FROM series s
JOIN cards c ON c.series_id = s.id
JOIN deck_cards dc ON dc.card_id = c.id
GROUP BY s.id, s.name_zh, s.series_code
ORDER BY use_count DESC;

-- ==========================================
-- 4. 牌組管理 (Decks)
-- ==========================================
CREATE TABLE IF NOT EXISTS decks (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  series_id INTEGER REFERENCES series(id),
  cover_card_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS deck_cards (
  id SERIAL PRIMARY KEY,
  deck_id INTEGER REFERENCES decks(id) ON DELETE CASCADE,
  card_id INTEGER REFERENCES cards(id),
  quantity INTEGER NOT NULL CHECK (quantity > 0 AND quantity <= 4),
  UNIQUE(deck_id, card_id)
);

-- ==========================================
-- 5. 效能優化 (Indexes)
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_cards_series ON cards(series_id);
CREATE INDEX IF NOT EXISTS idx_cards_version_search ON cards(card_number, star_count, is_parallel);
CREATE INDEX IF NOT EXISTS idx_price_history_card ON price_history(card_id);
CREATE INDEX IF NOT EXISTS idx_decks_user ON decks(user_id);

-- ==========================================
-- 6. 安全性設定 (RLS)
-- ==========================================
ALTER TABLE decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE deck_cards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own decks" ON decks;
CREATE POLICY "Users can manage own decks" ON decks
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own deck cards" ON deck_cards;
CREATE POLICY "Users can manage own deck cards" ON deck_cards
  USING (
    EXISTS (SELECT 1 FROM decks WHERE id = deck_cards.deck_id AND user_id = auth.uid())
  );

-- --- 初始化資料 ---

INSERT INTO series (id, series_code, name_zh) VALUES
  (1, 'UA01BT', 'Code Geass 反叛的魯路修 第1彈'),
  (2, 'EX02BT', 'Code Geass 反叛的魯路修 第2彈'),
  (3, 'UA02BT', '咒術迴戰 第1彈'),
  (4, 'UA02NC', '咒術迴戰 書卡'),
  (5, 'EX04BT', '咒術迴戰 第2彈'),
  (6, 'UA03BT', 'HUNTER×HUNTER 獵人 第1彈'),
  (7, 'EX01BT', 'HUNTER×HUNTER 獵人 第2彈'),
  (8, 'UA04BT', '偶像大師 閃耀色彩 第1彈'),
  (9, 'EX03BT', '偶像大師 閃耀色彩 第2彈'),
  (10, 'PC01BT', '偶像大師 閃耀色彩 閃耀補充包'),
  (11, 'UA05BT', '鬼滅之刃 第1彈'),
  (12, 'UA01NC', '鬼滅之刃 書卡'),
  (13, 'EX05BT', '鬼滅之刃 第2彈'),
  (14, 'UA06BT', '破曉傳奇 Tales of ARISE'),
  (15, 'UA07BT', '關於我轉生變成史萊姆這檔事 第1彈'),
  (16, 'EX09BT', '關於我轉生變成史萊姆這檔事 第2彈'),
  (17, 'UA08BT', 'BLEACH 死神 第1彈'),
  (18, 'EX07BT', 'BLEACH 死神 第2彈'),
  (19, 'UA04NC', 'BLEACH 死神 書卡'),
  (20, 'UA09BT', '我與機器子'),
  (21, 'UA10BT', '我的英雄學院 第1彈'),
  (22, 'EX06BT', '我的英雄學院 第2彈'),
  (23, 'UA11BT', '銀魂'),
  (24, 'UA12BT', '藍色監獄 第1彈'),
  (25, 'UA03NC', '藍色監獄 書卡'),
  (26, 'UA13BT', '鐵拳 7'),
  (27, 'UA14BT', 'Dr.STONE 新石紀'),
  (28, 'UA15BT', '刀劍神域 第1彈'),
  (29, 'EX08BT', '刀劍神域 第2彈'),
  (30, 'UA16BT', '戰姬絕唱 SYMPHOGEAR'),
  (31, 'UA17BT', '美食獵人 TORIKO'),
  (32, 'UA18BT', '勝利女神：妮姬'),
  (33, 'UA19BT', '排球少年'),
  (34, 'UA20BT', '黑色五葉草'),
  (35, 'UA21BT', '幽遊白書'),
  (36, 'UA22BT', '加美拉 -Rebirth-'),
  (37, 'UA23BT', '進擊的巨人 第1彈'),
  (38, 'EX10BT', '進擊的巨人 第2彈'),
  (39, 'UA24BT', 'SHY 英雄'),
  (40, 'UA25BT', '不死不運'),
  (41, 'UA26BT', '超喜歡你的100個女朋友'),
  (42, 'UA27BT', '學園偶像大師'),
  (43, 'UA28BT', '怪獸 8 號'),
  (44, 'UA29BT', '假面騎士'),
  (45, 'EX12BT', '假面騎士 第2彈'),
  (46, 'UA30BT', '明日方舟 第1彈'),
  (47, 'EX11BT', '明日方舟 第2彈'),
  (48, 'UA31BT', '魔法少女小圓'),
  (49, 'UA32BT', '香格里拉·開拓者'),
  (50, 'UA33BT', '2.5 次元的誘惑'),
  (51, 'UA34BT', 'Code Geass 奪還的 Z'),
  (52, 'UA35BT', '一拳超人'),
  (53, 'UA36BT', '超時空要塞 Delta'),
  (54, 'UA37BT', '鋼之鍊金術師 FA'),
  (55, 'UA38BT', 'WIND BREAKER —防風少年—'),
  (56, 'UA39BT', '筋肉人'),
  (57, 'UA40BT', 'Re:從零開始的異世界生活'),
  (58, 'UA41BT', '浪客劍心'),
  (59, 'UA42BT', '物語系列'),
  (60, 'UA43BT', 'SAKAMOTO DAYS 坂本日常'),
  (61, 'UA44BT', '新世紀福音戰士'),
  (62, 'UA45BT', 'To LOVE 出包王女'),
  (63, 'UA46BT', '神樂鉢'),
  (64, 'UA47BT', '東京喰種'),
  (65, 'UA48BT', '王者天下'),
  (66, 'PC02BT', '勝利女神：妮姬 第2彈'),
  (67, 'UA49BT', '魔都精兵'),
  (68, 'UA51BT', '我獨自升級'),
  (69, 'UA52BT', '我想成為影之強者'),
  (70, 'UA53BT', '鏈鋸人'),
  (71, 'UA50BT', '犬夜叉'),
  (72, 'EX14BT', '超時空要塞 Delta 第2彈'),
  (73, 'UA54BT', '無職轉生'),
  (74, 'UA36ST', '超時空要塞 Delta 第2彈 預組'),
  (75, 'UA44ST', '新世紀福音戰士 預組'),
  (76, 'UA55BT', '偶像大師灰姑娘')
-- 🔥 修正：原本是 ON CONFLICT (id)，改成 ON CONFLICT (series_code)——
-- series_code 才是這份種子資料實際想拿來判斷「重複」的自然鍵，
-- 之後要追加新系列時可以直接用同樣的 INSERT 寫法，不用手動算下一個 id。
ON CONFLICT (series_code) DO UPDATE SET
  name_zh = EXCLUDED.name_zh;

-- 🔥 最後一步：強制刷新 API 快取
NOTIFY pgrst, 'reload config';

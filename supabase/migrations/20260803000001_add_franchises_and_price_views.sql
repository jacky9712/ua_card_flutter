-- 新增 franchises（IP 分組）+ 使用者牌組/推薦牌組的總價 view
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行
-- 冪等：重複執行不會報錯。
-- 前提：series 已存在且已有 76 筆資料（含 UA01BT ~ UA55BT 等）。

-- ============================================================
-- 1. franchises：IP 層級分組，一個 IP 底下可以有好幾彈 series
-- ============================================================
CREATE TABLE IF NOT EXISTS franchises (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name_zh TEXT NOT NULL
);

ALTER TABLE series ADD COLUMN IF NOT EXISTS franchise_id INTEGER REFERENCES franchises(id);
CREATE INDEX IF NOT EXISTS idx_series_franchise ON series(franchise_id);

INSERT INTO franchises (code, name_zh) VALUES
  ('CODE_GEASS', 'Code Geass 反叛的魯路修'),
  ('JJK', '咒術迴戰'),
  ('HXH', 'HUNTER×HUNTER 獵人'),
  ('IM_SHINY', '偶像大師 閃耀色彩'),
  ('KIMETSU', '鬼滅之刃'),
  ('TALES_ARISE', '破曉傳奇 Tales of ARISE'),
  ('TENSURA', '關於我轉生變成史萊姆這檔事'),
  ('BLEACH', 'BLEACH 死神'),
  ('WATASHI_TO_ROBOT', '我與機器子'),
  ('MY_HERO', '我的英雄學院'),
  ('GINTAMA', '銀魂'),
  ('BLUELOCK', '藍色監獄'),
  ('TEKKEN7', '鐵拳 7'),
  ('DR_STONE', 'Dr.STONE 新石紀'),
  ('SAO', '刀劍神域'),
  ('SYMPHOGEAR', '戰姬絕唱 SYMPHOGEAR'),
  ('TORIKO', '美食獵人 TORIKO'),
  ('NIKKE', '勝利女神：妮姬'),
  ('HAIKYU', '排球少年'),
  ('BLACK_CLOVER', '黑色五葉草'),
  ('YUYU_HAKUSHO', '幽遊白書'),
  ('GAMERA', '加美拉'),
  ('AOT', '進擊的巨人'),
  ('SHY', 'SHY 英雄'),
  ('FUSHIFUUN', '不死不運'),
  ('100_GF', '超喜歡你的100個女朋友'),
  ('IM_GAKUEN', '學園偶像大師'),
  ('KAIJU8', '怪獸 8 號'),
  ('KAMEN_RIDER', '假面騎士'),
  ('ARKNIGHTS', '明日方舟'),
  ('MADOKA', '魔法少女小圓'),
  ('SHANGRI_LA_FRONTIER', '香格里拉·開拓者'),
  ('2POINT5_JIGEN', '2.5 次元的誘惑'),
  ('ONE_PUNCH', '一拳超人'),
  ('MACROSS_DELTA', '超時空要塞 Delta'),
  ('FMA', '鋼之鍊金術師 FA'),
  ('WIND_BREAKER', 'WIND BREAKER —防風少年—'),
  ('KINNIKUMAN', '筋肉人'),
  ('RE_ZERO', 'Re:從零開始的異世界生活'),
  ('RUROUNI_KENSHIN', '浪客劍心'),
  ('MONOGATARI', '物語系列'),
  ('SAKAMOTO_DAYS', 'SAKAMOTO DAYS 坂本日常'),
  ('EVANGELION', '新世紀福音戰士'),
  ('TO_LOVE_RU', 'To LOVE 出包王女'),
  ('KAGURABACHI', '神樂鉢'),
  ('TOKYO_GHOUL', '東京喰種'),
  ('KINGDOM', '王者天下'),
  ('MATO_SEIHEI', '魔都精兵'),
  ('SOLO_LEVELING', '我獨自升級'),
  ('KAGENO_JITSURYOKUSHA', '我想成為影之強者'),
  ('CHAINSAW_MAN', '鏈鋸人'),
  ('INUYASHA', '犬夜叉'),
  ('MUSHOKU_TENSEI', '無職轉生'),
  ('IM_CINDERELLA', '偶像大師灰姑娘')
ON CONFLICT (code) DO UPDATE SET name_zh = EXCLUDED.name_zh;

-- 判斷不完全確定的地方，先這樣分，之後你覺得不對可以直接改 UPDATE：
--   * UA34BT「Code Geass 奪還的 Z」歸進 CODE_GEASS 大傘（劇情是別的角色/別的作品，但同 IP 系列）
--   * 「偶像大師」底下 IM_SHINY(閃耀色彩) / IM_GAKUEN(學園) / IM_CINDERELLA(灰姑娘) 三個是各自獨立
--     的 franchise，沒有再往上合併成一個「偶像大師」大分類，因為三者卡池/角色主題完全不同
--   * UA09BT「我與機器子」、UA25BT「不死不運」原始標題不確定，先各自獨立成單一 franchise

UPDATE series s
SET franchise_id = f.id
FROM franchises f,
(VALUES
  ('UA01BT','CODE_GEASS'), ('EX02BT','CODE_GEASS'), ('UA34BT','CODE_GEASS'),
  ('UA02BT','JJK'), ('UA02NC','JJK'), ('EX04BT','JJK'),
  ('UA03BT','HXH'), ('EX01BT','HXH'),
  ('UA04BT','IM_SHINY'), ('EX03BT','IM_SHINY'), ('PC01BT','IM_SHINY'),
  ('UA05BT','KIMETSU'), ('UA01NC','KIMETSU'), ('EX05BT','KIMETSU'),
  ('UA06BT','TALES_ARISE'),
  ('UA07BT','TENSURA'), ('EX09BT','TENSURA'),
  ('UA08BT','BLEACH'), ('EX07BT','BLEACH'), ('UA04NC','BLEACH'),
  ('UA09BT','WATASHI_TO_ROBOT'),
  ('UA10BT','MY_HERO'), ('EX06BT','MY_HERO'),
  ('UA11BT','GINTAMA'),
  ('UA12BT','BLUELOCK'), ('UA03NC','BLUELOCK'),
  ('UA13BT','TEKKEN7'),
  ('UA14BT','DR_STONE'),
  ('UA15BT','SAO'), ('EX08BT','SAO'),
  ('UA16BT','SYMPHOGEAR'),
  ('UA17BT','TORIKO'),
  ('UA18BT','NIKKE'), ('PC02BT','NIKKE'),
  ('UA19BT','HAIKYU'),
  ('UA20BT','BLACK_CLOVER'),
  ('UA21BT','YUYU_HAKUSHO'),
  ('UA22BT','GAMERA'),
  ('UA23BT','AOT'), ('EX10BT','AOT'),
  ('UA24BT','SHY'),
  ('UA25BT','FUSHIFUUN'),
  ('UA26BT','100_GF'),
  ('UA27BT','IM_GAKUEN'),
  ('UA28BT','KAIJU8'),
  ('UA29BT','KAMEN_RIDER'), ('EX12BT','KAMEN_RIDER'),
  ('UA30BT','ARKNIGHTS'), ('EX11BT','ARKNIGHTS'),
  ('UA31BT','MADOKA'),
  ('UA32BT','SHANGRI_LA_FRONTIER'),
  ('UA33BT','2POINT5_JIGEN'),
  ('UA35BT','ONE_PUNCH'),
  ('UA36BT','MACROSS_DELTA'), ('EX14BT','MACROSS_DELTA'), ('UA36ST','MACROSS_DELTA'),
  ('UA37BT','FMA'),
  ('UA38BT','WIND_BREAKER'),
  ('UA39BT','KINNIKUMAN'),
  ('UA40BT','RE_ZERO'),
  ('UA41BT','RUROUNI_KENSHIN'),
  ('UA42BT','MONOGATARI'),
  ('UA43BT','SAKAMOTO_DAYS'),
  ('UA44BT','EVANGELION'), ('UA44ST','EVANGELION'),
  ('UA45BT','TO_LOVE_RU'),
  ('UA46BT','KAGURABACHI'),
  ('UA47BT','TOKYO_GHOUL'),
  ('UA48BT','KINGDOM'),
  ('UA49BT','MATO_SEIHEI'),
  ('UA51BT','SOLO_LEVELING'),
  ('UA52BT','KAGENO_JITSURYOKUSHA'),
  ('UA53BT','CHAINSAW_MAN'),
  ('UA50BT','INUYASHA'),
  ('UA54BT','MUSHOKU_TENSEI'),
  ('UA55BT','IM_CINDERELLA')
) AS m(series_code, franchise_code)
WHERE m.franchise_code = f.code AND s.series_code = m.series_code;

-- 檢查有沒有漏分組的 series（正常應該回傳 0 筆）
-- SELECT series_code, name_zh FROM series WHERE franchise_id IS NULL;

-- ============================================================
-- 2. 我的牌組總價 view
--    ⚠️ deck_cards 有 RLS（只能看自己的牌組），view 預設會用「view 擁有者」的權限
--    去繞過 RLS，等於任何人都能查到別人牌組的總價。加 security_invoker = true
--    讓 view 改用「查詢者本人」的權限跑 RLS 檢查，才不會外洩。
-- ============================================================
CREATE OR REPLACE VIEW deck_total_price
WITH (security_invoker = true) AS
SELECT
  dc.deck_id,
  SUM(lp.price_jpy * dc.quantity) AS total_price,
  SUM(dc.quantity) AS total_cards
FROM deck_cards dc
JOIN latest_prices lp ON lp.card_id = dc.card_id
GROUP BY dc.deck_id;

-- ============================================================
-- 3. 推薦牌組總價 view
--    recommended_deck_cards 本來就是公開讀取（RLS policy using (true)），
--    不涉及個人資料，這裡 security_invoker 不是必要，但保留寫法一致、
--    以後如果 recommended_deck_cards 的 RLS 政策改嚴格，也不用回頭補。
-- ============================================================
CREATE OR REPLACE VIEW recommended_deck_total_price
WITH (security_invoker = true) AS
SELECT
  rdc.recommended_deck_id AS deck_id,
  SUM(lp.price_jpy * rdc.quantity) AS total_price,
  SUM(rdc.quantity) AS total_cards
FROM recommended_deck_cards rdc
JOIN latest_prices lp ON lp.card_id = rdc.card_id
GROUP BY rdc.recommended_deck_id;

-- 🔥 最後一步：強制刷新 API 快取
NOTIFY pgrst, 'reload config';

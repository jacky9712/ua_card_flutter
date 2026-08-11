-- 補齊缺漏系列：對照 unionarena-tcg.com 官網卡表頁的完整系列下拉選單，
-- 找出目前 76 筆 series 裡漏掉的部分。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行
-- 冪等：重複執行不會報錯。
--
-- 缺漏的 34 個系列：
--   - 33 個「預組」(Starter Deck，XXST)：幾乎每個 IP 都有出預組，但當初建表時
--     只收錄了 UA36ST／UA44ST 這兩個，其餘 33 個(UA01ST～UA55ST 之間)都漏掉了。
--   - 1 個正式彈：EX13BT（學園偶像大師 第2彈）—— 這個不是「預組」而是完整的
--     Vol.2 booster，同樣完全沒建到 series 表，也是「一年生」牌組匯入失敗
--     （0/50 對照成功）的根本原因。
--
-- 因為 20260803000000_fix_series_sequence_and_popularity.sql 已經校正過
-- series 的 SERIAL 序列，這裡可以直接用「不指定 id」的寫法插入，交給序列自動配號。

INSERT INTO series (series_code, name_zh) VALUES
  ('UA01ST', 'Code Geass 反叛的魯路修 預組'),
  ('UA02ST', '咒術迴戰 預組'),
  ('UA03ST', 'HUNTER×HUNTER 獵人 預組'),
  ('UA04ST', '偶像大師 閃耀色彩 預組'),
  ('UA05ST', '鬼滅之刃 預組'),
  ('UA06ST', '破曉傳奇 Tales of ARISE 預組'),
  ('UA07ST', '關於我轉生變成史萊姆這檔事 預組'),
  ('UA08ST', 'BLEACH 死神 預組'),
  ('UA09ST', '我與機器子 預組'),
  ('UA10ST', '我的英雄學院 預組'),
  ('UA11ST', '銀魂 預組'),
  ('UA12ST', '藍色監獄 預組'),
  ('UA13ST', '鐵拳 7 預組'),
  ('UA14ST', 'Dr.STONE 新石紀 預組'),
  ('UA15ST', '刀劍神域 預組'),
  ('UA16ST', '戰姬絕唱 SYMPHOGEAR 預組'),
  ('UA17ST', '美食獵人 TORIKO 預組'),
  ('UA18ST', '勝利女神：妮姬 預組'),
  ('UA19ST', '排球少年 預組'),
  ('UA20ST', '黑色五葉草 預組'),
  ('UA21ST', '幽遊白書 預組'),
  ('UA23ST', '進擊的巨人 預組'),
  ('UA29ST', '假面騎士 預組'),
  ('UA30ST', '明日方舟 預組'),
  ('UA31ST', '魔法少女小圓 預組'),
  ('UA35ST', '一拳超人 預組'),
  ('UA37ST', '鋼之鍊金術師 FA 預組'),
  ('UA40ST', 'Re:從零開始的異世界生活 預組'),
  ('UA41ST', '浪客劍心 預組'),
  ('UA42ST', '物語系列 預組'),
  ('UA47ST', '東京喰種 預組'),
  ('UA48ST', '王者天下 預組'),
  ('UA55ST', '偶像大師灰姑娘 預組'),
  ('EX13BT', '學園偶像大師 第2彈')
ON CONFLICT (series_code) DO UPDATE SET name_zh = EXCLUDED.name_zh;

-- 每個新系列的 franchise，直接沿用跟它同號 BT 系列相同的分組。
UPDATE series s
SET franchise_id = f.id
FROM franchises f,
(VALUES
  ('UA01ST','CODE_GEASS'),
  ('UA02ST','JJK'),
  ('UA03ST','HXH'),
  ('UA04ST','IM_SHINY'),
  ('UA05ST','KIMETSU'),
  ('UA06ST','TALES_ARISE'),
  ('UA07ST','TENSURA'),
  ('UA08ST','BLEACH'),
  ('UA09ST','WATASHI_TO_ROBOT'),
  ('UA10ST','MY_HERO'),
  ('UA11ST','GINTAMA'),
  ('UA12ST','BLUELOCK'),
  ('UA13ST','TEKKEN7'),
  ('UA14ST','DR_STONE'),
  ('UA15ST','SAO'),
  ('UA16ST','SYMPHOGEAR'),
  ('UA17ST','TORIKO'),
  ('UA18ST','NIKKE'),
  ('UA19ST','HAIKYU'),
  ('UA20ST','BLACK_CLOVER'),
  ('UA21ST','YUYU_HAKUSHO'),
  ('UA23ST','AOT'),
  ('UA29ST','KAMEN_RIDER'),
  ('UA30ST','ARKNIGHTS'),
  ('UA31ST','MADOKA'),
  ('UA35ST','ONE_PUNCH'),
  ('UA37ST','FMA'),
  ('UA40ST','RE_ZERO'),
  ('UA41ST','RUROUNI_KENSHIN'),
  ('UA42ST','MONOGATARI'),
  ('UA47ST','TOKYO_GHOUL'),
  ('UA48ST','KINGDOM'),
  ('UA55ST','IM_CINDERELLA'),
  ('EX13BT','IM_GAKUEN')
) AS m(series_code, franchise_code)
WHERE m.franchise_code = f.code AND s.series_code = m.series_code;

-- 檢查有沒有漏分組的 series（正常應該回傳 0 筆）
-- SELECT series_code, name_zh FROM series WHERE franchise_id IS NULL;

NOTIFY pgrst, 'reload config';

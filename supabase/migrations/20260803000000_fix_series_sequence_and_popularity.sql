-- 修正 series 的 id 序列錯位，以及 series_popularity 視圖的用量計算
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行
-- 冪等：重複執行不會報錯。

-- ============================================================
-- 1. 修正 series_id_seq 錯位
--    原本的 seed 腳本用「INSERT INTO series (id, ...) VALUES (1, ...), (2, ...) ...」
--    手動指定 id，序列（sequence）完全沒被推進，還停在初始值。
--    之後只要有一次「不指定 id」的 INSERT，序列給出的號碼會跟既有資料撞主鍵。
--    這裡把序列位置校正到目前資料的最大值，讓「以後」的 INSERT 不會出錯。
-- ============================================================
SELECT setval(
  pg_get_serial_sequence('series', 'id'),
  COALESCE((SELECT MAX(id) FROM series), 1)
);

-- ============================================================
-- 2. 修正 series_popularity 視圖：改用「實際張數」而非「出現的 deck_cards 列數」
--    COUNT(dc.id) 算的是「這張卡出現在幾副牌組裡」，一副牌放 4 張同卡只算 1。
--    改成 SUM(dc.quantity) 才是真正被使用的張數，排行榜/佔比才準確。
-- ============================================================
CREATE OR REPLACE VIEW series_popularity AS
SELECT
  s.name_zh,
  s.series_code,
  SUM(dc.quantity) AS use_count,
  ROUND(SUM(dc.quantity) * 100.0 / NULLIF(SUM(SUM(dc.quantity)) OVER (), 0), 1) AS share_rate
FROM series s
JOIN cards c ON c.series_id = s.id
JOIN deck_cards dc ON dc.card_id = c.id
GROUP BY s.id, s.name_zh, s.series_code
ORDER BY use_count DESC;

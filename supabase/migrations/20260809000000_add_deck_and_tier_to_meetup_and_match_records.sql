-- 約戰地點補上「選牌組」欄位（原本完全沒有）；約戰地點跟戰績紀錄都補上「T級」
-- 自評欄位（使用者自己標記 Tier1~Tier6，純自我評估，不比對資料庫）。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。

-- deck_id 允許 NULL、搭配 deck_name_snapshot，理由跟 match_records.player_deck_id 一樣：
-- 本地（未同步）牌組的 id 是負數、不在 decks 表裡，選那種牌組時 deck_id 就留 NULL，
-- 只存快照名稱；牌組之後被刪掉也不影響貼文本身。
alter table public.meetup_posts add column if not exists deck_id integer references public.decks(id) on delete set null;
alter table public.meetup_posts add column if not exists deck_name_snapshot text;
alter table public.meetup_posts add column if not exists deck_tier text;

alter table public.match_records add column if not exists deck_tier text;

notify pgrst, 'reload config';

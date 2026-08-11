-- 讓 recommended_decks 可以用 (name, series_id) 當 upsert 的 on_conflict 目標，
-- 這樣 ua_card_py 的爬蟲重跑時不會一直疊加出重複的牌組列。
-- 冪等：重複執行不會報錯。

create unique index if not exists recommended_decks_name_series_id_idx
  on public.recommended_decks (name, series_id);

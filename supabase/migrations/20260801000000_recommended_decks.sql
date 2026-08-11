-- 上位卡組推薦 (Recommended / Meta Decks)
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行
-- 這份是冪等的（idempotent），重複執行不會報錯，也會把舊版已建立的資料表修正成最新結構。

create table if not exists public.recommended_decks (
  id bigint generated always as identity primary key,
  name text not null,
  series_id bigint references public.series(id),
  -- 直接存來源原始的分級字串（例如 torecards 的 "Tier1"、"Tier1.5"…「Tier1」~「Tier6」剛好是
  -- 個位數，用文字遞增排序即可正確排序，不用額外的排序欄位）；社群/自家熱門度來源可留空。
  tier text,
  win_rate numeric(5, 2),
  summary text,
  cover_card_url text,
  source text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 舊版 tier 欄位曾經是 `not null default 'B' check (tier in ('S','A','B','C'))`，
-- 如果資料表是用舊版建立的，這裡把限制放寬成純文字。
alter table public.recommended_decks drop constraint if exists recommended_decks_tier_check;
alter table public.recommended_decks alter column tier drop not null;
alter table public.recommended_decks alter column tier drop default;

create table if not exists public.recommended_deck_cards (
  id bigint generated always as identity primary key,
  recommended_deck_id bigint not null references public.recommended_decks(id) on delete cascade,
  card_id bigint not null references public.cards(id),
  quantity int not null check (quantity between 1 and 4),
  unique (recommended_deck_id, card_id)
);

create index if not exists idx_recommended_deck_cards_deck_id
  on public.recommended_deck_cards (recommended_deck_id);

alter table public.recommended_decks enable row level security;
alter table public.recommended_deck_cards enable row level security;

-- 前台只需要讀取；新增/編輯牌組請用 Supabase Dashboard 或 service role 進行
drop policy if exists "Public read recommended decks" on public.recommended_decks;
create policy "Public read recommended decks"
  on public.recommended_decks for select
  using (true);

drop policy if exists "Public read recommended deck cards" on public.recommended_deck_cards;
create policy "Public read recommended deck cards"
  on public.recommended_deck_cards for select
  using (true);

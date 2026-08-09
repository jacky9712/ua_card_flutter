-- 分享位置 + 紀錄打牌勝敗：第二支 migration，功能本體。
-- 前提：20260808000000_profiles_and_known_opponents.sql 已經跑過。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。

-- ============================================================
-- meetup_posts：「約戰地點」——靜態、有排定時間的約戰貼文。
-- 用單純經緯度（double precision），不用 PostGIS：資料量小，距離排序放
-- Flutter 端用 Geolocator.distanceBetween 算就夠了，不用另外處理地理索引。
-- ============================================================
-- user_id 參照 profiles(id)（不是 auth.users(id)）——理由跟 known_opponents 一樣：
-- 只有這樣 PostgREST 巢狀 select 才能直接 join 出發文者的 display_name。
create table if not exists public.meetup_posts (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  location_name text not null,
  lat double precision,
  lng double precision,
  note text,
  scheduled_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours')
);

create index if not exists idx_meetup_posts_expires on public.meetup_posts(expires_at);
create index if not exists idx_meetup_posts_user on public.meetup_posts(user_id);

alter table public.meetup_posts enable row level security;

drop policy if exists "Public read open meetup posts" on public.meetup_posts;
create policy "Public read open meetup posts"
  on public.meetup_posts for select
  using (expires_at > now());

drop policy if exists "Owner manages own meetup posts" on public.meetup_posts;
create policy "Owner manages own meetup posts"
  on public.meetup_posts for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- live_locations：「分享真實地理位置」——即時、明確選填分享時長，一人只有一筆
-- （upsert，不是歷史紀錄表），到期後其他人就查不到（RLS 直接擋掉，不用另外清理）。
-- ============================================================
create table if not exists public.live_locations (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null
);

alter table public.live_locations enable row level security;

drop policy if exists "Public read active live locations" on public.live_locations;
create policy "Public read active live locations"
  on public.live_locations for select
  using (expires_at > now());

drop policy if exists "Owner manages own live location" on public.live_locations;
create policy "Owner manages own live location"
  on public.live_locations for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================
-- match_records：紀錄打牌勝敗。opponent_id 只能唯讀查自己被記錄的那些
-- （信任制，沒有確認/拒絕流程，是跟使用者確認過的設計）。
-- player_deck_id 允許 NULL，搭配 deck_name_snapshot：本地（未同步）牌組
-- 也能被選，牌組之後被刪掉也不影響歷史紀錄本身。
-- 注意：decks.id 是 SERIAL（integer），FK 型別要對上，不是 bigint。
-- player_id / opponent_id 參照 profiles(id) 而不是 auth.users(id)，理由同上——
-- 要靠這個 FK 才能巢狀 select 出對手/自己的 display_name。
--
-- opponent_id 允許 NULL、搭配 opponent_name_text：對手沒有這個 App 的帳號、
-- 或還沒掃過 QR 加成已知對手時，也能先用自由文字記一筆（使用者實測後反映
-- 「限定要選已知對手」太綁）。兩者至少要有一個，不能整筆都沒有對手資訊。
-- 用文字記的這種，對手自然看不到這筆紀錄（沒有帳號可以套 RLS）。
-- ============================================================
create table if not exists public.match_records (
  id bigint generated always as identity primary key,
  player_id uuid not null references public.profiles(id) on delete cascade,
  opponent_id uuid references public.profiles(id) on delete cascade,
  opponent_name_text text,
  player_deck_id integer references public.decks(id) on delete set null,
  deck_name_snapshot text,
  result text not null check (result in ('win', 'loss', 'draw')),
  played_at timestamptz not null default now(),
  note text,
  meetup_post_id bigint references public.meetup_posts(id) on delete set null,
  created_at timestamptz not null default now(),
  check (player_id <> opponent_id),
  check (opponent_id is not null or opponent_name_text is not null)
);

-- 如果這支 migration 是第二次以後執行（表已經存在、當時 opponent_id 還是 not null），
-- 這幾行負責把既有的表補成上面的新結構；表是新建的話這幾行都是 no-op。
alter table public.match_records add column if not exists opponent_name_text text;
alter table public.match_records alter column opponent_id drop not null;
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.match_records'::regclass
      and conname = 'match_records_opponent_present_check'
  ) then
    alter table public.match_records
      add constraint match_records_opponent_present_check
      check (opponent_id is not null or opponent_name_text is not null);
  end if;
end $$;

create index if not exists idx_match_records_player on public.match_records(player_id);
create index if not exists idx_match_records_opponent on public.match_records(opponent_id);

alter table public.match_records enable row level security;

drop policy if exists "Player manages own match records" on public.match_records;
create policy "Player manages own match records"
  on public.match_records for all
  using (auth.uid() = player_id) with check (auth.uid() = player_id);

drop policy if exists "Opponent reads match records about them" on public.match_records;
create policy "Opponent reads match records about them"
  on public.match_records for select
  using (auth.uid() = opponent_id);

notify pgrst, 'reload config';

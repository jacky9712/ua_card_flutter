-- 分享位置 + 紀錄打牌勝敗：第一支 migration，身分前提。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。

-- ============================================================
-- profiles：每個 auth 使用者（含匿名）都有一筆公開可讀的最小身分資料。
-- App 目前預設訪客也是無感匿名登入，匿名使用者原本完全沒有任何可辨識的名稱，
-- 這張表是「掃 QR 加對手」「戰績紀錄顯示對手是誰」的前提。
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Public read profiles" on public.profiles;
create policy "Public read profiles"
  on public.profiles for select
  using (true);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile"
  on public.profiles for update
  using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Users insert own profile" on public.profiles;
create policy "Users insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- 每個新的 auth.users（含匿名登入）都自動建一筆空白 profiles，
-- 不依賴 App 端一定會記得呼叫 upsert（客戶端可能中途崩潰、漏呼叫）。
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill：這支 migration 執行之前就已經存在的使用者（含匿名）。
insert into public.profiles (id)
select id from auth.users
on conflict (id) do nothing;

-- ============================================================
-- known_opponents：「掃過 QR 認識的人」清單，私人、跟有沒有真的記錄過對戰無關。
-- match_records 的 opponent_id 直接參照 auth.users，不強制要求先出現在這張表。
-- ============================================================
-- 注意：owner_id / opponent_id 參照 profiles(id) 而不是 auth.users(id)——
-- 兩者的值永遠一致（profiles.id 本身就是 1:1 對應 auth.users.id，且有上面的
-- trigger 保證一定存在），但只有參照 profiles 才會有 PostgREST 能用來做巢狀
-- select（'profiles(display_name)' 這種寫法）的外鍵關聯，參照 auth.users 查不到。
create table if not exists public.known_opponents (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  opponent_id uuid not null references public.profiles(id) on delete cascade,
  nickname text,
  created_at timestamptz not null default now(),
  unique (owner_id, opponent_id),
  check (owner_id <> opponent_id)
);

create index if not exists idx_known_opponents_owner on public.known_opponents(owner_id);

alter table public.known_opponents enable row level security;

drop policy if exists "Owner manages known opponents" on public.known_opponents;
create policy "Owner manages known opponents"
  on public.known_opponents for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

notify pgrst, 'reload config';

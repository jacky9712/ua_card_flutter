-- 牌組分享代碼：玩家產生 6 位數數字代碼（24 小時有效、每次產生都是新的），
-- 對方（含同專案的 ua_card_game）用代碼取回 `UA_DECK|<card_number>:<qty>,...` 字串。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。

-- ============================================================
-- deck_share_codes：代碼 -> 牌組字串。過期的列不主動清除，只在代碼碰撞時被覆寫。
-- ============================================================
create table if not exists public.deck_share_codes (
  code char(6) primary key check (code ~ '^[0-9]{6}$'),
  deck_string text not null,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

alter table public.deck_share_codes enable row level security;

-- 刻意不開任何 policy（RLS 下等於全拒）、並收回所有 table 權限：
-- 只能透過下面兩支 SECURITY DEFINER RPC 存取，避免代碼被直接列舉。
drop policy if exists "No direct access to deck share codes" on public.deck_share_codes;

revoke all on table public.deck_share_codes from public, anon, authenticated;

-- ============================================================
-- create_deck_share_code：驗證牌組字串後，配一組未被使用（或已過期）的 6 位數代碼。
-- OUT 欄位 code / expires_at 與表格欄位同名，函式內一律使用限定名稱避免 ambiguous。
-- ============================================================
drop function if exists public.create_deck_share_code(text);
create or replace function public.create_deck_share_code(deck_string text)
returns table(code text, expires_at timestamptz)
language plpgsql
volatile
security definer set search_path = public
as $$
declare
  v_code text;
  v_expires timestamptz := now() + interval '24 hours';
  v_rows int;
  v_attempt int := 0;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  -- 比照 ua_card_game 的嚴格 parser：前綴 UA_DECK|、無空白、無空 pair、張數 >= 1
  if create_deck_share_code.deck_string is null
     or length(create_deck_share_code.deck_string) > 4000
     or create_deck_share_code.deck_string !~ '^UA_DECK\|[^,:[:space:]]+:[1-9][0-9]*(,[^,:[:space:]]+:[1-9][0-9]*)*$' then
    raise exception 'invalid deck_string' using errcode = '22023';
  end if;

  loop
    v_attempt := v_attempt + 1;
    if v_attempt > 20 then
      raise exception 'could not allocate deck share code' using errcode = '53400';
    end if;

    v_code := lpad(floor(random() * 1000000)::int::text, 6, '0');

    -- 用 on conflict on constraint 而不是 on conflict (code)，避開與 OUT 參數 code 的 ambiguity。
    -- 只有已過期的列可以被覆寫；未過期的碰撞 row_count = 0，重抽一次。
    insert into public.deck_share_codes as d (code, deck_string, created_by, created_at, expires_at)
    values (v_code, create_deck_share_code.deck_string, auth.uid(), now(), v_expires)
    on conflict on constraint deck_share_codes_pkey do update
      set deck_string = excluded.deck_string,
          created_by = excluded.created_by,
          created_at = excluded.created_at,
          expires_at = excluded.expires_at
      where d.expires_at <= now();

    get diagnostics v_rows = row_count;
    if v_rows = 1 then
      code := v_code;
      expires_at := v_expires;
      return next;
      return;
    end if;
  end loop;
end;
$$;

-- ============================================================
-- resolve_deck_share_code：代碼 -> 牌組字串；不存在或已過期回傳 null。
-- SQL 函式裡同名欄位優先於參數，所以參數用 $1；先用正則擋，因為 ::char(6) 會靜默截斷過長輸入。
-- ============================================================
drop function if exists public.resolve_deck_share_code(text);
create or replace function public.resolve_deck_share_code(code text)
returns text
language sql
stable
security definer set search_path = public
as $$
  select d.deck_string
  from public.deck_share_codes d
  where $1 ~ '^[0-9]{6}$'
    and d.code = $1::char(6)
    and d.expires_at > now();
$$;

revoke all on function public.create_deck_share_code(text) from public, anon;
grant execute on function public.create_deck_share_code(text) to authenticated;

revoke all on function public.resolve_deck_share_code(text) from public, anon;
grant execute on function public.resolve_deck_share_code(text) to authenticated;

notify pgrst, 'reload schema';

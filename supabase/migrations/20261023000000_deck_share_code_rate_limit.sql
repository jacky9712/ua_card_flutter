-- 牌組分享代碼的速率限制：同一個使用者（含匿名登入）每小時最多產生 20 組代碼，
-- 避免腳本在 24 小時內塞滿 100 萬組的代碼空間（正常使用者會一直撞到「配不到代碼」，也讓亂猜更容易命中）。
-- 前提：20261022000000_deck_share_codes.sql 已經執行過。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。

-- 每次產生都要數「這個人最近一小時產生了幾組」，加索引讓它不用掃整張表。
create index if not exists deck_share_codes_created_by_created_at_idx
  on public.deck_share_codes (created_by, created_at);

-- ============================================================
-- create_deck_share_code：跟 20261022000000 的版本相同，只多了開頭的速率限制。
-- 用 create or replace（不先 drop），既有的 grant 會保留；結尾仍重新設定一次權限，確保冪等。
-- 超過上限時丟 errcode 'UA429'，App 端（DeckShareCodeRepository）據此顯示「產生次數太多」。
-- ============================================================
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
  v_recent int;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select count(*) into v_recent
  from public.deck_share_codes d
  where d.created_by = auth.uid()
    and d.created_at > now() - interval '1 hour';
  if v_recent >= 20 then
    raise exception 'deck share code rate limit exceeded' using errcode = 'UA429';
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

revoke all on function public.create_deck_share_code(text) from public, anon;
grant execute on function public.create_deck_share_code(text) to authenticated;

notify pgrst, 'reload schema';

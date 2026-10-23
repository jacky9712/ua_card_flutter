-- 牌組分享代碼：有效期限從 24 小時延長到 7 天，並在每次產生代碼時順手刪掉已過期的代碼。
-- 7 天讓貼到群組、隔幾天才有人用的代碼還能查得到；每人每小時 20 組的速率限制不變。
-- 前提：20261022000000_deck_share_codes.sql、20261023000000_deck_share_code_rate_limit.sql 已經執行過。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。
-- 注意：之後若重跑前兩份 migration，會把函式換回舊版（24 小時、不清理），要再跑一次這份。

-- 清理過期代碼用的索引。
create index if not exists deck_share_codes_expires_at_idx
  on public.deck_share_codes (expires_at);

-- ============================================================
-- create_deck_share_code：跟 20261023000000 的版本相同，只改了有效期限（7 天）並加上清理過期代碼。
-- ============================================================
create or replace function public.create_deck_share_code(deck_string text)
returns table(code text, expires_at timestamptz)
language plpgsql
volatile
security definer set search_path = public
as $$
declare
  v_code text;
  v_expires timestamptz := now() + interval '7 days';
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

  -- 順手清掉已過期的代碼，不需要另外排程；有 expires_at 索引，沒東西可刪時很便宜。
  -- 速率限制只看最近一小時建立的列，過期的列早已超過 7 天，刪掉不影響計數。
  delete from public.deck_share_codes d where d.expires_at <= now();

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

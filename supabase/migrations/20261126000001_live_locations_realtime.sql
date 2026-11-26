-- 即時位置清單即時更新：把 live_locations 加進 Supabase Realtime 的 publication。
-- 別人（或同帳號的另一台裝置）開始/停止分享時，App 會自動重抓清單、同步自己的分享狀態。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'live_locations'
  ) then
    alter publication supabase_realtime add table public.live_locations;
  end if;
end $$;

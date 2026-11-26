-- 約戰地點清單即時更新：把 meetup_posts 加進 Supabase Realtime 的 publication，
-- App 端訂閱 postgres_changes，別人新增/編輯/取消貼文時清單會自動重抓。
-- Realtime 會套用既有 RLS（一般使用者只會收到 expires_at > now() 的列）。
-- 執行方式：Supabase Dashboard -> SQL Editor -> 貼上整份執行（冪等，可重複執行）。
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'meetup_posts'
  ) then
    alter publication supabase_realtime add table public.meetup_posts;
  end if;
end $$;

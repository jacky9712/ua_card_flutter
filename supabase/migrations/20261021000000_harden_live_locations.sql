-- ============================================================
-- live_locations 資安補強
--
-- 1. 讀取限定登入使用者：原本的 select policy 沒指定角色，anon key 又打包在 App 裡，
--    等於任何人不用登入就能撈到所有正在分享的人的座標。
-- 2. 時間與座標交給伺服器決定（trigger），不信任前端送來的值：
--    - updated_at 一律用 now()
--    - expires_at 最多 now() + 2 小時（App 選單最長就是 2 小時），改過的客戶端
--      也沒辦法「永久分享」
--    - lat/lng 四捨五入到小數第 3 位（約 110 公尺），夠約在店裡碰面，
--      但不會精準到住家門牌
-- ============================================================

drop policy if exists "Public read active live locations" on public.live_locations;
drop policy if exists "Authenticated read active live locations" on public.live_locations;
create policy "Authenticated read active live locations"
  on public.live_locations for select
  to authenticated
  using (expires_at > now());

create or replace function public.sanitize_live_location()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  new.expires_at := least(new.expires_at, now() + interval '2 hours');
  new.lat := round(new.lat::numeric, 3)::double precision;
  new.lng := round(new.lng::numeric, 3)::double precision;
  return new;
end;
$$;

drop trigger if exists sanitize_live_location on public.live_locations;
create trigger sanitize_live_location
  before insert or update on public.live_locations
  for each row execute function public.sanitize_live_location();

-- 既有資料也套用同樣的規則（trigger 只管之後寫入的）。
update public.live_locations set lat = lat;

-- شغّل الملف ده مرة واحدة في Supabase ← SQL Editor
-- بيجهّز تحديث التطبيق من جوه التطبيق (لوحة الأدمن)

create table if not exists public.app_admins (email text primary key);
insert into public.app_admins (email) values ('dawahplatform2026@gmail.com') on conflict do nothing;
alter table public.app_admins enable row level security;   -- مفيش سياسات: محدش يقراها من التطبيق

create or replace function public.is_app_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_admins where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')))
$$;

create table if not exists public.app_updates (
  version    int primary key,
  notes      text,
  html       text not null,
  created_at timestamptz not null default now()
);
alter table public.app_updates enable row level security;

drop policy if exists "updates read"   on public.app_updates;
drop policy if exists "updates insert" on public.app_updates;
drop policy if exists "updates delete" on public.app_updates;
create policy "updates read"   on public.app_updates for select using (true);
create policy "updates insert" on public.app_updates for insert to authenticated with check (public.is_app_admin());
create policy "updates delete" on public.app_updates for delete to authenticated using (public.is_app_admin());

grant select on public.app_updates to anon, authenticated;
grant insert, delete on public.app_updates to authenticated;

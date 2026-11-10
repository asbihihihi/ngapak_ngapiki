create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null check (length(btrim(full_name)) > 0),
  created_at timestamptz not null default now()
);

create table public.farms (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) > 0),
  created_at timestamptz not null default now()
);

create table public.farm_members (
  farm_id uuid not null references public.farms (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'employee')),
  created_at timestamptz not null default now(),
  primary key (farm_id, user_id)
);

create index farm_members_user_id_idx on public.farm_members (user_id);

alter table public.profiles enable row level security;
alter table public.farms enable row level security;
alter table public.farm_members enable row level security;

create function public.is_farm_member(p_farm_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.farm_members as member
    where member.farm_id = p_farm_id
      and member.user_id = (select auth.uid())
  );
$$;

create function public.is_farm_owner(p_farm_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.farm_members as member
    where member.farm_id = p_farm_id
      and member.user_id = (select auth.uid())
      and member.role = 'owner'
  );
$$;

create function public.create_farm(p_name text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  new_farm_id uuid;
  clean_name text := btrim(coalesce(p_name, ''));
begin
  if current_user_id is null then
    raise exception 'Sign in before creating a farm.';
  end if;

  if clean_name = '' then
    raise exception 'Farm name cannot be empty.';
  end if;

  insert into public.farms (name)
  values (clean_name)
  returning id into new_farm_id;

  insert into public.farm_members (farm_id, user_id, role)
  values (new_farm_id, current_user_id, 'owner');

  insert into public.profiles (id, full_name)
  values (current_user_id, clean_name)
  on conflict (id) do update
    set full_name = excluded.full_name;

  return new_farm_id;
end;
$$;

revoke all on function public.is_farm_member(uuid) from public, anon;
revoke all on function public.is_farm_owner(uuid) from public, anon;
revoke all on function public.create_farm(text) from public, anon;
grant execute on function public.is_farm_member(uuid) to authenticated;
grant execute on function public.is_farm_owner(uuid) to authenticated;
grant execute on function public.create_farm(text) to authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select, update on public.farms to authenticated;
grant select, insert, delete on public.farm_members to authenticated;

create policy "Users can read their own profile"
on public.profiles for select to authenticated
using (id = (select auth.uid()));

create policy "Users can create their own profile"
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));

create policy "Users can update their own profile"
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "Farm members can read their farms"
on public.farms for select to authenticated
using (public.is_farm_member(id));

create policy "Owners can update their farms"
on public.farms for update to authenticated
using (public.is_farm_owner(id))
with check (public.is_farm_owner(id));

create policy "Farm members can read membership"
on public.farm_members for select to authenticated
using (public.is_farm_member(farm_id));

create policy "Owners can add employees"
on public.farm_members for insert to authenticated
with check (
  role = 'employee'
  and public.is_farm_owner(farm_id)
);

create policy "Owners can remove employees"
on public.farm_members for delete to authenticated
using (
  role = 'employee'
  and public.is_farm_owner(farm_id)
);

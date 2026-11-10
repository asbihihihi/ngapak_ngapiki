alter table public.profiles
add column username text;

create unique index profiles_username_unique
on public.profiles (lower(username))
where username is not null;

alter table public.farm_members
drop constraint farm_members_user_id_fkey;

alter table public.farm_members
add constraint farm_members_user_id_fkey
foreign key (user_id) references public.profiles (id) on delete cascade;

revoke update on public.profiles from authenticated;
grant update (full_name) on public.profiles to authenticated;

create policy "Owners can read employee profiles"
on public.profiles for select to authenticated
using (
  exists (
    select 1
    from public.farm_members as employee_membership
    where employee_membership.user_id = profiles.id
      and employee_membership.role = 'employee'
      and public.is_farm_owner(employee_membership.farm_id)
  )
);

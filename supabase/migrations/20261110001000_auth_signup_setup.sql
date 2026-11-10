create function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  user_name text := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Pengguna'
  );
  farm_name text := nullif(
    btrim(coalesce(new.raw_user_meta_data ->> 'farm_name', '')),
    ''
  );
  new_farm_id uuid;
begin
  insert into public.profiles (id, full_name)
  values (new.id, user_name)
  on conflict (id) do update
    set full_name = excluded.full_name;

  if farm_name is not null then
    insert into public.farms (name)
    values (farm_name)
    returning id into new_farm_id;

    insert into public.farm_members (farm_id, user_id, role)
    values (new_farm_id, new.id, 'owner');
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

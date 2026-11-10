create table public.farm_sync_records (
  farm_id uuid not null references public.farms (id) on delete cascade,
  box_name text not null check (
    box_name in (
      'dombaBox',
      'penjualanBox',
      'bobotDombaBox',
      'aktivitasDombaBox',
      'batchBox',
      'barangBox',
      'pergerakanGudangBox',
      'keuanganBox',
      'posProductBox',
      'posSaleBox',
      'dailyReportBox',
      'healthRecordBox'
    )
  ),
  record_id uuid not null,
  payload jsonb,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  updated_by uuid not null,
  primary key (farm_id, box_name, record_id),
  check (
    (deleted_at is null and payload is not null)
    or (deleted_at is not null and payload is null)
  )
);

create index farm_sync_records_updated_idx
on public.farm_sync_records (farm_id, updated_at);

alter table public.farm_sync_records enable row level security;

grant select, insert, update on public.farm_sync_records to authenticated;

create policy "Farm members can read synchronized data"
on public.farm_sync_records for select to authenticated
using (public.is_farm_member(farm_id));

create policy "Farm members can insert synchronized data"
on public.farm_sync_records for insert to authenticated
with check (
  public.is_farm_member(farm_id)
  and updated_by = (select auth.uid())
);

create policy "Farm members can update synchronized data"
on public.farm_sync_records for update to authenticated
using (public.is_farm_member(farm_id))
with check (
  public.is_farm_member(farm_id)
  and updated_by = (select auth.uid())
);

create function public.sync_farm_record(
  p_farm_id uuid,
  p_box_name text,
  p_record_id uuid,
  p_payload jsonb,
  p_updated_at timestamptz,
  p_deleted_at timestamptz
)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  insert into public.farm_sync_records (
    farm_id,
    box_name,
    record_id,
    payload,
    client_updated_at,
    updated_at,
    deleted_at,
    updated_by
  )
  values (
    p_farm_id,
    p_box_name,
    p_record_id,
    case when p_deleted_at is null then p_payload else null end,
    p_updated_at,
    now(),
    p_deleted_at,
    (select auth.uid())
  )
  on conflict (farm_id, box_name, record_id)
  do update set
    payload = excluded.payload,
    client_updated_at = excluded.client_updated_at,
    updated_at = now(),
    deleted_at = excluded.deleted_at,
    updated_by = excluded.updated_by
  where farm_sync_records.client_updated_at < excluded.client_updated_at
     or (
       farm_sync_records.client_updated_at = excluded.client_updated_at
       and farm_sync_records.updated_by::text < excluded.updated_by::text
     );
end;
$$;

revoke all on function public.sync_farm_record(
  uuid, text, uuid, jsonb, timestamptz, timestamptz
) from public, anon;
grant execute on function public.sync_farm_record(
  uuid, text, uuid, jsonb, timestamptz, timestamptz
) to authenticated;

insert into storage.buckets (id, name, public)
values ('farm-media', 'farm-media', false)
on conflict (id) do nothing;

create policy "Farm members can read farm media"
on storage.objects for select to authenticated
using (
  bucket_id = 'farm-media'
  and public.is_farm_member(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

create policy "Farm members can upload farm media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'farm-media'
  and public.is_farm_member(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

create policy "Farm members can update farm media"
on storage.objects for update to authenticated
using (
  bucket_id = 'farm-media'
  and public.is_farm_member(
    nullif((storage.foldername(name))[1], '')::uuid
  )
)
with check (
  bucket_id = 'farm-media'
  and public.is_farm_member(
    nullif((storage.foldername(name))[1], '')::uuid
  )
);

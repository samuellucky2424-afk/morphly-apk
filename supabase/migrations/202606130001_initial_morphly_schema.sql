create extension if not exists "pgcrypto";

create table if not exists public.profiles_r (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_settings_r (
  user_id uuid primary key references auth.users(id) on delete cascade,
  camera_quality text not null default 'high' check (camera_quality in ('low', 'medium', 'high')),
  dark_mode boolean not null default true,
  notifications_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.credit_packages_r (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  credits integer not null check (credits > 0),
  price_minor integer not null check (price_minor > 0),
  currency text not null default 'NGN',
  active boolean not null default true,
  is_popular boolean not null default false,
  sort_order integer not null default 0,
  apple_product_id text,
  google_product_id text,
  flutterwave_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.morph_sessions_r (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  reference_image_path text not null,
  model text,
  status text not null default 'reserved' check (status in ('reserved', 'live', 'completed', 'failed', 'refunded')),
  estimated_seconds integer not null default 30 check (estimated_seconds > 0),
  elapsed_seconds integer not null default 0 check (elapsed_seconds >= 0),
  reserved_credits integer not null default 0 check (reserved_credits >= 0),
  final_credits integer not null default 0 check (final_credits >= 0),
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_transactions_r (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  package_id uuid references public.credit_packages_r(id),
  provider text not null check (provider in ('apple', 'google', 'flutterwave')),
  provider_reference text not null,
  provider_transaction_id text,
  status text not null default 'pending' check (status in ('pending', 'succeeded', 'failed', 'cancelled')),
  amount_minor integer not null check (amount_minor > 0),
  currency text not null default 'NGN',
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, provider_reference)
);

create table if not exists public.credit_ledger_r (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null check (amount <> 0),
  reason text not null check (reason in ('purchase', 'morph_reserve', 'morph_finalize_refund', 'morph_failed_refund', 'admin_adjustment')),
  package_id uuid references public.credit_packages_r(id),
  payment_transaction_id uuid references public.payment_transactions_r(id),
  morph_session_id uuid references public.morph_sessions_r(id),
  idempotency_key text not null unique,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles_r;
create trigger profiles_set_updated_at
before update on public.profiles_r
for each row execute function public.set_updated_at();

drop trigger if exists user_settings_set_updated_at on public.user_settings_r;
create trigger user_settings_set_updated_at
before update on public.user_settings_r
for each row execute function public.set_updated_at();

drop trigger if exists credit_packages_set_updated_at on public.credit_packages_r;
create trigger credit_packages_set_updated_at
before update on public.credit_packages_r
for each row execute function public.set_updated_at();

drop trigger if exists morph_sessions_set_updated_at on public.morph_sessions_r;
create trigger morph_sessions_set_updated_at
before update on public.morph_sessions_r
for each row execute function public.set_updated_at();

drop trigger if exists payment_transactions_set_updated_at on public.payment_transactions_r;
create trigger payment_transactions_set_updated_at
before update on public.payment_transactions_r
for each row execute function public.set_updated_at();

create or replace function public.prevent_credit_ledger_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'credit_ledger_r is append-only';
end;
$$;

drop trigger if exists credit_ledger_prevent_update on public.credit_ledger_r;
create trigger credit_ledger_prevent_update
before update or delete on public.credit_ledger_r
for each row execute function public.prevent_credit_ledger_mutation();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles_r (user_id, email)
  values (new.id, new.email)
  on conflict (user_id) do update set email = excluded.email;

  insert into public.user_settings_r (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.get_credit_balance()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(amount), 0)::integer
  from public.credit_ledger_r
  where user_id = auth.uid();
$$;

create or replace function public.reserve_morph_session(
  p_reference_image_path text,
  p_estimated_seconds integer default 30,
  p_model text default null
)
returns table(session_id uuid, reserved_credits integer, balance integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_balance integer;
  v_reserved integer;
  v_session_id uuid;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  if p_reference_image_path is null or length(trim(p_reference_image_path)) = 0 then
    raise exception 'reference_image_path is required';
  end if;

  v_reserved := greatest(1, ceil(greatest(p_estimated_seconds, 1)::numeric / 10.0)::integer);

  select public.get_credit_balance() into v_balance;
  if v_balance < v_reserved then
    raise exception 'insufficient credits';
  end if;

  insert into public.morph_sessions_r (
    user_id,
    reference_image_path,
    model,
    estimated_seconds,
    reserved_credits,
    status,
    started_at
  )
  values (
    v_user_id,
    p_reference_image_path,
    p_model,
    greatest(p_estimated_seconds, 1),
    v_reserved,
    'reserved',
    now()
  )
  returning id into v_session_id;

  insert into public.credit_ledger_r (
    user_id,
    amount,
    reason,
    morph_session_id,
    idempotency_key,
    metadata
  )
  values (
    v_user_id,
    -v_reserved,
    'morph_reserve',
    v_session_id,
    'morph-reserve:' || v_session_id::text,
    jsonb_build_object('estimated_seconds', p_estimated_seconds)
  );

  return query
    select v_session_id, v_reserved, public.get_credit_balance();
end;
$$;

create or replace function public.finalize_morph_session(
  p_session_id uuid,
  p_elapsed_seconds integer
)
returns table(final_credits integer, refunded_credits integer, balance integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.morph_sessions_r%rowtype;
  v_final integer;
  v_refund integer;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select * into v_session
  from public.morph_sessions_r
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'morph session not found';
  end if;

  if v_session.status in ('completed', 'refunded') then
    return query
      select v_session.final_credits, 0, public.get_credit_balance();
    return;
  end if;

  v_final := least(
    v_session.reserved_credits,
    greatest(1, ceil(greatest(p_elapsed_seconds, 1)::numeric / 10.0)::integer)
  );
  v_refund := greatest(v_session.reserved_credits - v_final, 0);

  update public.morph_sessions_r
  set
    status = 'completed',
    elapsed_seconds = greatest(p_elapsed_seconds, 0),
    final_credits = v_final,
    completed_at = now()
  where id = p_session_id;

  if v_refund > 0 then
    insert into public.credit_ledger_r (
      user_id,
      amount,
      reason,
      morph_session_id,
      idempotency_key,
      metadata
    )
    values (
      v_user_id,
      v_refund,
      'morph_finalize_refund',
      p_session_id,
      'morph-finalize-refund:' || p_session_id::text,
      jsonb_build_object('elapsed_seconds', p_elapsed_seconds)
    )
    on conflict (idempotency_key) do nothing;
  end if;

  return query
    select v_final, v_refund, public.get_credit_balance();
end;
$$;

create or replace function public.refund_morph_session(p_session_id uuid)
returns table(refunded_credits integer, balance integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_session public.morph_sessions_r%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select * into v_session
  from public.morph_sessions_r
  where id = p_session_id and user_id = v_user_id
  for update;

  if not found then
    raise exception 'morph session not found';
  end if;

  if v_session.status in ('completed', 'refunded') then
    return query select 0, public.get_credit_balance();
    return;
  end if;

  update public.morph_sessions_r
  set status = 'refunded', completed_at = now()
  where id = p_session_id;

  insert into public.credit_ledger_r (
    user_id,
    amount,
    reason,
    morph_session_id,
    idempotency_key
  )
  values (
    v_user_id,
    v_session.reserved_credits,
    'morph_failed_refund',
    p_session_id,
    'morph-failed-refund:' || p_session_id::text
  )
  on conflict (idempotency_key) do nothing;

  return query select v_session.reserved_credits, public.get_credit_balance();
end;
$$;

create or replace function public.grant_purchase_credits(
  p_user_id uuid,
  p_package_code text,
  p_provider text,
  p_provider_reference text,
  p_provider_transaction_id text default null,
  p_raw_payload jsonb default '{}'::jsonb
)
returns table(granted_credits integer, balance integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_package public.credit_packages_r%rowtype;
  v_transaction_id uuid;
begin
  select * into v_package
  from public.credit_packages_r
  where code = p_package_code and active = true;

  if not found then
    raise exception 'credit package not found';
  end if;

  insert into public.payment_transactions_r (
    user_id,
    package_id,
    provider,
    provider_reference,
    provider_transaction_id,
    status,
    amount_minor,
    currency,
    raw_payload
  )
  values (
    p_user_id,
    v_package.id,
    p_provider,
    p_provider_reference,
    p_provider_transaction_id,
    'succeeded',
    v_package.price_minor,
    v_package.currency,
    p_raw_payload
  )
  on conflict (provider, provider_reference)
  do update set
    provider_transaction_id = coalesce(excluded.provider_transaction_id, public.payment_transactions_r.provider_transaction_id),
    status = 'succeeded',
    raw_payload = excluded.raw_payload
  returning id into v_transaction_id;

  insert into public.credit_ledger_r (
    user_id,
    amount,
    reason,
    package_id,
    payment_transaction_id,
    idempotency_key,
    metadata
  )
  values (
    p_user_id,
    v_package.credits,
    'purchase',
    v_package.id,
    v_transaction_id,
    'purchase:' || p_provider || ':' || p_provider_reference,
    jsonb_build_object('package_code', p_package_code)
  )
  on conflict (idempotency_key) do nothing;

  return query
    select v_package.credits, coalesce(sum(amount), 0)::integer
    from public.credit_ledger_r
    where user_id = p_user_id;
end;
$$;

revoke execute on function public.get_credit_balance() from public;
grant execute on function public.get_credit_balance() to authenticated;

revoke execute on function public.reserve_morph_session(text, integer, text) from public;
grant execute on function public.reserve_morph_session(text, integer, text) to authenticated;

revoke execute on function public.finalize_morph_session(uuid, integer) from public;
grant execute on function public.finalize_morph_session(uuid, integer) to authenticated;

revoke execute on function public.refund_morph_session(uuid) from public;
grant execute on function public.refund_morph_session(uuid) to authenticated;

revoke execute on function public.grant_purchase_credits(uuid, text, text, text, text, jsonb) from public;
grant execute on function public.grant_purchase_credits(uuid, text, text, text, text, jsonb) to service_role;

alter table public.profiles_r enable row level security;
alter table public.user_settings_r enable row level security;
alter table public.credit_packages_r enable row level security;
alter table public.morph_sessions_r enable row level security;
alter table public.payment_transactions_r enable row level security;
alter table public.credit_ledger_r enable row level security;

drop policy if exists "profiles_r are user readable" on public.profiles_r;
create policy "profiles_r are user readable"
on public.profiles_r for select
using (auth.uid() = user_id);

drop policy if exists "profiles_r are user updatable" on public.profiles_r;
create policy "profiles_r are user updatable"
on public.profiles_r for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "settings are user readable" on public.user_settings_r;
create policy "settings are user readable"
on public.user_settings_r for select
using (auth.uid() = user_id);

drop policy if exists "settings are user writable" on public.user_settings_r;
create policy "settings are user writable"
on public.user_settings_r for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "active packages are public readable" on public.credit_packages_r;
create policy "active packages are public readable"
on public.credit_packages_r for select
using (active = true);

drop policy if exists "sessions are user readable" on public.morph_sessions_r;
create policy "sessions are user readable"
on public.morph_sessions_r for select
using (auth.uid() = user_id);

drop policy if exists "transactions are user readable" on public.payment_transactions_r;
create policy "transactions are user readable"
on public.payment_transactions_r for select
using (auth.uid() = user_id);

drop policy if exists "ledger is user readable" on public.credit_ledger_r;
create policy "ledger is user readable"
on public.credit_ledger_r for select
using (auth.uid() = user_id);

insert into public.credit_packages_r (
  code,
  credits,
  price_minor,
  currency,
  is_popular,
  sort_order,
  apple_product_id,
  google_product_id,
  flutterwave_enabled
)
values
  ('credits_50', 50, 100000, 'NGN', false, 10, 'morphly.credits.50', 'morphly_credits_50', true),
  ('credits_120', 120, 200000, 'NGN', true, 20, 'morphly.credits.120', 'morphly_credits_120', true),
  ('credits_350', 350, 500000, 'NGN', false, 30, 'morphly.credits.350', 'morphly_credits_350', true),
  ('credits_800', 800, 1000000, 'NGN', false, 40, 'morphly.credits.800', 'morphly_credits_800', true)
on conflict (code) do update set
  credits = excluded.credits,
  price_minor = excluded.price_minor,
  currency = excluded.currency,
  is_popular = excluded.is_popular,
  sort_order = excluded.sort_order,
  apple_product_id = excluded.apple_product_id,
  google_product_id = excluded.google_product_id,
  flutterwave_enabled = excluded.flutterwave_enabled;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('reference-images', 'reference-images', false, 20971520, array['image/jpeg', 'image/png', 'image/webp']),
  ('morph-outputs', 'morph-outputs', false, 52428800, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "users can upload own reference images" on storage.objects;
create policy "users can upload own reference images"
on storage.objects for insert
with check (
  bucket_id = 'reference-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can read own reference images" on storage.objects;
create policy "users can read own reference images"
on storage.objects for select
using (
  bucket_id = 'reference-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "users can read own morph outputs" on storage.objects;
create policy "users can read own morph outputs"
on storage.objects for select
using (
  bucket_id = 'morph-outputs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

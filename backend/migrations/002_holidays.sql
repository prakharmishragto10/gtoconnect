-- Run once in the Supabase SQL editor. Adds company holidays, which the admin
-- marks per month and which salary and attendance treat as paid days off.

create table if not exists holidays (
  id         uuid primary key default gen_random_uuid(),
  date       date not null unique,
  name       text not null,
  created_by text,
  created_at timestamptz not null default now()
);

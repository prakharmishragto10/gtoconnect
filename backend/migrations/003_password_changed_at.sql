-- Run once in the Supabase SQL editor. Records when a password last changed,
-- so login tokens issued before a reset stop working.

alter table users add column if not exists password_changed_at timestamptz;

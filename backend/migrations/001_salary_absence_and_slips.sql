-- Run once in the Supabase SQL editor before deploying the backend that
-- calculates salary from absences and stores salary slips.

alter table salary_records
  add column if not exists working_days     integer,
  add column if not exists paid_days        integer,
  add column if not exists absent_days      integer,
  add column if not exists deduction        numeric not null default 0,
  add column if not exists slip_path        text,
  add column if not exists slip_uploaded_at timestamptz;

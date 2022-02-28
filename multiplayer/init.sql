create table if not exists "mp_latency" (
  id bigserial primary key,
  created_at timestamptz default now() NOT NULL
);
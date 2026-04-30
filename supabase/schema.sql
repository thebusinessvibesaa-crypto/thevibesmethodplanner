create extension if not exists "pgcrypto";

create table if not exists podcast_guests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text not null,
  phone text not null,
  country text not null,
  timezone text not null,
  instagram text not null,
  linkedin text,
  youtube text,
  tiktok text,
  website text,
  short_bio text not null,
  long_bio text,
  preferred_intro text not null,
  topic_proposal text not null,
  what_to_promote text not null,
  avoid_topics text,
  suggested_questions text,
  notes text,
  photo_url text,
  media_kit_url text,
  presentation_url text,
  consent_recording boolean not null,
  consent_content_reuse boolean not null,
  created_at timestamptz default now()
);

create table if not exists podcast_bookings (
  id uuid primary key default gen_random_uuid(),
  guest_id uuid references podcast_guests(id) on delete cascade,
  start_time timestamptz not null,
  end_time timestamptz not null,
  timezone text not null,
  google_calendar_event_id text,
  google_calendar_event_link text,
  status text not null default 'Nuevo',
  internal_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

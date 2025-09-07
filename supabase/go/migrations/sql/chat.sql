-- Chat schema for GoDarna
-- Requires pgcrypto or equivalent for gen_random_uuid(); ensure enabled in your extensions migration.
-- If not available, replace gen_random_uuid() with uuid_generate_v4() and enable uuid-ossp.

begin;

-- =====================
-- Tables
-- =====================
create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  title text,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_participants (
  chat_id uuid not null references public.chats(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (chat_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  type text not null default 'text', -- text | image | system ...
  created_at timestamptz not null default now(),
  seen_at timestamptz
);

-- =====================
-- Indexes
-- =====================
create index if not exists idx_messages_chat_created on public.messages(chat_id, created_at);
create index if not exists idx_messages_sender on public.messages(sender_id);
create index if not exists idx_participants_user on public.chat_participants(user_id);

-- =====================
-- RLS Policies
-- =====================
alter table public.chats enable row level security;
alter table public.chat_participants enable row level security;
alter table public.messages enable row level security;

-- chats: participants can select
create policy if not exists chats_select_participants on public.chats
for select
using (
  exists (
    select 1 from public.chat_participants cp
    where cp.chat_id = chats.id and cp.user_id = auth.uid()
  )
);

-- chats: creator can insert
create policy if not exists chats_insert_creator on public.chats
for insert
with check (created_by = auth.uid());

-- chat_participants: user can view own membership and memberships of chats they are part of
create policy if not exists chat_participants_select on public.chat_participants
for select
using (
  user_id = auth.uid() or exists (
    select 1 from public.chat_participants cp2
    where cp2.chat_id = chat_participants.chat_id and cp2.user_id = auth.uid()
  )
);

-- chat_participants: allow creator of chat to add participants (including themselves)
create policy if not exists chat_participants_insert_by_creator on public.chat_participants
for insert
with check (
  exists (
    select 1 from public.chats c
    where c.id = chat_participants.chat_id and c.created_by = auth.uid()
  )
);

-- messages: participants can select
create policy if not exists messages_select_participants on public.messages
for select
using (
  exists (
    select 1 from public.chat_participants cp
    where cp.chat_id = messages.chat_id and cp.user_id = auth.uid()
  )
);

-- messages: only participants can insert, and sender must be self
create policy if not exists messages_insert_sender_participant on public.messages
for insert
with check (
  sender_id = auth.uid() and exists (
    select 1 from public.chat_participants cp
    where cp.chat_id = messages.chat_id and cp.user_id = auth.uid()
  )
);

-- messages: only sender can update their message (e.g., to set seen or edits) and must belong to chat
create policy if not exists messages_update_sender on public.messages
for update
using (
  sender_id = auth.uid() and exists (
    select 1 from public.chat_participants cp
    where cp.chat_id = messages.chat_id and cp.user_id = auth.uid()
  )
)
with check (
  sender_id = auth.uid()
);

-- =====================
-- Triggers / helper functions
-- =====================
-- When creating a chat, auto-add creator as participant
create or replace function public.fn_add_creator_as_participant()
returns trigger as $$
begin
  insert into public.chat_participants(chat_id, user_id, role)
  values (new.id, new.created_by, 'owner')
  on conflict do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_chats_add_creator on public.chats;
create trigger trg_chats_add_creator
after insert on public.chats
for each row execute procedure public.fn_add_creator_as_participant();

-- Optional: helper to mark messages as seen for current user in a chat
create or replace function public.fn_mark_chat_seen(p_chat_id uuid)
returns void as $$
begin
  update public.messages m
  set seen_at = now()
  where m.chat_id = p_chat_id
    and m.sender_id <> auth.uid()
    and m.seen_at is null
    and exists (
      select 1 from public.chat_participants cp
      where cp.chat_id = m.chat_id and cp.user_id = auth.uid()
    );
end;
$$ language plpgsql security definer;

commit;

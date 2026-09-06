-- Bazarek buyer/seller chat and listing contact preferences
alter table public.products
  add column if not exists allow_chat boolean not null default true,
  add column if not exists show_phone boolean not null default false;

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.products(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references auth.users(id) on delete cascade,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  unique(listing_id, buyer_id, seller_id),
  check (buyer_id <> seller_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 2000),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists conversations_buyer_idx on public.conversations(buyer_id, last_message_at desc);
create index if not exists conversations_seller_idx on public.conversations(seller_id, last_message_at desc);
create index if not exists messages_conversation_idx on public.messages(conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.messages enable row level security;

drop policy if exists conversations_participants on public.conversations;
create policy conversations_participants on public.conversations
  for all using (auth.uid() = buyer_id or auth.uid() = seller_id)
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists messages_participants on public.messages;
create policy messages_participants on public.messages
  for all using (exists (select 1 from public.conversations c where c.id = conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())))
  with check (exists (select 1 from public.conversations c where c.id = conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())) and sender_id = auth.uid());

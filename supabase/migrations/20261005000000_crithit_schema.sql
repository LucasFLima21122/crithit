-- CritHit — schema do banco (Checkpoint 5)
--
-- Tabelas:
--   profiles  → dados públicos de cada usuário (nome de exibição, conta Steam)
--   reviews   → nota (1 a 5 estrelas) + crítica de um usuário sobre um jogo
--
-- Segurança: Row Level Security ligado em tudo. Qualquer pessoa pode LER
-- perfis e reviews (é uma rede social de críticas), mas cada usuário só
-- cria, edita e apaga o que é dele.

-- ---------------------------------------------------------------- profiles

create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Jogador'
                 check (char_length(display_name) between 1 and 40),
  steam_id     text check (steam_id ~ '^7656119[0-9]{10}$'),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Perfis são públicos" on public.profiles;
create policy "Perfis são públicos"
  on public.profiles for select
  using (true);

drop policy if exists "Usuário cria o próprio perfil" on public.profiles;
create policy "Usuário cria o próprio perfil"
  on public.profiles for insert
  with check ((select auth.uid()) = id);

drop policy if exists "Usuário edita o próprio perfil" on public.profiles;
create policy "Usuário edita o próprio perfil"
  on public.profiles for update
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Cria o perfil automaticamente quando alguém se cadastra (inclusive
-- convidados/anônimos, que não têm e-mail).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Jogador'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mantém updated_at em dia.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------- reviews

create table if not exists public.reviews (
  id          uuid primary key default gen_random_uuid(),
  -- Id do jogo no app: slug do catálogo ("hades") ou "steam-<appid>".
  game_id     text not null check (char_length(game_id) between 1 and 100),
  -- Guardado junto para o histórico do perfil não depender do catálogo.
  game_title  text not null check (char_length(game_title) between 1 and 200),
  -- null nas reviews de exemplo (seed) da comunidade.
  user_id     uuid references auth.users (id) on delete cascade,
  author_name text not null check (char_length(author_name) between 1 and 40),
  rating      smallint not null check (rating between 1 and 5),
  comment     text not null default '' check (char_length(comment) <= 500),
  created_at  timestamptz not null default now(),
  -- Uma review por usuário por jogo: salvar de novo atualiza (upsert).
  -- Como NULLs são distintos no Postgres, as reviews de seed não conflitam.
  constraint reviews_one_per_user_per_game unique (user_id, game_id)
);

create index if not exists reviews_game_id_idx on public.reviews (game_id);
create index if not exists reviews_created_at_idx on public.reviews (created_at desc);

alter table public.reviews enable row level security;

drop policy if exists "Reviews são públicas" on public.reviews;
create policy "Reviews são públicas"
  on public.reviews for select
  using (true);

drop policy if exists "Usuário cria as próprias reviews" on public.reviews;
create policy "Usuário cria as próprias reviews"
  on public.reviews for insert
  with check ((select auth.uid()) = user_id);

drop policy if exists "Usuário edita as próprias reviews" on public.reviews;
create policy "Usuário edita as próprias reviews"
  on public.reviews for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Usuário apaga as próprias reviews" on public.reviews;
create policy "Usuário apaga as próprias reviews"
  on public.reviews for delete
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------- acesso

-- Permissões explícitas da Data API (não dependemos do "expose new tables"
-- automático do Supabase). O GRANT libera a operação; quem decide QUAIS
-- linhas cada um vê ou altera continuam sendo as policies de RLS acima.
-- Convidados (login anônimo) também usam o papel "authenticated".
grant usage on schema public to anon, authenticated;

grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;

grant select on public.reviews to anon, authenticated;
grant insert, update, delete on public.reviews to authenticated;

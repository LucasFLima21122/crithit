-- CritHit — conta PlayStation no perfil (Checkpoint 6)
--
-- Guarda o ID online da PSN conectada, para a biblioteca ser recarregada
-- sozinha no próximo login (mesmo papel da coluna steam_id). As policies de
-- RLS de profiles já cobrem a coluna nova: todo mundo lê, só o dono edita.

alter table public.profiles
  add column if not exists psn_online_id text
    check (psn_online_id ~ '^[A-Za-z][A-Za-z0-9_-]{2,15}$');

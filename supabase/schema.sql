-- İTÜpoly — Online çok oyunculu şema (Faz 5)
-- Model: deterministik lockstep. Ağa yalnızca AKSİYON gider; her istemci aynı
-- motoru (GameEngine.submit) çalıştırır. seq senkronun bel kemiğidir.

create table if not exists rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,                 -- 6 haneli oda kodu (/oda/KOD)
  host_id uuid not null,
  seed bigint not null,                      -- deste karıştırma + zar determinizmi
  status text not null default 'lobby',      -- lobby | playing | ended
  created_at timestamptz default now()
);

create table if not exists room_players (
  room_id uuid references rooms(id) on delete cascade,
  user_id uuid not null,
  seat int not null,                         -- oturma sırası = motor oyuncu id'si
  name text not null,
  pawn text not null,                        -- PawnType.name
  is_bot boolean not null default false,
  primary key (room_id, seat)
);

create table if not exists game_events (
  id bigserial primary key,
  room_id uuid references rooms(id) on delete cascade,
  seq int not null,                          -- 0'dan artan sıra numarası
  payload jsonb not null,                    -- PlayerAction.toJson()
  sender_id uuid not null,
  created_at timestamptz default now(),
  unique (room_id, seq)                      -- çakışan hamleyi DB reddeder
);

-- Reconnect = eksik seq'leri çekip submit ile replay.
create index if not exists game_events_room_seq on game_events (room_id, seq);

-- NOT (ilk sürüm): host doğrulayıcıdır (referee). İleride RLS + edge function
-- ile sunucu taraflı kural doğrulaması eklenir. Debug için periyodik
-- state-hash karşılaştırması (GameState.toJson tabanlı) kullanılır.

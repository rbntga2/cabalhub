-- ══════════════════════════════════════════════
-- CabalHub.online — Setup SQL Completo
-- Rodar no Supabase: SQL Editor → New Query → Cole tudo → Run
-- ══════════════════════════════════════════════

-- ══════ EXTENSÕES ══════
create extension if not exists "uuid-ossp";

-- ══════ TABELAS GLOBAIS ══════

create table public.users_global (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  creditos_globais int default 0,
  is_super_admin boolean default false,
  created_at timestamptz default now()
);

create table public.servidores (
  id uuid primary key default uuid_generate_v4(),
  nome text unique not null,
  regiao text default 'Brasil',
  idioma text default 'pt-BR',
  craft_ativo boolean default false,
  ativo boolean default true,
  created_at timestamptz default now()
);

create table public.features_config (
  id uuid primary key default uuid_generate_v4(),
  servidor_id uuid references public.servidores(id) on delete cascade,
  nome text not null,
  ativo boolean default false,
  created_at timestamptz default now()
);

create table public.server_requests (
  id uuid primary key default uuid_generate_v4(),
  nome_servidor text not null,
  regiao text,
  link text,
  nick_solicitante text,
  email_solicitante text,
  created_at timestamptz default now()
);

-- ══════ TABELAS POR SERVIDOR ══════

create table public.server_profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users_global(id) on delete cascade,
  servidor_id uuid not null references public.servidores(id) on delete cascade,
  nick text not null,
  avatar_url text,
  banner_url text,
  bio text,
  cargo text default 'membro' check (cargo in ('membro','streamer','moderador','admin_servidor','super_admin')),
  creditos int default 0,
  nick_alterado_em timestamptz,
  created_at timestamptz default now(),
  unique(user_id, servidor_id),
  unique(nick, servidor_id)
);

create table public.posts (
  id uuid primary key default uuid_generate_v4(),
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  servidor_id uuid not null references public.servidores(id) on delete cascade,
  tipo text not null check (tipo in ('feed','media','video','enquete','anuncio','mural')),
  mural_categoria text check (mural_categoria in ('atualizacoes','eventos','codigos','campanhas','fixados')),
  conteudo text,
  spoiler_conteudo text,
  imagem_url text,
  video_url text,
  video_plataforma text check (video_plataforma in ('youtube','twitch')),
  enquete_opcoes jsonb,
  anuncio_preco bigint,
  anuncio_preco_spoiler boolean default false,
  anuncio_status text default 'a_venda' check (anuncio_status in ('a_venda','vendido','comprado','cancelado')),
  likes_count int default 0,
  comments_count int default 0,
  views_count int default 0,
  shares_count int default 0,
  alcance_atual int default 0,
  last_liked_at timestamptz,
  status text default 'ativo' check (status in ('ativo','oculto','deletado','congelado')),
  created_at timestamptz default now()
);

create table public.comments (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  parent_id uuid references public.comments(id) on delete cascade,
  conteudo text not null,
  spoiler_conteudo text,
  is_spoiler boolean default false,
  likes_count int default 0,
  created_at timestamptz default now()
);

create table public.likes (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique(post_id, server_profile_id)
);

create table public.views (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique(post_id, server_profile_id)
);

create table public.notifications (
  id uuid primary key default uuid_generate_v4(),
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  tipo text not null check (tipo in ('like','comment','spoiler','invite','mission','system','mural')),
  post_id uuid references public.posts(id) on delete cascade,
  actor_profile_id uuid references public.server_profiles(id) on delete set null,
  conteudo text,
  lido boolean default false,
  created_at timestamptz default now()
);

create table public.referrals (
  id uuid primary key default uuid_generate_v4(),
  referrer_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  referred_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  creditos_dados int default 50,
  created_at timestamptz default now()
);

create table public.missoes (
  id uuid primary key default uuid_generate_v4(),
  servidor_id uuid references public.servidores(id) on delete cascade,
  titulo text not null,
  descricao text,
  tipo text,
  meta int not null,
  recompensa_creditos int not null,
  ativo boolean default true,
  created_at timestamptz default now()
);

create table public.missoes_progresso (
  id uuid primary key default uuid_generate_v4(),
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  missao_id uuid not null references public.missoes(id) on delete cascade,
  progresso int default 0,
  completa boolean default false,
  completed_at timestamptz,
  unique(server_profile_id, missao_id)
);

create table public.anuncios_rapidos (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  custo int default 200,
  expira_em timestamptz not null,
  ativo boolean default true,
  created_at timestamptz default now()
);

create table public.cargo_requests (
  id uuid primary key default uuid_generate_v4(),
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  cargo_solicitado text not null,
  link_live text,
  frequencia text,
  observacoes text,
  status text default 'pendente' check (status in ('pendente','aprovado','rejeitado')),
  created_at timestamptz default now()
);

create table public.enquete_votos (
  id uuid primary key default uuid_generate_v4(),
  post_id uuid not null references public.posts(id) on delete cascade,
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  opcao_idx int not null,
  unique(post_id, server_profile_id)
);

create table public.craft_config (
  id uuid primary key default uuid_generate_v4(),
  servidor_id uuid unique not null references public.servidores(id) on delete cascade,
  preco_peca bigint default 1500000,
  min_pecas int default 35,
  taxa_pontos_creditos int default 10,
  promo_taxa int,
  promo_expira timestamptz,
  grades_ativas jsonb default '["SigMetal"]'::jsonb
);

create table public.craft_pontos (
  id uuid primary key default uuid_generate_v4(),
  server_profile_id uuid not null references public.server_profiles(id) on delete cascade,
  pontos_acumulados int default 0,
  pontos_gastos int default 0,
  unique(server_profile_id)
);

create table public.server_migrations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users_global(id) on delete cascade,
  from_servidor_id uuid references public.servidores(id),
  to_servidor_id uuid not null references public.servidores(id),
  is_new_account boolean default false,
  created_at timestamptz default now()
);

-- ══════ ÍNDICES ══════

create index idx_posts_servidor on public.posts(servidor_id, created_at desc);
create index idx_posts_tipo on public.posts(servidor_id, tipo);
create index idx_posts_status on public.posts(status);
create index idx_posts_likes on public.posts(servidor_id, last_liked_at desc nulls last);
create index idx_comments_post on public.comments(post_id, created_at);
create index idx_likes_post on public.likes(post_id);
create index idx_notifications_profile on public.notifications(server_profile_id, lido, created_at desc);
create index idx_server_profiles_user on public.server_profiles(user_id);
create index idx_server_profiles_servidor on public.server_profiles(servidor_id);
create index idx_anuncios_rapidos_ativo on public.anuncios_rapidos(ativo, expira_em);
create index idx_server_migrations_user on public.server_migrations(user_id, created_at desc);
create index idx_server_migrations_to on public.server_migrations(to_servidor_id, created_at desc);

-- ══════ ROW LEVEL SECURITY ══════

alter table public.users_global enable row level security;
alter table public.servidores enable row level security;
alter table public.server_profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.likes enable row level security;
alter table public.views enable row level security;
alter table public.notifications enable row level security;
alter table public.referrals enable row level security;
alter table public.missoes enable row level security;
alter table public.missoes_progresso enable row level security;
alter table public.anuncios_rapidos enable row level security;
alter table public.cargo_requests enable row level security;
alter table public.enquete_votos enable row level security;
alter table public.craft_config enable row level security;
alter table public.craft_pontos enable row level security;
alter table public.features_config enable row level security;
alter table public.server_requests enable row level security;
alter table public.server_migrations enable row level security;

-- Servidores: todos leem, super admin edita
create policy "servidores_select" on public.servidores for select using (true);
create policy "servidores_admin" on public.servidores for all using (
  exists(select 1 from public.users_global where id = auth.uid() and is_super_admin = true)
);

-- Users global: próprio user lê/edita
create policy "users_select_own" on public.users_global for select using (id = auth.uid());
create policy "users_update_own" on public.users_global for update using (id = auth.uid());

-- Server profiles: todos leem (público), dono edita
create policy "profiles_select" on public.server_profiles for select using (true);
create policy "profiles_insert" on public.server_profiles for insert with check (user_id = auth.uid());
create policy "profiles_update_own" on public.server_profiles for update using (user_id = auth.uid());

-- Posts: leitura pública (exceto ocultos/deletados), dono edita
create policy "posts_select" on public.posts for select using (status in ('ativo','congelado'));
create policy "posts_insert" on public.posts for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);
create policy "posts_update_own" on public.posts for update using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);
-- Admin vê tudo (incluindo ocultos)
create policy "posts_admin_select" on public.posts for select using (
  exists(select 1 from public.users_global where id = auth.uid() and is_super_admin = true)
);

-- Comments: leitura pública, inserção autenticada (exceto posts congelados)
create policy "comments_select" on public.comments for select using (true);
create policy "comments_insert" on public.comments for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
  and not exists(select 1 from public.posts where id = post_id and status = 'congelado')
);

-- $spoiler em comentários de anúncio: só dono do post vê spoiler_conteudo
-- Nota: isso é tratado no frontend com uma view ou function, não via RLS direto
-- porque RLS não pode filtrar colunas, só linhas. A query filtra:
--   SELECT ..., CASE WHEN (post.server_profile_id = meu_profile_id) THEN spoiler_conteudo ELSE NULL END

-- Likes: autenticado insere, público lê
create policy "likes_select" on public.likes for select using (true);
create policy "likes_insert" on public.likes for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);
create policy "likes_delete" on public.likes for delete using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

-- Views: autenticado insere, público lê contagem via posts.views_count
create policy "views_insert" on public.views for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

-- Notifications: só próprio user
create policy "notif_select" on public.notifications for select using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);
create policy "notif_update" on public.notifications for update using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

-- Referrals, missoes_progresso, craft_pontos, enquete_votos: próprio user
create policy "referrals_select" on public.referrals for select using (
  referrer_profile_id in (select id from public.server_profiles where user_id = auth.uid())
  or referred_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

create policy "missoes_select" on public.missoes for select using (true);
create policy "missoes_prog_select" on public.missoes_progresso for select using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);
create policy "missoes_prog_upsert" on public.missoes_progresso for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

create policy "craft_config_select" on public.craft_config for select using (true);
create policy "craft_pontos_select" on public.craft_pontos for select using (true);
create policy "craft_pontos_own" on public.craft_pontos for update using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

create policy "anuncios_rapidos_select" on public.anuncios_rapidos for select using (true);
create policy "cargo_requests_insert" on public.cargo_requests for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);
create policy "cargo_requests_own" on public.cargo_requests for select using (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

create policy "enquete_votos_select" on public.enquete_votos for select using (true);
create policy "enquete_votos_insert" on public.enquete_votos for insert with check (
  server_profile_id in (select id from public.server_profiles where user_id = auth.uid())
);

create policy "features_select" on public.features_config for select using (true);
create policy "server_requests_insert" on public.server_requests for insert with check (true);
create policy "server_migrations_select" on public.server_migrations for select using (
  user_id = auth.uid()
  or exists(select 1 from public.users_global where id = auth.uid() and is_super_admin = true)
);

-- ══════ FUNCTIONS ══════

-- Auto-criar users_global ao registrar
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users_global (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Incrementar likes_count e atualizar last_liked_at
create or replace function public.handle_new_like()
returns trigger as $$
begin
  update public.posts
  set likes_count = likes_count + 1, last_liked_at = now()
  where id = new.post_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_like_created
  after insert on public.likes
  for each row execute function public.handle_new_like();

-- Decrementar likes_count ao remover like
create or replace function public.handle_remove_like()
returns trigger as $$
begin
  update public.posts
  set likes_count = greatest(likes_count - 1, 0)
  where id = old.post_id;
  return old;
end;
$$ language plpgsql security definer;

create trigger on_like_removed
  after delete on public.likes
  for each row execute function public.handle_remove_like();

-- Incrementar comments_count
create or replace function public.handle_new_comment()
returns trigger as $$
begin
  update public.posts
  set comments_count = comments_count + 1
  where id = new.post_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_comment_created
  after insert on public.comments
  for each row execute function public.handle_new_comment();

-- Incrementar views_count
create or replace function public.handle_new_view()
returns trigger as $$
begin
  update public.posts
  set views_count = views_count + 1
  where id = new.post_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_view_created
  after insert on public.views
  for each row execute function public.handle_new_view();

-- Incrementar shares_count (chamado via RPC)
create or replace function public.increment_shares(post_uuid uuid)
returns void as $$
begin
  update public.posts set shares_count = shares_count + 1 where id = post_uuid;
end;
$$ language plpgsql security definer;

-- ══════ SEED DATA ══════

-- Servidor inicial
insert into public.servidores (nome, regiao, craft_ativo) values
  ('Infinity', 'Brasil', true);

-- Missões iniciais (vinculadas ao servidor Infinity ou globais)
insert into public.missoes (titulo, descricao, tipo, meta, recompensa_creditos) values
  ('Poste 5 anúncios', 'Registre 5 itens à venda na loja', 'anuncios', 5, 100),
  ('Convide 10 amigos', 'Envie seu link de convite', 'convites', 10, 200),
  ('Receba 100 corações', 'Acumule 100 curtidas únicas', 'likes', 100, 150),
  ('Faça 3 ofertas com $spoiler', 'Use $spoiler em comentários', 'spoilers', 3, 75),
  ('Crie 3 enquetes', 'Engaje a comunidade', 'enquetes', 3, 75);

-- Craft config para Infinity
insert into public.craft_config (servidor_id, preco_peca, min_pecas, taxa_pontos_creditos, grades_ativas)
select id, 1500000, 35, 10, '["SigMetal"]'::jsonb
from public.servidores where nome = 'Infinity';

-- Features iniciais
insert into public.features_config (nome, ativo) values
  ('compra_creditos', false),
  ('idioma_regional', false),
  ('cronometro_post', false),
  ('pagamento_real', false);

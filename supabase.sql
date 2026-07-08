-- Schema + RPC para o fluxo /aplicar/ da mentoria-1a1-lp.
-- Rode no SQL Editor do seu projeto Supabase.
--
-- Modelo de segurança: a landing usa a anon/publishable key só para chamar a
-- RPC `mentoria_upsert` (security definer). NÃO há policy de SELECT/UPDATE para
-- `anon`, então ninguém consegue ler os leads pela chave pública.

create extension if not exists "pgcrypto";

create table if not exists public.mentoria_aplicacoes (
  id            uuid primary key default gen_random_uuid(),
  -- dados do lead
  name          text,
  email         text,
  whatsapp      text,
  instagram     text,
  momento       text,
  faturamento   text,
  experiencia_ia text,
  motivo        text,
  investimento  text,
  urgencia      text,
  -- scoring
  score         int,
  temperatura   text,           -- quente | morno | frio | descartado
  -- tracking
  utm_source    text,
  utm_medium    text,
  utm_campaign  text,
  utm_content   text,
  utm_term      text,
  user_agent    text,
  referrer      text,
  -- progresso
  last_step     int,
  completed     boolean default false,
  completed_at  timestamptz,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

alter table public.mentoria_aplicacoes enable row level security;
-- sem policies para anon: acesso apenas via RPC abaixo.

-- UPSERT idempotente por id (progressive save). Recebe um jsonb `p` com um
-- subconjunto das colunas e faz insert-or-update.
create or replace function public.mentoria_upsert(p jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.mentoria_aplicacoes as m (
    id, name, email, whatsapp, instagram, momento, faturamento,
    experiencia_ia, motivo, investimento, urgencia, score, temperatura,
    utm_source, utm_medium, utm_campaign, utm_content, utm_term,
    user_agent, referrer, last_step, completed, completed_at, updated_at
  )
  values (
    coalesce((p->>'id')::uuid, gen_random_uuid()),
    p->>'name', p->>'email', p->>'whatsapp', p->>'instagram', p->>'momento',
    p->>'faturamento', p->>'experiencia_ia', p->>'motivo', p->>'investimento',
    p->>'urgencia', (p->>'score')::int, p->>'temperatura',
    p->>'utm_source', p->>'utm_medium', p->>'utm_campaign', p->>'utm_content',
    p->>'utm_term', p->>'user_agent', p->>'referrer', (p->>'last_step')::int,
    coalesce((p->>'completed')::boolean, false),
    (p->>'completed_at')::timestamptz,
    coalesce((p->>'updated_at')::timestamptz, now())
  )
  on conflict (id) do update set
    name           = coalesce(excluded.name, m.name),
    email          = coalesce(excluded.email, m.email),
    whatsapp       = coalesce(excluded.whatsapp, m.whatsapp),
    instagram      = coalesce(excluded.instagram, m.instagram),
    momento        = coalesce(excluded.momento, m.momento),
    faturamento    = coalesce(excluded.faturamento, m.faturamento),
    experiencia_ia = coalesce(excluded.experiencia_ia, m.experiencia_ia),
    motivo         = coalesce(excluded.motivo, m.motivo),
    investimento   = coalesce(excluded.investimento, m.investimento),
    urgencia       = coalesce(excluded.urgencia, m.urgencia),
    score          = coalesce(excluded.score, m.score),
    temperatura    = coalesce(excluded.temperatura, m.temperatura),
    utm_source     = coalesce(excluded.utm_source, m.utm_source),
    utm_medium     = coalesce(excluded.utm_medium, m.utm_medium),
    utm_campaign   = coalesce(excluded.utm_campaign, m.utm_campaign),
    utm_content    = coalesce(excluded.utm_content, m.utm_content),
    utm_term       = coalesce(excluded.utm_term, m.utm_term),
    user_agent     = coalesce(excluded.user_agent, m.user_agent),
    referrer       = coalesce(excluded.referrer, m.referrer),
    last_step      = coalesce(excluded.last_step, m.last_step),
    completed      = excluded.completed or m.completed,
    completed_at   = coalesce(excluded.completed_at, m.completed_at),
    updated_at     = now();
end;
$$;

-- Permite que a anon key chame a RPC (e só ela).
grant execute on function public.mentoria_upsert(jsonb) to anon;

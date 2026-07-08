# mentoria-1a1-lp

Landing page + fluxo de aplicação (quiz multi-step) da **Mentoria 1-a-1**.

Site estático, zero build: HTML + CSS inline + fontes. Deploy direto na Vercel/Netlify/GitHub Pages.

## Estrutura

```
index.html          landing principal
aplicar/index.html  quiz de aplicação (10 perguntas → Supabase → WhatsApp)
img/                fotos (hero, work, perfil) + logo 99labdev
supabase.sql        schema + RPC de upsert dos leads
```

## Identidade visual (MIV 99LabDev)

- **Cores:** Cinza `#292A25` · Roxo `#B078FF` (principais) · Verde `#3CD3A4` · Amarelo `#D9D353` (secundárias)
- **Tipografia:** Raleway (títulos 800 + corpo) · IBM Plex Mono (kickers/tech)
- **Logo:** `img/logo-99labdev.png` (assinatura prioritária, funde no fundo charcoal)

## Fluxo do /aplicar/

Quiz de 10 passos que coleta: nome, instagram, whatsapp, email, momento,
faturamento, experiência com IA, motivo, investimento e urgência.

1. **Progressive save** — a partir do momento que o WhatsApp é preenchido,
   cada passo faz `UPSERT` via RPC `mentoria_upsert` (não grava lead fantasma).
2. **Scoring** — calcula um score 0–100 e classifica o lead em
   `quente` / `morno` / `frio` / `descartado` (regras em `submit()`).
3. **Redirect** — tela final abre o WhatsApp com mensagem pré-preenchida.

## Setup (antes de publicar)

Abra `aplicar/index.html` e preencha o bloco de config no topo do `<script>`:

```js
const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_KEY = 'SUA_PUBLISHABLE_KEY_AQUI';   // anon/publishable key
const WPP_NUM      = 'SEU_NUMERO_WHATSAPP';         // E.164 sem +, ex 5511999999999
```

Rode `supabase.sql` no SQL Editor do seu projeto Supabase pra criar a tabela
`mentoria_aplicacoes` e a RPC `mentoria_upsert`.

> A publishable/anon key fica exposta no client (normal). A segurança vem da
> RPC `security definer` sem policies de SELECT/UPDATE pra `anon` — ninguém lê
> os leads pela anon key.

## Rodar local

```bash
python3 -m http.server 8000
# http://localhost:8000
```

---
Clone de referência montado para a 99lab. Design e copy originais adaptados;
backend (Supabase + WhatsApp) reconfigurado para credenciais próprias.

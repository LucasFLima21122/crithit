# Guia: Supabase + Steam

Passo a passo para ligar o **modo online** do CritHit: banco de dados e login no Supabase, mais a importação da biblioteca Steam. Sem nada disso o app continua funcionando no modo offline (dados mockados).

## Visão geral

```
App Flutter ──► Supabase Auth          (login: e-mail/senha ou convidado)
            ──► Supabase Postgres      (tabelas profiles e reviews, com RLS)
            ──► Edge Function "steam"  ──► api.steampowered.com
                 (guarda a STEAM_API_KEY e libera CORS para o navegador)
```

## 1. Criar o projeto no Supabase

1. Entre em [supabase.com](https://supabase.com) → **New project** (o plano gratuito basta).
2. Em **Project Settings → API**, copie:
   - **Project URL** (`https://xxxx.supabase.co`)
   - **Publishable key** (`sb_publishable_...`) ou a antiga **anon key**. Essa chave é pública e pode ficar no app.

## 2. Criar as tabelas

No painel: **SQL Editor → New query**, cole e rode, nesta ordem:

1. `supabase/migrations/20261005000000_crithit_schema.sql` (tabelas, RLS e triggers)
2. `supabase/seed.sql` (as 43 reviews de exemplo da comunidade)

Ou pelo terminal, com o [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
npx supabase login
npx supabase link --project-ref <ref-do-projeto>
npx supabase db push            # aplica as migrations
```

> O seed é gerado a partir de `lib/data/mock_reviews.dart`. Se mudar as reviews mockadas, rode `dart run tool/generate_seed.dart > supabase/seed.sql`.

## 3. Configurar o login

Em **Authentication → Sign In / Providers**:

- **Email**: deixe ligado. Para a apresentação, desligue **"Confirm email"**; assim o cadastro já entra direto, sem precisar abrir o e-mail.
- **Allow anonymous sign-ins**: ligue, para o botão **"Explorar como convidado"** funcionar no modo online.

## 4. Chave da Steam Web API

1. Entre em [steamcommunity.com/dev/apikey](https://steamcommunity.com/dev/apikey) com sua conta Steam (a conta precisa ter pelo menos uma compra; contas "limitadas" não geram chave).
2. Em *Domain Name* pode colocar `crithit.app` (é só um rótulo).
3. Copie a chave (32 caracteres). **Ela é secreta: não coloque no código nem no `env.json`.**

## 5. Publicar a Edge Function `steam`

```bash
npx supabase login
npx supabase secrets set STEAM_API_KEY=<sua-chave> --project-ref <ref-do-projeto>
npx supabase functions deploy steam --project-ref <ref-do-projeto> --use-api
```

A função fica em `supabase/functions/steam/index.ts`. Ela só aceita 4 métodos da Steam (lista fechada) e exige o header de autenticação do Supabase, que o app já manda sozinho.

## 6. Apontar o app para o Supabase

```bash
cp config/env.example.json config/env.json   # no Windows: copy config\env.example.json config\env.json
```

Preencha `config/env.json` (esse arquivo está no `.gitignore`):

```json
{
  "SUPABASE_URL": "https://xxxx.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

E rode:

```bash
flutter run -d chrome --dart-define-from-file=config/env.json
```

Na tela de boas-vindas deve aparecer **"Online · dados salvos no Supabase"**.

## 7. Deixar o perfil da Steam visível

Na Steam: clique no seu nome → **Perfil → Editar perfil → Privacidade**:

- **Meu perfil**: Público
- **Detalhes de jogos**: Público
- Desmarque **"Sempre manter meu tempo de jogo privado"**

Sem isso a Steam não devolve a lista de jogos, e o app mostra a mensagem explicando o que ajustar.

## Modo direto (opcional, sem Supabase)

Para testar a Steam real **fora do navegador** (Windows desktop ou Android) sem Supabase, dá para passar a chave direto:

```bash
flutter run -d windows --dart-define=STEAM_API_KEY=<sua-chave>
```

Use só para teste local: nesse modo a chave vai junto do executável. No navegador isso não funciona, porque a Steam bloqueia CORS; por isso existe a Edge Function.

## Problemas comuns

| Sintoma | Causa provável |
|---|---|
| "Modo offline" mesmo com `env.json` | Faltou `--dart-define-from-file=config/env.json` no comando |
| "Confirme seu e-mail antes de entrar" | "Confirm email" ainda ligado no Supabase (passo 3) |
| "O modo convidado está desligado no servidor" | Anonymous sign-ins desligado (passo 3) |
| "A chave da Steam não está configurada no servidor" | Faltou o `secrets set` (passo 5) |
| "Esse perfil da Steam é privado" / "Não consegui ver seus jogos" | Privacidade da Steam (passo 7) |
| Biblioteca carrega, mas sem conquistas | A Steam não respondeu o progresso de conquistas agora; atualize depois. Os jogos aparecem mesmo assim |

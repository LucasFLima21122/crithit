# Marca — CritHit

<img src="brand/logo.svg" alt="Logo do CritHit" width="120" />

## Nome

**CritHit**

### Naming rationale

"Crit Hit" (Critical Hit / acerto crítico) é um termo que qualquer jogador reconhece na hora: é aquele ataque que sai com dano extra, o momento de sorte e habilidade que vira o jogo. A gente pegou esse termo e sobrepôs um segundo significado: **"Crit"** também é a raiz de *crítica* e *critique* — exatamente o que o app faz, permitir que jogadores critiquem (no bom sentido) os jogos que jogaram.

O nome funciona em três camadas:

1. **Gamer**: reconhecível instantaneamente por quem joga, sem precisar explicar.
2. **Produto**: comunica a função central do app — dar uma nota e escrever uma crítica.
3. **Memorável**: curto (7 letras), fácil de falar em português e em inglês, funciona como `@crithit` em qualquer rede social e como domínio (`crithit.app`).

Tagline: **"Cada jogo merece uma crítica."**

## Tom de voz

O CritHit fala como um amigo gamer experiente que também manja de crítica — não como uma enciclopédia nem como uma marca corporativa. Diretrizes:

- **Direto e leve**: frases curtas, sem enrolação. Nada de jargão corporativo ("sinergia", "solução disruptiva").
- **Vocabulário gamer com moderação**: termos como *combo*, *loot*, *backlog*, *platinar* aparecem naturalmente, mas sem forçar gíria em toda frase.
- **Encorajador, nunca elitista**: qualquer pessoa pode dar uma nota e escrever duas linhas — o app não julga quem não é "hardcore".
- **Opinativo, mas respeitoso**: incentiva o usuário a ter e defender uma opinião sobre os jogos, sem tom de ataque a quem pensa diferente.

Exemplos de microcopy:

| Contexto | Texto |
|---|---|
| Tela vazia de reviews | "Ainda sem crítica nenhuma. Bora ser o primeiro a dar essa nota?" |
| Confirmação ao salvar review | "Review salva! Combo de bom gosto ativado." |
| Erro genérico | "Deu ruim aqui do nosso lado. Tenta de novo?" |
| Convite para avaliar | "Zerou (ou desistiu de) esse jogo? Conta pra gente quantas estrelas ele merece." |

## Paleta de cores

Tema escuro como padrão (referência visual do universo gamer e de apps como Letterboxd/Steam), com um roxo elétrico como cor de marca e dourado para o elemento mais importante do produto: a nota em estrelas.

| Token | Hex | Uso |
|---|---|---|
| `background` | `#12121A` | Fundo geral do app |
| `surface` | `#1E1E2A` | Cards, listas, campos |
| `surfaceAlt` | `#292938` | Elementos elevados (modais, app bar) |
| `primary` (Crit Purple) | `#7C3AED` | Cor de marca, botões primários, destaques |
| `primaryDark` | `#4C1D95` | Gradientes, estados pressionados |
| `accent` (Loot Gold) | `#FFC857` | Estrelas de avaliação, destaques de conquista |
| `textPrimary` | `#F5F5F7` | Texto principal sobre fundo escuro |
| `textSecondary` | `#A0A0B2` | Texto de apoio, metadados |
| `success` | `#4ADE80` | Estados positivos (ex: "salvo com sucesso") |
| `danger` | `#F87171` | Erros, ações destrutivas |

## Tipografia

- **Títulos e destaques**: `Space Grotesk` (geométrica, moderna, com personalidade — usada em nomes de jogos, títulos de tela e no logotipo).
- **Corpo de texto**: `Inter` (alta legibilidade em telas pequenas, ótima para reviews longas e listas).
- **Fallback no código**: enquanto as fontes customizadas são carregadas via `google_fonts`, o Material 3 usa a família padrão da plataforma como fallback automático — ou seja, o app nunca fica sem tipografia definida.

## Aplicações do logo

- `docs/brand/logo.svg` — símbolo isolado (ícone de app, favicon, avatar).
- `docs/brand/logo-wordmark.svg` — logo + nome, para cabeçalhos de documentação, splash screen e materiais de pitch.

O símbolo é uma estrela de avaliação com uma "faísca de crit" saindo da ponta — reforça visualmente a ideia de "acerto crítico" e remete diretamente às estrelas de nota do produto.

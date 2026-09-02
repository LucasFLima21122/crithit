<img src="docs/brand/logo.png" alt="Logo do CritHit: monograma Ch com uma estrela dourada" width="120" />

# CritHit

**"Letterboxd para jogos"**, registre os jogos que você jogou, dê uma nota de 1 a 5 estrelas e escreva sua crítica, exatamente como você faria numa plataforma de avaliação de filmes.

Projeto integrado da disciplina **Cross-Platform Application Development** (Ciência da Computação — 2º Ano), desenvolvido em **Flutter/Dart** ao longo dos Checkpoints 4, 5 e 6.

<img src="docs/demo.gif" alt="Demonstração do CritHit: navegação pelo catálogo, tela de detalhe e avaliação por estrelas" width="360" />

## Proposta de valor

Hoje, avaliar jogos é uma experiência fragmentada: nota de crítica especializada num site, review de compra na loja digital, opinião pessoal perdida em um grupo do WhatsApp. O **CritHit** junta tudo isso em um único lugar, focado exclusivamente na experiência pessoal de quem joga: um catálogo de jogos onde qualquer pessoa pode dar sua nota (1 a 5 estrelas) e escrever uma crítica, além de ver o que a comunidade achou de cada jogo.

Veja a documentação completa do produto em [`docs/PRODUCT.md`](docs/PRODUCT.md), a identidade de marca em [`docs/BRANDING.md`](docs/BRANDING.md) e o pitch de negócio em [`docs/PITCH.md`](docs/PITCH.md).

## Integrantes do grupo

| Nome | RM | Papel no projeto |
|---|---|---|
| Felipe Krzyanovski do Santos Menezes | 564878 | Coordenação geral / Product Owner |
| Lucas Ferrari Lima | 563119 | Desenvolvimento Geral do App |
| Carlos Eduardo Pires Cervelli | 563462 | Apoio ao Desenvolvimento e Organizacao do Repositorio |
| Leonardo Lopes Oliveira | 565437 | Identidade visual — logo, paleta de cores, tipografia, Figma |
| Arthur de Souza Matos Dias | 566068 | Documentação — problema, público-alvo, MVP (`docs/PRODUCT.md`) |
| Guilherme Carreri Giampietro | 565676 | Pitch — modelo de negócio e diferencial competitivo (`docs/PITCH.md`) |
| Mateus Patricio Pereira | 564695 | QA/Testes — validação do build |

## Status por Checkpoint

- [x] **Checkpoint 4 — Idealização**: marca, identidade visual, documentação inicial, pitch e projeto Flutter inicial rodando com tela inicial (catálogo mockado) e fluxo de avaliação por estrelas.
- [ ] **Checkpoint 5 — Protótipo funcional**: navegação completa do MVP com dados mockados.
- [ ] **Checkpoint 6 — App final**: MVP completo, documentado e empacotado em APK.

## Como rodar o projeto

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e configurado (Android Studio ou VS Code com os plugins Flutter/Dart).

```bash
# 1. Instale as dependências
flutter pub get

# 2. Rode em um emulador/dispositivo conectado
flutter run

# (alternativa rápida, sem emulador) rode no navegador
flutter run -d chrome

# Analise o código estático
flutter analyze

# Rode os testes de widget
flutter test
```

## Estrutura do projeto

```
lib/
  main.dart                  # ponto de entrada do app
  theme/
    app_colors.dart          # paleta oficial da marca
    app_theme.dart           # ThemeData (Material 3, dark theme)
  models/
    game.dart                # modelos Game e Review
  data/
    mock_games.dart          # catálogo mockado usado nos Checkpoints 4 e 5
  widgets/
    star_rating.dart         # widget de avaliação por estrelas (leitura/escrita)
    game_cover.dart          # capa do jogo (imagem real, com fallback pro emoji)
    game_card.dart           # card de jogo usado na lista
  screens/
    home_screen.dart         # catálogo de jogos
    game_detail_screen.dart  # detalhe do jogo + formulário de avaliação
assets/
  covers/                    # capas reais dos jogos do catálogo mockado
  branding/                  # logo oficial usado dentro do app
docs/
  PRODUCT.md                 # problema, público-alvo, MVP
  BRANDING.md                # nome, tom de voz, paleta, tipografia
  PITCH.md                   # modelo de negócio e diferencial competitivo
  GUIA_FIGMA_CRITHIT.md      # passo a passo pra montar a identidade no Figma
  brand/                     # logo oficial (PNG) + mini brandbook (HTML e prints)
```

## Decisões técnicas (Checkpoint 4)

- **Material 3 + tema escuro**: alinhado à identidade visual do CritHit (ver `docs/BRANDING.md`).
- **`google_fonts`** para tipografia (Space Grotesk nos títulos, Inter no corpo), evitando bundlar arquivos de fonte manualmente.
- **Dados 100% mockados em memória** (`lib/data/mock_games.dart`): não há dependência de backend ainda, está alinhado ao escopo do Checkpoint 4/5.
- **Capas reais com fallback**: as capas dos jogos (`assets/covers/`) são imagens locais de verdade; se algum arquivo faltar, o widget `GameCover` cai automaticamente para um emoji ilustrativo, então o app nunca quebra por causa de uma imagem ausente.
- **Sem imagens externas**: nenhuma imagem vem da internet (nem covers, nem logo), tudo é asset local, pra não depender de rede na hora da apresentação.
- **Sem gerenciador de estado externo**: `StatefulWidget` + `setState` são suficientes para o escopo atual; a introdução de Provider/Riverpod fica para quando houver estado compartilhado mais complexo (Checkpoint 5/6).


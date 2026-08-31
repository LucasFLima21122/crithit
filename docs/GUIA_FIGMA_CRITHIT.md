# Guia Figma — Identidade Visual do CritHit

Guia prático pra montar a identidade visual do CritHit no Figma: o arquivo, o logo (monograma "Ch"), a paleta e a tipografia — já com os valores atualizados depois da mudança pra paleta escura.

## 1. Criando o arquivo

1. Abre o Figma, cria um arquivo novo e renomeia pra **"CritHit — Identidade Visual"**.
2. Cria um Frame grande (tecla `F`, escolhe um preset "Desktop" 1440×1024 ou solta um frame em branco maior) — vai ser o "quadro" onde tudo fica organizado lado a lado: logo, paleta, tipografia.
3. Dá um fundo escuro nesse frame (`#101012`, o mesmo fundo do app) — assim você já vê o logo e as cores exatamente como vão aparecer dentro do app de verdade.

## 2. Desenhando o monograma "Ch" (logo)

A ideia definida: um **"C" grande** com um **"h" pequeno** encostado nele, do lado esquerdo. Passo a passo pra desenhar isso no Figma:

1. **Digita as duas letras**: cria uma camada de texto com "C" (tecla `T`, clica e digita). Usa a fonte **Space Grotesk**, peso **Bold** ou **ExtraBold**, tamanho grande (tipo 200px pra trabalhar confortável — depois você redimensiona o conjunto todo).
2. Cria outra camada de texto só com "h", mesma fonte, mas bem menor (uns 35–40% do tamanho do "C").
3. **Posiciona o "h"**: encosta ele na parte de cima-esquerda do "C", meio "grudado" na curva da letra — pensa em como um "™" ou "©" fica colado do lado de um logotipo, só que aqui o "h" é parte do símbolo, não um selo.
4. **Transforma texto em contorno**: com as duas camadas de texto selecionadas, clica com o botão direito → **Outline Stroke** (ou `Shift+Ctrl+O` / `Shift+Cmd+O` no Mac). Isso converte o texto em formas vetoriais puras — importante porque assim o logo não depende de ninguém ter a fonte Space Grotesk instalada pra abrir o arquivo depois.
5. Se quiser um efeito mais "logo único" (as duas letras se tocando/fundindo em vez de só sobrepostas), seleciona as duas formas e usa **Union Selection** (ícone de booleanos, ou no menu Boolean Groups) — isso funde as duas em um único caminho vetorial.
6. Aplica a cor: seleciona a forma final e troca o fill pra uma das cores da paleta abaixo — o **azul** (`#3B82F6`, Mana Blue) é a escolha mais alinhada, já que é a cor de ação/identidade principal agora que o roxo saiu.
7. Agrupa tudo (`Ctrl+G` / `Cmd+G`) e nomeia o grupo como "CritHit Logo".

**Dica de variação**: depois de ter a versão base, testa colocar o "Ch" dentro de um quadrado com cantos arredondados (`#19191D` ou `#22303F` de fundo) — isso vira automaticamente a versão "ícone de app" (útil pro favicon e pro ícone do APK lá no Checkpoint 6).

## 3. Paleta de cores (atualizada — tema escuro + acentos)

Cria retângulos pequenos (`R`) lado a lado, um pra cada cor, com o hex escrito embaixo:

| Cor | Hex | Uso |
|---|---|---|
| Fundo | `#101012` | Fundo geral do app |
| Superfície | `#19191D` | Cards, listas, campos |
| Superfície elevada | `#24242A` | App bar, modais, inputs |
| Fundo de capa (sem imagem) | `#22303F` | Placeholder de capa de jogo |
| **Primária — Mana Blue** | `#3B82F6` | Botões, ações, destaques (é a cor do logo agora) |
| **Estrelas — Loot Gold** | `#FFC857` | Só as estrelas de avaliação — não usar em outro lugar |
| **Sucesso — Combo Green** | `#4ADE80` | Feedback positivo (ex.: "review salva") |
| **Erro — Boss Red** | `#F87171` | Avisos e erros |
| Texto principal | `#F2F2F5` | Texto sobre fundo escuro |
| Texto secundário | `#9C9CA6` | Textos de apoio, metadados |

Regra pra manter consistência (bom repetir isso no board do Figma como nota): dourado é exclusivo das estrelas, verde/vermelho só aparecem em feedback de sucesso/erro — nunca como decoração solta.

## 4. Tipografia

Cria dois textos de exemplo pra mostrar a hierarquia:

- **Títulos**: fonte **Space Grotesk**, peso Bold/ExtraBold — usa pra mostrar um título de tela, tipo "Catálogo" ou o nome de um jogo.
- **Corpo de texto**: fonte **Inter**, peso Regular — usa pra um parágrafo de exemplo, tipo uma sinopse ou review.

As duas fontes já vêm disponíveis na busca de fontes do Figma (são Google Fonts), sem precisar instalar nada — só digitar o nome no seletor.

## 5. Exportando de volta pro código

Quando o logo estiver pronto:

1. Seleciona o grupo "CritHit Logo".
2. Menu direito → **Export** (ou painel de export no canto inferior direito) → escolhe formato **SVG** → clica em **Export "CritHit Logo"**.
3. Manda esse arquivo `.svg` aqui no chat (ou salva na pasta `docs/brand/` do projeto substituindo o `logo.svg` atual) que eu já troco a referência no app e na documentação — a tela inicial vai passar a mostrar o logo de verdade no lugar do emoji 🎮 que está lá hoje.

## 6. Checklist rápido antes de fechar o board

- [ ] Logo "Ch" desenhado e convertido em contorno (não depende de fonte instalada)
- [ ] Logo testado em fundo escuro (`#101012`) — precisa ficar legível
- [ ] Todas as 10 cores da paleta com o hex escrito do lado
- [ ] Exemplo de título (Space Grotesk) e corpo de texto (Inter) lado a lado
- [ ] (Opcional) print da tela do app rodando, pra comparar identidade documentada vs. implementada
- [ ] Logo exportado em SVG e enviado pra atualizar o repositório

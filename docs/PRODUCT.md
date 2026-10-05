# Documentação do produto — CritHit

## O problema

Quem joga videogame termina uma campanha, zera um indie ou passa 40 horas num RPG e, no fim, quer fazer duas coisas: **guardar essa experiência em algum lugar** e **saber o que outras pessoas acharam**. Hoje isso é resolvido de forma fragmentada:

- Notas de crítica especializada (Metacritic, IGN) são genéricas e não refletem o gosto pessoal de quem joga.
- Lojas digitais (Steam, PSN, Nintendo eShop) misturam review de compra com review de experiência, e o histórico de jogos fica preso dentro de cada plataforma.
- Não existe, para jogos, um equivalente direto ao que o Letterboxd é para filmes ou o Goodreads é para livros: um lugar simples, bonito e focado só em **registrar, avaliar de 1 a 5 estrelas e escrever uma crítica pessoal** sobre cada jogo, independente da plataforma em que foi jogado.

## Público-alvo

- **Persona principal — "o completista social"**: jogador(a) de 16 a 32 anos que já joga regularmente (PC, console ou mobile), gosta de organizar o que já jogou/está jogando/quer jogar, e curte trocar opinião sobre jogos com amigos ou comunidades online.
- **Persona secundária — "o crítico casual"**: pessoa que não se considera "hardcore gamer", mas joga de vez em quando e gosta de deixar registrada sua opinião sincera sobre os jogos que passou.
- **Contexto de uso**: universitários e jovens profissionais, público já habituado a apps de avaliação (Letterboxd, Goodreads, TripAdvisor) e que naturalmente pede "e para jogos, existe algo assim?".

## Funcionalidades principais (MVP)

O MVP do CritHit responde a uma pergunta só: *"o que eu joguei, o que eu achei, e o que os outros acharam?"*

1. **Catálogo de jogos**: lista de jogos (inicialmente com dados mockados/curados) com capa, título, plataforma e gênero.
2. **Avaliação por estrelas (1 a 5)**: cada usuário atribui uma nota de 1 a 5 estrelas para um jogo que jogou — o coração do produto, no mesmo espírito de uma plataforma de filmes.
3. **Review em texto**: campo livre para escrever uma crítica pessoal sobre o jogo, associada à nota dada.
4. **Perfil / histórico do usuário**: lista dos jogos avaliados por aquela pessoa, com nota e data.
5. **Busca e detalhes do jogo**: tela de detalhe do jogo com sinopse, nota média da comunidade e lista de reviews de outros usuários.
6. **Importação da biblioteca Steam** (adicionada no Checkpoint 5): o usuário conecta o perfil da Steam e todos os jogos dele entram no CritHit, com horas jogadas, conquistas e o selo de "Platinado" (100% das conquistas), sem precisar cadastrar jogo por jogo. Ataca direto a dor de "o histórico de jogos fica preso dentro de cada plataforma".

Funcionalidades fora do MVP (roadmap futuro): sistema de amigos/seguir usuários, listas personalizadas (tipo "quero jogar"), importação de PlayStation e Xbox (as APIs são fechadas ou não oficiais, por isso a Steam veio primeiro), recomendações por algoritmo.

## Escopo por Checkpoint

- **Checkpoint 4**: conceito, marca, identidade visual e projeto Flutter inicial rodando (tela inicial com catálogo mockado e acesso à avaliação).
- **Checkpoint 5 (este)**: navegação completa entre todas as telas do MVP (boas-vindas, login/cadastro, início, busca com filtros, biblioteca Steam, detalhe do jogo, avaliação, perfil), dados mockados realistas, banco de dados no Supabase (login, perfis e reviews) e importação da biblioteca Steam.
- **Checkpoint 6**: MVP funcional completo, documentado e empacotado em um APK instalável.

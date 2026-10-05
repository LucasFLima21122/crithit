# Capas dos jogos

Capas locais (em pé, proporção 2:3) dos 16 jogos do catálogo curado que existem na Steam. Elas ficam dentro do app para o catálogo funcionar sem internet.

Para adicionar um jogo novo ao catálogo (`lib/data/mock_catalog.dart`), salve a capa aqui com o mesmo nome usado no campo `coverAsset`, em `.jpg`. Se o jogo existe na Steam, a capa pode ser baixada do CDN:

```
https://cdn.cloudflare.steamstatic.com/steam/apps/<steamAppId>/library_600x900.jpg
```

Se o arquivo não existir, o widget `GameCover` (`lib/widgets/game_cover.dart`) tenta, nesta ordem: capa da Steam pela internet → banner da Steam → emoji do jogo. O Zelda (exclusivo de Switch, sem Steam) fica de propósito sem capa, para mostrar o fallback em emoji.

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../data/mock_catalog.dart";
import "../models/game.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../widgets/common.dart";
import "../widgets/game_card.dart";
import "game_detail_screen.dart";
import "main_shell.dart";

enum _SortOrder {
  bestRated("Mais bem avaliados"),
  mostReviewed("Mais avaliados"),
  newest("Lançamento mais recente"),
  alphabetical("A–Z");

  const _SortOrder(this.label);
  final String label;
}

/// Aba "Buscar": busca por nome/desenvolvedora, filtros por plataforma e
/// gênero, "só jogos da minha Steam" e ordenação.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  String? _platform;
  String? _genre;
  bool _onlySteam = false;
  _SortOrder _sort = _SortOrder.bestRated;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _query.text.isNotEmpty ||
      _platform != null ||
      _genre != null ||
      _onlySteam;

  void _clearFilters() {
    setState(() {
      _query.clear();
      _platform = null;
      _genre = null;
      _onlySteam = false;
    });
  }

  List<Game> _results(AppState state) {
    final String query = _query.text.trim().toLowerCase();
    final List<Game> games = state.allGames.where((game) {
      if (query.isNotEmpty &&
          !game.title.toLowerCase().contains(query) &&
          !(game.developer?.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      if (_platform != null && !game.platform.contains(_platform!)) {
        return false;
      }
      if (_genre != null && game.genre != _genre) return false;
      if (_onlySteam && state.steamEntryFor(game) == null) return false;
      return true;
    }).toList();

    int byTitle(Game a, Game b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase());

    games.sort((a, b) {
      switch (_sort) {
        case _SortOrder.bestRated:
          final int c = state
              .averageFor(b.id)
              .compareTo(state.averageFor(a.id));
          return c != 0 ? c : byTitle(a, b);
        case _SortOrder.mostReviewed:
          final int c = state
              .reviewsFor(b.id)
              .length
              .compareTo(state.reviewsFor(a.id).length);
          return c != 0 ? c : byTitle(a, b);
        case _SortOrder.newest:
          final int c = (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0);
          return c != 0 ? c : byTitle(a, b);
        case _SortOrder.alphabetical:
          return byTitle(a, b);
      }
    });
    return games;
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Game> results = _results(state);

    return Scaffold(
      appBar: AppBar(title: const Text("Buscar")),
      body: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: "Nome do jogo ou desenvolvedora",
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: "Limpar busca",
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(_query.clear),
                        ),
                ),
              ),
            ),
            _ChipRow(
              children: [
                for (final String platform in kPlatforms)
                  FilterChip(
                    label: Text(platform),
                    selected: _platform == platform,
                    onSelected: (selected) =>
                        setState(() => _platform = selected ? platform : null),
                  ),
              ],
            ),
            _ChipRow(
              children: [
                if (state.library != null)
                  FilterChip(
                    avatar: const Icon(Icons.sports_esports_rounded, size: 16),
                    label: const Text("Na minha Steam"),
                    selected: _onlySteam,
                    onSelected: (selected) =>
                        setState(() => _onlySteam = selected),
                  ),
                for (final String genre in kGenres)
                  FilterChip(
                    label: Text(genre),
                    selected: _genre == genre,
                    onSelected: (selected) =>
                        setState(() => _genre = selected ? genre : null),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(
                children: [
                  Text(
                    results.length == 1 ? "1 jogo" : "${results.length} jogos",
                    style: textTheme.bodySmall,
                  ),
                  if (_hasFilters)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text("Limpar filtros"),
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<_SortOrder>(
                        tooltip: "Ordenar",
                        initialValue: _sort,
                        onSelected: (value) => setState(() => _sort = value),
                        itemBuilder: (context) => [
                          for (final _SortOrder order in _SortOrder.values)
                            PopupMenuItem<_SortOrder>(
                              value: order,
                              child: Text(order.label),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sort_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _sort.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? SingleChildScrollView(
                      child: EmptyState(
                        emoji: "🕹️",
                        title: "Nenhum jogo encontrado",
                        message: state.library == null
                            ? "Tenta outro nome ou tira algum filtro. Dica: importando sua Steam, todos os seus jogos aparecem aqui."
                            : "Tenta outro nome ou tira algum filtro.",
                        actionLabel: state.library == null
                            ? "Importar Steam"
                            : null,
                        onAction: () =>
                            MainShell.goToTab(context, MainShell.libraryTab),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => GameCard(
                        game: results[index],
                        onTap: () => openGame(context, results[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

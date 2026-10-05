import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/steam.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_poster.dart";
import "../widgets/platinum_badge.dart";
import "game_detail_screen.dart";
import "main_shell.dart";
import "steam_connect_screen.dart";

enum _LibraryFilter {
  all("Todos"),
  played("Jogados"),
  platinum("Platinados"),
  backlog("Nunca jogados");

  const _LibraryFilter(this.label);
  final String label;
}

enum _LibrarySort {
  playtime("Mais jogados"),
  recent("Jogados recentemente"),
  achievements("% de conquistas"),
  alphabetical("A–Z");

  const _LibrarySort(this.label);
  final String label;
}

/// Abre a tela para conectar a Steam e mostra o resultado.
Future<void> openSteamConnect(BuildContext context) async {
  final String? message = await Navigator.of(context).push<String>(
    MaterialPageRoute<String>(builder: (_) => const SteamConnectScreen()),
  );
  if (message != null && context.mounted) showCritHitSnack(context, message);
}

/// Aba "Biblioteca": jogos importados da Steam, com horas jogadas,
/// conquistas e platinas — sem precisar adicionar um por um.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  _LibraryFilter _filter = _LibraryFilter.all;
  _LibrarySort _sort = _LibrarySort.playtime;

  List<SteamOwnedGame> _visible(SteamLibrary library) {
    final List<SteamOwnedGame> games = library.games.where((g) {
      switch (_filter) {
        case _LibraryFilter.all:
          return true;
        case _LibraryFilter.played:
          return g.wasPlayed;
        case _LibraryFilter.platinum:
          return g.isPlatinum;
        case _LibraryFilter.backlog:
          return !g.wasPlayed;
      }
    }).toList();

    int byName(SteamOwnedGame a, SteamOwnedGame b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());

    games.sort((a, b) {
      switch (_sort) {
        case _LibrarySort.playtime:
          final int c = b.playtimeMinutes.compareTo(a.playtimeMinutes);
          return c != 0 ? c : byName(a, b);
        case _LibrarySort.recent:
          final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
          final int c = (b.lastPlayed ?? epoch).compareTo(
            a.lastPlayed ?? epoch,
          );
          return c != 0 ? c : byName(a, b);
        case _LibrarySort.achievements:
          final int c = b.achievementRatio.compareTo(a.achievementRatio);
          return c != 0 ? c : byName(a, b);
        case _LibrarySort.alphabetical:
          return byName(a, b);
      }
    });
    return games;
  }

  Future<void> _confirmDisconnect(AppState state) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Desconectar a Steam?"),
        content: const Text(
          "Sua biblioteca some do CritHit, mas as reviews que você escreveu continuam aqui.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Desconectar"),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.disconnectSteam();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final SteamLibrary? library = state.library;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Biblioteca"),
        actions: [
          if (library != null) ...[
            IconButton(
              tooltip: "Atualizar biblioteca",
              onPressed: state.loadingSteam ? null : state.refreshSteam,
              icon: const Icon(Icons.refresh_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: "Mais opções",
              onSelected: (value) {
                if (value == "switch") openSteamConnect(context);
                if (value == "disconnect") _confirmDisconnect(state);
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: "switch",
                  child: Text("Trocar conta Steam"),
                ),
                PopupMenuItem<String>(
                  value: "disconnect",
                  child: Text("Desconectar Steam"),
                ),
              ],
            ),
          ],
        ],
      ),
      body: library == null
          ? _NotConnected(state: state)
          : _buildLibrary(context, state, library),
    );
  }

  Widget _buildLibrary(
    BuildContext context,
    AppState state,
    SteamLibrary library,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<SteamOwnedGame> games = _visible(library);
    final int playedPercent = library.games.isEmpty
        ? 0
        : (library.playedCount * 100 / library.games.length).round();

    return RefreshIndicator(
      onRefresh: state.refreshSteam,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth.clamp(0, 760);
          final int columns = (width / 130).floor().clamp(2, 6);
          final double posterWidth =
              (width - 32 - (columns - 1) * 12) / columns;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.loadingSteam)
                      const LinearProgressIndicator(minHeight: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          UserAvatar(
                            initials: library.profile.personaName
                                .substring(0, 1)
                                .toUpperCase(),
                            imageUrl: library.profile.avatarUrl,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  library.profile.personaName,
                                  style: textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Steam · atualizado ${formatRelativeDate(library.fetchedAt)}",
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isSteamDemo)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          "Modo offline: esta é uma biblioteca de demonstração. Com o Supabase configurado, os dados vêm da sua conta Steam de verdade.",
                          style: textTheme.bodySmall,
                        ),
                      ),
                    if (state.steamError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          state.steamError!,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              value: "${library.games.length}",
                              label: "Jogos",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatTile(
                              value: formatHoursTotal(
                                library.totalPlaytimeMinutes,
                              ),
                              label: "Horas",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatTile(
                              value: "${library.platinumCount}",
                              label: "Platinados",
                              icon: Icons.emoji_events_rounded,
                              iconColor: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatTile(
                              value: "$playedPercent%",
                              label: "Já jogados",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        children: [
                          for (final _LibraryFilter filter
                              in _LibraryFilter.values)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter.label),
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
                      child: Row(
                        children: [
                          Text(
                            games.length == 1
                                ? "1 jogo"
                                : "${games.length} jogos",
                            style: textTheme.bodySmall,
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: PopupMenuButton<_LibrarySort>(
                                tooltip: "Ordenar",
                                initialValue: _sort,
                                onSelected: (value) =>
                                    setState(() => _sort = value),
                                itemBuilder: (context) => [
                                  for (final _LibrarySort sort
                                      in _LibrarySort.values)
                                    PopupMenuItem<_LibrarySort>(
                                      value: sort,
                                      child: Text(sort.label),
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
                    if (games.isEmpty)
                      EmptyState(
                        emoji: _filter == _LibraryFilter.platinum ? "🏆" : "📭",
                        title: _filter == _LibraryFilter.platinum
                            ? "Nenhuma platina ainda"
                            : "Nada por aqui",
                        message: _filter == _LibraryFilter.platinum
                            ? "Quando você desbloquear 100% das conquistas de um jogo, ele aparece aqui."
                            : "Nenhum jogo da sua biblioteca bate com esse filtro.",
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: [
                            for (final SteamOwnedGame owned in games)
                              GamePoster(
                                width: posterWidth,
                                game: state.gameForSteam(owned),
                                onTap: () => openGame(
                                  context,
                                  state.gameForSteam(owned),
                                ),
                                overlay: owned.isPlatinum
                                    ? const PlatinumBadge(compact: true)
                                    : null,
                                caption: _PosterCaption(owned: owned),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PosterCaption extends StatelessWidget {
  const _PosterCaption({required this.owned});

  final SteamOwnedGame owned;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatPlaytime(owned.playtimeMinutes), style: textTheme.bodySmall),
        if (owned.hasAchievements && owned.wasPlayed) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: owned.achievementRatio,
              minHeight: 4,
              color: owned.isPlatinum ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadingSteam) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Importando sua biblioteca Steam...",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        child: ContentWidth(
          maxWidth: 480,
          child: Column(
            children: [
              EmptyState(
                emoji: "🎮",
                title: "Traga sua Steam pro CritHit",
                message:
                    "Conecte seu perfil e todos os seus jogos aparecem aqui — com horas jogadas, conquistas e platinas. Sem cadastrar um por um.",
                actionLabel: "Conectar Steam",
                onAction: () => openSteamConnect(context),
              ),
              if (state.steamError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Não deu pra recarregar sua Steam: ${state.steamError}",
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                ),
              TextButton(
                onPressed: () =>
                    MainShell.goToTab(context, MainShell.searchTab),
                child: const Text("Ou explore o catálogo"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/library.dart";
import "../models/psn.dart";
import "../state/app_state.dart";
import "../theme/app_colors.dart";
import "../utils/formatters.dart";
import "../widgets/common.dart";
import "../widgets/game_poster.dart";
import "../widgets/platform_style.dart";
import "../widgets/platinum_badge.dart";
import "game_detail_screen.dart";
import "main_shell.dart";
import "psn_connect_screen.dart";
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

/// Abre a tela para conectar a PSN e mostra o resultado.
Future<void> openPsnConnect(BuildContext context) async {
  final String? message = await Navigator.of(context).push<String>(
    MaterialPageRoute<String>(builder: (_) => const PsnConnectScreen()),
  );
  if (message != null && context.mounted) showCritHitSnack(context, message);
}

Future<void> openConnect(BuildContext context, GamePlatform platform) {
  switch (platform) {
    case GamePlatform.steam:
      return openSteamConnect(context);
    case GamePlatform.psn:
      return openPsnConnect(context);
  }
}

/// Aba "Biblioteca": jogos importados da Steam ou da PlayStation, com horas
/// jogadas, conquistas/troféus e platinas — sem adicionar um por um.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  GamePlatform _platform = GamePlatform.steam;
  _LibraryFilter _filter = _LibraryFilter.all;
  _LibrarySort _sort = _LibrarySort.playtime;

  List<OwnedGame> _visible(GameLibrary library) {
    final List<OwnedGame> games = library.games.where((g) {
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

    int byName(OwnedGame a, OwnedGame b) =>
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

  bool _loading(AppState state) =>
      _platform == GamePlatform.steam ? state.loadingSteam : state.loadingPsn;

  String? _error(AppState state) =>
      _platform == GamePlatform.steam ? state.steamError : state.psnError;

  bool _isDemo(AppState state) =>
      _platform == GamePlatform.steam ? state.isSteamDemo : state.isPsnDemo;

  Future<void> _refresh(AppState state) => _platform == GamePlatform.steam
      ? state.refreshSteam()
      : state.refreshPsn();

  Future<void> _confirmDisconnect(AppState state) async {
    final String name = _platform.label;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Desconectar a $name?"),
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
    if (confirmed != true) return;
    if (_platform == GamePlatform.steam) {
      await state.disconnectSteam();
    } else {
      await state.disconnectPsn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final GameLibrary? library = state.libraryFor(_platform);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Biblioteca"),
        actions: [
          if (library != null) ...[
            IconButton(
              tooltip: "Atualizar biblioteca",
              onPressed: _loading(state) ? null : () => _refresh(state),
              icon: const Icon(Icons.refresh_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: "Mais opções",
              onSelected: (value) {
                if (value == "switch") openConnect(context, _platform);
                if (value == "disconnect") _confirmDisconnect(state);
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: "switch",
                  child: Text("Trocar conta ${_platform.shortLabel}"),
                ),
                PopupMenuItem<String>(
                  value: "disconnect",
                  child: Text("Desconectar ${_platform.shortLabel}"),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<GamePlatform>(
                  showSelectedIcon: false,
                  segments: [
                    for (final GamePlatform p in GamePlatform.values)
                      ButtonSegment<GamePlatform>(
                        value: p,
                        icon: Icon(p.icon, color: p.color, size: 18),
                        label: Text(p.label),
                      ),
                  ],
                  selected: <GamePlatform>{_platform},
                  onSelectionChanged: (selection) => setState(() {
                    _platform = selection.first;
                    _filter = _LibraryFilter.all;
                  }),
                ),
              ),
            ),
          ),
          Expanded(
            child: library == null
                ? _NotConnected(
                    platform: _platform,
                    loading: _loading(state),
                    error: _error(state),
                  )
                : _buildLibrary(context, state, library),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary(
    BuildContext context,
    AppState state,
    GameLibrary library,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<OwnedGame> games = _visible(library);
    final int playedPercent = library.games.isEmpty
        ? 0
        : (library.playedCount * 100 / library.games.length).round();
    final GameLibrary lib = library;
    final String subtitle = lib is PsnLibrary && lib.profile.trophyLevel != null
        ? "PSN · nível ${lib.profile.trophyLevel} · ${lib.profile.earnedTrophies.platinum} platinas · atualizado ${formatRelativeDate(lib.fetchedAt)}"
        : "${_platform.label} · atualizado ${formatRelativeDate(library.fetchedAt)}";

    return RefreshIndicator(
      onRefresh: () => _refresh(state),
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
                    if (_loading(state))
                      const LinearProgressIndicator(minHeight: 2),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          UserAvatar(
                            initials: library.accountName
                                .substring(0, 1)
                                .toUpperCase(),
                            imageUrl: library.avatarUrl,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  library.accountName,
                                  style: textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(subtitle, style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isDemo(state))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          "Modo offline: esta é uma biblioteca de demonstração. Com o Supabase configurado, os dados vêm da sua conta ${_platform.label} de verdade.",
                          style: textTheme.bodySmall,
                        ),
                      ),
                    if (_error(state) != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          _error(state)!,
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
                              iconColor: AppColors.platinum,
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
                              child: _SortMenu(
                                sort: _sort,
                                onSelected: (value) =>
                                    setState(() => _sort = value),
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
                            ? (_platform == GamePlatform.steam
                                  ? "Quando você desbloquear 100% das conquistas de um jogo, ele aparece aqui."
                                  : "Quando você ganhar o troféu de platina de um jogo, ele aparece aqui.")
                            : "Nenhum jogo da sua biblioteca bate com esse filtro.",
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 18,
                          children: [
                            for (final OwnedGame owned in games)
                              GamePoster(
                                width: posterWidth,
                                game: state.gameForOwned(owned),
                                onTap: () => openGame(
                                  context,
                                  state.gameForOwned(owned),
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

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSelected});

  final _LibrarySort sort;
  final ValueChanged<_LibrarySort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_LibrarySort>(
      tooltip: "Ordenar",
      initialValue: sort,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final _LibrarySort option in _LibrarySort.values)
          PopupMenuItem<_LibrarySort>(value: option, child: Text(option.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                sort.label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterCaption extends StatelessWidget {
  const _PosterCaption({required this.owned});

  final OwnedGame owned;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String time = owned.playtimeMinutes > 0
        ? formatPlaytime(owned.playtimeMinutes)
        : owned.wasPlayed
        ? "${(owned.achievementRatio * 100).round()}% dos troféus"
        : "nunca jogado";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time, style: textTheme.bodySmall),
        if (owned.hasAchievements && owned.wasPlayed) ...[
          const SizedBox(height: 6),
          SegmentedBar(
            value: owned.achievementRatio,
            segments: 8,
            height: 5,
            color: owned.isPlatinum ? AppColors.platinum : AppColors.primary,
          ),
        ],
      ],
    );
  }
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({
    required this.platform,
    required this.loading,
    required this.error,
  });

  final GamePlatform platform;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Importando sua biblioteca ${platform.label}...",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    final bool steam = platform == GamePlatform.steam;
    return Center(
      child: SingleChildScrollView(
        child: ContentWidth(
          maxWidth: 480,
          child: Column(
            children: [
              EmptyState(
                emoji: steam ? "🖥️" : "🎮",
                title: steam
                    ? "Traga sua Steam pro CritHit"
                    : "Traga sua PSN pro CritHit",
                message: steam
                    ? "Conecte seu perfil e todos os seus jogos aparecem aqui — com horas jogadas, conquistas e platinas. Sem cadastrar um por um."
                    : "Conecte sua conta PlayStation e seus jogos de PS4 e PS5 aparecem aqui — com troféus, platinas e tempo de jogo.",
                actionLabel: steam ? "Conectar Steam" : "Conectar PSN",
                onAction: () => openConnect(context, platform),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Não deu pra recarregar sua ${platform.label}: $error",
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

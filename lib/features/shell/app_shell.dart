import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/animated_toggle_icon.dart';
import '../../shared/widgets/app_sheet.dart';
import 'package:ionicons/ionicons.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final location = GoRouterState.of(context).uri.path;

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          top: true,
          bottom: false,
          child: child,
        ),
        bottomNavigationBar: _BottomTabBar(activePath: location),
      ),
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({required this.activePath});
  final String activePath;

  static const _tabs = [
    _TabSpec(path: '/', label: 'home', icon: Ionicons.home_outline, activeIcon: Ionicons.home),
    _TabSpec(path: '/azkars', label: 'azkars', icon: Ionicons.bookmark_outline, activeIcon: Ionicons.bookmark),
    _TabSpec(path: '/popular', label: 'popular', icon: Ionicons.sparkles_outline, activeIcon: Ionicons.sparkles),
    _TabSpec(path: '/quran', label: 'quran', icon: Ionicons.book_outline, activeIcon: Ionicons.book),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final media = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      padding: EdgeInsets.only(bottom: media.padding.bottom),
      child: SizedBox(
        height: AppTokens.tabBarHeight,
        child: Row(
          children: [
            ..._tabs.map((tab) {
              final selected = _isActive(activePath, tab.path);
              return Expanded(
                child: _TabButton(
                  tab: tab,
                  selected: selected,
                  label: l10n.t('nav.${tab.label}'),
                  onTap: () => context.go(tab.path),
                ),
              );
            }),
            Expanded(
              child: _TabButton(
                tab: const _TabSpec(
                  path: '__more__',
                  label: 'more',
                  icon: Ionicons.apps_outline,
                  activeIcon: Ionicons.apps_outline,
                ),
                selected: false,
                label: l10n.t('nav.more'),
                onTap: () => _openMore(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(String currentPath, String tabPath) {
    if (tabPath == '/') {
      return currentPath == '/' ||
          currentPath.isEmpty ||
          currentPath == '/home';
    }
    return currentPath == tabPath || currentPath.startsWith('$tabPath/');
  }

  void _openMore(BuildContext context) {
    final l10n = AppL10n.of(context);
    showAppSheet(
      context: context,
      title: l10n.t('nav.more'),
      builder: (ctx) => _MoreSheet(),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final _TabSpec tab;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.accent : palette.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedToggleIcon(
            outlineIcon: tab.icon,
            filledIcon: tab.activeIcon,
            active: selected,
            activeColor: palette.accent,
            inactiveColor: palette.textMuted,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  static const _gridItems = [
    _MoreItem(path: '/qibla', label: 'qibla', icon: Ionicons.compass_outline),
    _MoreItem(path: '/calendar', label: 'calendar', icon: Ionicons.calendar_outline),
    _MoreItem(path: '/names', label: 'names', icon: Ionicons.list_outline),
    _MoreItem(path: '/tasbih', label: 'tasbih', icon: Ionicons.disc_outline),
  ];

  static const _settingsItem = _MoreItem(
    path: '/settings',
    label: 'settings',
    icon: Ionicons.settings_outline,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.0,
          children: _gridItems
              .map((it) =>
                  _MoreTile(item: it, label: l10n.t('nav.${it.label}')))
              .toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: _MoreTile(
            item: _settingsItem,
            label: l10n.t('nav.${_settingsItem.label}'),
          ),
        ),
      ],
    );
  }
}

class _MoreItem {
  const _MoreItem({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final IconData icon;
}

class _MoreTile extends StatefulWidget {
  const _MoreTile({required this.item, required this.label});
  final _MoreItem item;
  final String label;

  @override
  State<_MoreTile> createState() => _MoreTileState();
}

class _MoreTileState extends State<_MoreTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        Navigator.of(context).pop();
        context.push(widget.item.path);
      },
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        decoration: BoxDecoration(
          color: _down ? palette.surface3 : palette.surface2,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: palette.line),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.item.icon, size: 18, color: palette.accentStrong),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

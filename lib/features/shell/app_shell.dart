import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_sheet.dart';

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
          child: Column(
            children: [
              Expanded(child: child),
            ],
          ),
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
    _TabSpec(path: '/', label: 'home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _TabSpec(path: '/azkars', label: 'azkars', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book),
    _TabSpec(path: '/qibla', label: 'qibla', icon: Icons.explore_outlined, activeIcon: Icons.explore),
    _TabSpec(path: '/quran', label: 'quran', icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final media = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
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
                  icon: Icons.more_horiz,
                  activeIcon: Icons.more_horiz,
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
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  static const _items = [
    _MoreItem(path: '/calendar', label: 'calendar', icon: Icons.calendar_month_rounded),
    _MoreItem(path: '/names', label: 'names', icon: Icons.format_list_numbered_rounded),
    _MoreItem(path: '/tasbih', label: 'tasbih', icon: Icons.adjust_rounded),
    _MoreItem(path: '/settings', label: 'settings', icon: Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: _items.map((it) => _MoreTile(item: it, label: l10n.t('nav.${it.label}'))).toList(),
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
        context.go(widget.item.path);
      },
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : palette.surface,
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
                color: palette.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.item.icon, size: 19, color: palette.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14,
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

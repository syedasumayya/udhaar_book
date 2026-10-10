import 'package:flutter/material.dart';

/// Money colours that read well in both light and dark themes.
extension AppPalette on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get positiveColor =>
      _isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  Color get negativeColor =>
      _isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
  Color get warningColor =>
      _isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
}

/// Keeps page content to a readable width on big screens.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  static const _hues = <double>[174, 210, 262, 330, 24, 142, 48, 190];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trimmed = name.trim();
    final hash = trimmed.codeUnits.fold<int>(
      0,
      (h, c) => (h * 31 + c) & 0x7fffffff,
    );
    final hue = _hues[hash % _hues.length];
    final bg = HSLColor.fromAHSL(1, hue, 0.45, dark ? 0.28 : 0.88).toColor();
    final fg = HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.82 : 0.28).toColor();
    final initial =
        trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon: icon, color: theme.colorScheme.primary, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
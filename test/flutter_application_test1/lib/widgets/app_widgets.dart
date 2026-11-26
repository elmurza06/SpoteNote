import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../models/item_model.dart';
import '../providers/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Мини-хелпер локализации. Единственное место, где читается текущий язык.
String tr(String ru, String en) => appState.isRu ? ru : en;

const String kMonoFont = 'monospace';
const double kRadius = 12;

/// Плоский «тинт» цвета поверх kCard (без прозрачности и теней).
Color tint(Color c, [int alpha = 28]) =>
    Color.alphaBlend(c.withAlpha(alpha), AppColors.kCard);

IconData categoryIcon(SpotCategory c) {
  switch (c) {
    case SpotCategory.todo:
      return Icons.check_circle_outline_rounded;
    case SpotCategory.note:
      return Icons.notes_rounded;
    case SpotCategory.wifi:
      return Icons.wifi_rounded;
  }
}

String categoryLabel(SpotCategory c) {
  switch (c) {
    case SpotCategory.todo:
      return 'To-Do';
    case SpotCategory.note:
      return tr('Список', 'List');
    case SpotCategory.wifi:
      return 'Wi-Fi';
  }
}

OutlineInputBorder _border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: 1),
    );

// ─────────────────────────────────────────────────────────────────────────────
// AppBar divider
// ─────────────────────────────────────────────────────────────────────────────

class SpotAppBarDivider extends StatelessWidget implements PreferredSizeWidget {
  const SpotAppBarDivider({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(1);

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.kBorder);
}

// ─────────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────────

class SpotCard extends StatelessWidget {
  const SpotCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kRadius);
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.kCard,
        borderRadius: radius,
        border: Border.all(color: AppColors.kBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges
// ─────────────────────────────────────────────────────────────────────────────

class SpotAddressBadge extends StatelessWidget {
  const SpotAddressBadge({
    super.key,
    required this.address,
    this.onTap,
    this.showCopyIcon = false,
  });

  final String address;
  final VoidCallback? onTap;
  final bool showCopyIcon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurfaceElevated,
        borderRadius: radius,
        border: Border.all(color: AppColors.kBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kMonoFont,
                      fontSize: 12,
                      color: AppColors.kAccentBright,
                    ),
                  ),
                ),
                if (showCopyIcon) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded,
                      size: 13, color: AppColors.kDim),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NfcStatusBadge extends StatelessWidget {
  const NfcStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint(AppColors.kSuccess, 24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tint(AppColors.kSuccess, 80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nfc_rounded, size: 13, color: AppColors.kSuccess),
          const SizedBox(width: 4),
          Text(
            tr('NFC привязан', 'NFC Linked'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.kSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text, buttons, FAB, empty state
// ─────────────────────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
          color: AppColors.kDim,
        ),
      );
}

class SpotTextField extends StatelessWidget {
  const SpotTextField({
    super.key,
    this.controller,
    this.hint,
    this.autofocus = false,
    this.mono = false,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
    this.prefixIcon,
    this.errorText,
    this.textInputAction,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool autofocus;
  final bool mono;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final String? errorText;
  final TextInputAction? textInputAction;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: 1,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      textInputAction: textInputAction,
      cursorColor: AppColors.kAccentBright,
      style: TextStyle(
        color: AppColors.kText,
        fontSize: 15,
        fontFamily: mono ? kMonoFont : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.kDim,
          fontSize: 15,
          fontFamily: mono ? kMonoFont : null,
        ),
        errorText: errorText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: AppColors.kDim),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.kSurfaceElevated,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(AppColors.kBorder),
        enabledBorder: _border(AppColors.kBorder),
        focusedBorder: _border(AppColors.kAccent),
        errorBorder: _border(AppColors.kDanger),
        focusedErrorBorder: _border(AppColors.kDanger),
      ),
    );
  }
}

enum SpotButtonKind { primary, secondary, danger }

class SpotButton extends StatelessWidget {
  const SpotButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = SpotButtonKind.secondary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SpotButtonKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    switch (kind) {
      case SpotButtonKind.primary:
        bg = AppColors.kAccentBright;
        fg = AppColors.kBg;
        border = AppColors.kAccentBright;
        break;
      case SpotButtonKind.secondary:
        bg = Colors.transparent;
        fg = AppColors.kText;
        border = AppColors.kBorder;
        break;
      case SpotButtonKind.danger:
        bg = Colors.transparent;
        fg = AppColors.kDanger;
        border = tint(AppColors.kDanger, 90);
        break;
    }

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 46,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledForegroundColor: AppColors.kDim,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: border, width: 1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpotFab extends StatelessWidget {
  const SpotFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      backgroundColor: AppColors.kAccentBright,
      foregroundColor: AppColors.kBg,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.kBorder, width: 1),
              ),
              child: Icon(icon, color: AppColors.kDim, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.kText,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.kDim),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SnackBar
// ─────────────────────────────────────────────────────────────────────────────

enum SpotSnackKind { info, success, error }

void showSpotSnackOn(
  ScaffoldMessengerState messenger,
  String message, {
  SpotSnackKind kind = SpotSnackKind.info,
  IconData? icon,
}) {
  final Color color;
  final IconData defaultIcon;
  switch (kind) {
    case SpotSnackKind.success:
      color = AppColors.kSuccess;
      defaultIcon = Icons.check_circle_outline_rounded;
      break;
    case SpotSnackKind.error:
      color = AppColors.kDanger;
      defaultIcon = Icons.error_outline_rounded;
      break;
    case SpotSnackKind.info:
      color = AppColors.kAccentBright;
      defaultIcon = Icons.info_outline_rounded;
      break;
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.kSurfaceElevated,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: kind == SpotSnackKind.info
                ? AppColors.kBorder
                : tint(color, 90),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            Icon(icon ?? defaultIcon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.kText, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
}

void showSpotSnack(
  BuildContext context,
  String message, {
  SpotSnackKind kind = SpotSnackKind.info,
  IconData? icon,
}) =>
    showSpotSnackOn(ScaffoldMessenger.of(context), message,
        kind: kind, icon: icon);

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet base
// ─────────────────────────────────────────────────────────────────────────────

Future<T?> showSpotSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    backgroundColor: AppColors.kCard,
    elevation: 0,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      side: BorderSide(color: AppColors.kBorder, width: 1),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  builder(ctx),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.kText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: const TextStyle(fontSize: 13, color: AppColors.kDim)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text input sheet (создание / переименование / редактирование)
// ─────────────────────────────────────────────────────────────────────────────

Future<String?> showTextInputSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? subtitle,
  String? hint,
  String initial = '',
}) {
  return showSpotSheet<String>(
    context,
    builder: (_) => _TextInputSheet(
      title: title,
      subtitle: subtitle,
      hint: hint,
      initial: initial,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextInputSheet extends StatefulWidget {
  const _TextInputSheet({
    required this.title,
    required this.confirmLabel,
    this.subtitle,
    this.hint,
    this.initial = '',
  });

  final String title;
  final String confirmLabel;
  final String? subtitle;
  final String? hint;
  final String initial;

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(widget.title, subtitle: widget.subtitle),
        const SizedBox(height: 16),
        SpotTextField(
          controller: _c,
          hint: widget.hint,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        SpotButton(
          label: widget.confirmLabel,
          kind: SpotButtonKind.primary,
          onPressed: _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showSpotSheet<bool>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(title, subtitle: message),
        const SizedBox(height: 20),
        SpotButton(
          label: confirmLabel,
          kind: destructive ? SpotButtonKind.danger : SpotButtonKind.primary,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
        const SizedBox(height: 8),
        SpotButton(
          label: tr('Отмена', 'Cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// NFC write sheet (симуляция записи метки)
// ─────────────────────────────────────────────────────────────────────────────

Future<String?> showNfcWriteSheet(
  BuildContext context, {
  required String address,
}) {
  return showSpotSheet<String>(
    context,
    builder: (_) => _NfcWriteSheet(address: address),
  );
}

class _NfcWriteSheet extends StatefulWidget {
  const _NfcWriteSheet({required this.address});
  final String address;

  @override
  State<_NfcWriteSheet> createState() => _NfcWriteSheetState();
}

class _NfcWriteSheetState extends State<_NfcWriteSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  Timer? _timer;
  bool _done = false;
  late final String _label;

  @override
  void initState() {
    super.initState();
    final h = widget.address.hashCode.abs().toRadixString(16).toUpperCase();
    final padded = h.padLeft(6, '0');
    _label = 'NTAG215 · ${padded.substring(padded.length - 6)}';
    _timer = Timer(const Duration(milliseconds: 2600), _finish);
  }

  void _finish() {
    if (!mounted) return;
    _pulse.stop();
    setState(() => _done = true);
    HapticFeedback.mediumImpact();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(_label);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          _done
              ? tr('Метка записана', 'Tag written')
              : tr('Запись на NFC-метку', 'Write to NFC tag'),
          subtitle: _done
              ? _label
              : tr('Поднесите метку к задней панели телефона',
                  'Hold the tag to the back of your phone'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_done)
                      for (var i = 0; i < 3; i++)
                        _ring((_pulse.value + i / 3) % 1.0),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.kSurfaceElevated,
                        border: Border.all(
                          color:
                              _done ? AppColors.kSuccess : AppColors.kBorder,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _done ? Icons.check_rounded : Icons.nfc_rounded,
                        size: 32,
                        color: _done
                            ? AppColors.kSuccess
                            : AppColors.kAccentBright,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Center(child: SpotAddressBadge(address: widget.address)),
        const SizedBox(height: 20),
        if (!_done)
          SpotButton(
            label: tr('Отмена', 'Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _ring(double t) {
    final size = 72 + 120 * t;
    final alpha = ((1 - t) * 160).round().clamp(0, 255);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.kAccent.withAlpha(alpha),
          width: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showShareSheet(
  BuildContext context, {
  required String code,
  required String title,
}) {
  Clipboard.setData(ClipboardData(text: code));
  return showSpotSheet<void>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(
          tr('Поделиться списком', 'Share list'),
          subtitle: tr(
              'Код скопирован в буфер обмена. Вставьте его через «Импорт по коду».',
              'Code copied to clipboard. Paste it via “Import by code”.'),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.kSurfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kBorder, width: 1),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: kMonoFont,
                fontSize: 12,
                height: 1.4,
                color: AppColors.kAccentBright,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SpotButton(
          label: tr('Скопировать ещё раз', 'Copy again'),
          icon: Icons.copy_rounded,
          kind: SpotButtonKind.primary,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            showSpotSnack(ctx, tr('Код скопирован', 'Code copied'),
                kind: SpotSnackKind.success);
          },
        ),
        const SizedBox(height: 8),
        SpotButton(
          label: tr('Закрыть', 'Close'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}

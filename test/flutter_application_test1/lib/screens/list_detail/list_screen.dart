import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_widgets.dart';

String _s(Object? v) => v == null ? '' : v.toString();

/// Алиас для обратной совместимости
typedef ListPage = ListScreen;

class ListScreen extends StatelessWidget {
  const ListScreen({super.key, required this.list});

  final ItemList list;

  Future<void> _rename(BuildContext context) async {
    final name = await showTextInputSheet(
      context,
      title: tr('Переименовать список', 'Rename list'),
      hint: tr('Название', 'Name'),
      initial: list.name,
      confirmLabel: tr('Сохранить', 'Save'),
    );
    if (name != null) appState.renameList(list.id, name);
  }

  Future<void> _addItem(BuildContext context) async {
    final text = await showTextInputSheet(
      context,
      title: tr('Новый пункт', 'New item'),
      hint: tr('Текст пункта', 'Item text'),
      confirmLabel: tr('Добавить', 'Add'),
    );
    if (text != null) appState.addItem(list.id, text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final items = list.items;
        return Scaffold(
          backgroundColor: AppColors.kBg,
          appBar: AppBar(
            backgroundColor: AppColors.kBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: const IconThemeData(color: AppColors.kAccentBright),
            title: Text(
              list.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.kText,
              ),
            ),
            actions: [
              IconButton(
                tooltip: tr('Переименовать', 'Rename'),
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.kAccentBright),
                onPressed: () => _rename(context),
              ),
              const SizedBox(width: 4),
            ],
            bottom: const SpotAppBarDivider(),
          ),
          floatingActionButton: SpotFab(
            icon: Icons.add_rounded,
            label: tr('Пункт', 'Item'),
            onPressed: () => _addItem(context),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _HeaderCard(list: list),
              if (list.category == SpotCategory.wifi) ...[
                const SizedBox(height: 12),
                _WifiCard(list: list),
              ],
              const SizedBox(height: 24),
              SectionLabel('${tr('Пункты', 'Items')} · ${items.length}'),
              const SizedBox(height: 10),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.playlist_add_rounded,
                  title: tr('Список пуст', 'List is empty'),
                  subtitle: tr('Нажмите «Пункт», чтобы добавить первый',
                      'Tap “Item” to add the first one'),
                )
              else
                for (final item in items)
                  _ItemTile(
                    key: ValueKey('item_${item.id}'),
                    list: list,
                    item: item,
                  ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card: address, NFC, share
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.list});
  final ItemList list;

  Future<void> _copyAddress(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: list.spotAddress));
    if (!context.mounted) return;
    showSpotSnack(context, tr('Адрес скопирован', 'Address copied'),
        kind: SpotSnackKind.success);
  }

  Future<void> _toggleNfc(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    if (list.isNfcLinked) {
      final ok = await showConfirmSheet(
        context,
        title: tr('Отвязать NFC-метку?', 'Unlink NFC tag?'),
        message: tr(
            'Список останется в приложении, но метка перестанет на него указывать.',
            'The list stays in the app, but the tag will no longer point to it.'),
        confirmLabel: tr('Отвязать', 'Unlink'),
        destructive: true,
      );
      if (!ok) return;
      appState.unbindNfcTag(list.id);
      showSpotSnackOn(messenger, tr('NFC-метка отвязана', 'NFC tag unlinked'));
      return;
    }

    final label = await showNfcWriteSheet(context, address: list.spotAddress);
    if (label == null) return;
    appState.bindNfcTag(list.id, label);
    showSpotSnackOn(
      messenger,
      tr('Метка записана: $label', 'Tag written: $label'),
      kind: SpotSnackKind.success,
      icon: Icons.nfc_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTodo = list.category == SpotCategory.todo;
    final tag = _s(list.nfcTagLabel);

    return SpotCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(categoryIcon(list.category),
                  size: 18, color: AppColors.kAccentBright),
              const SizedBox(width: 8),
              Text(
                categoryLabel(list.category),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kAccentBright,
                ),
              ),
              const Spacer(),
              if (list.isNfcLinked) const NfcStatusBadge(),
            ],
          ),
          const SizedBox(height: 14),
          SectionLabel(tr('Локальный адрес NFC', 'Local Spot Address')),
          const SizedBox(height: 8),
          _AddressRow(
            address: list.spotAddress,
            onTap: () => _copyAddress(context),
          ),
          if (list.isNfcLinked && tag.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${tr('Метка', 'Tag')}: $tag',
              style: const TextStyle(
                fontFamily: kMonoFont,
                fontSize: 12,
                color: AppColors.kDim,
              ),
            ),
          ],
          if (isTodo) ...[
            const SizedBox(height: 14),
            _TodoProgress(list: list),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SpotButton(
                  label: list.isNfcLinked
                      ? tr('Отвязать NFC', 'Unlink NFC')
                      : tr('Записать на NFC', 'Write to NFC'),
                  icon: list.isNfcLinked
                      ? Icons.link_off_rounded
                      : Icons.nfc_rounded,
                  kind: list.isNfcLinked
                      ? SpotButtonKind.danger
                      : SpotButtonKind.primary,
                  onPressed: () => _toggleNfc(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SpotButton(
                  label: tr('Поделиться', 'Share'),
                  icon: Icons.ios_share_rounded,
                  onPressed: () => showShareSheet(
                    context,
                    code: list.exportShareCode(),
                    title: list.name,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.onTap});
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kMonoFont,
                      fontSize: 14,
                      color: AppColors.kAccentBright,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.kDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoProgress extends StatelessWidget {
  const _TodoProgress({required this.list});
  final ItemList list;

  @override
  Widget build(BuildContext context) {
    final total = list.items.length;
    final done = list.items.where((i) => i.done).length;
    final p = list.progress.toDouble().clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: p,
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: AppColors.kBorder,
            color: p >= 1 ? AppColors.kSuccess : AppColors.kAccentBright,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$done/$total',
          style: const TextStyle(
            fontFamily: kMonoFont,
            fontSize: 12,
            color: AppColors.kDim,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wi-Fi card (с возможностью редактирования SSID и пароля)
// ─────────────────────────────────────────────────────────────────────────────

class _WifiCard extends StatefulWidget {
  const _WifiCard({required this.list});
  final ItemList list;

  @override
  State<_WifiCard> createState() => _WifiCardState();
}

class _WifiCardState extends State<_WifiCard> {
  bool _visible = false;

  Future<void> _copyPassword(String pw) async {
    await Clipboard.setData(ClipboardData(text: pw));
    if (!mounted) return;
    showSpotSnack(context, tr('Пароль скопирован', 'Password copied'),
        kind: SpotSnackKind.success);
  }

  Future<void> _editWifi() async {
    final ssidCtrl = TextEditingController(text: _s(widget.list.wifiSsid));
    final passCtrl = TextEditingController(text: _s(widget.list.wifiPassword));

    final saved = await showSpotSheet<bool>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(tr('Настройки Wi-Fi метки', 'Wi-Fi Spot Settings')),
          const SizedBox(height: 16),
          SpotTextField(
            controller: ssidCtrl,
            hint: tr('Имя сети (SSID)', 'Network Name (SSID)'),
            prefixIcon: Icons.wifi_rounded,
            mono: true,
            autofocus: true,
          ),
          const SizedBox(height: 10),
          SpotTextField(
            controller: passCtrl,
            hint: tr('Пароль от Wi-Fi', 'Wi-Fi Password'),
            prefixIcon: Icons.lock_outline_rounded,
            mono: true,
          ),
          const SizedBox(height: 16),
          SpotButton(
            label: tr('Сохранить', 'Save'),
            kind: SpotButtonKind.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      appState.updateWifiCredentials(
        widget.list.id,
        ssid: ssidCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ssid = _s(widget.list.wifiSsid);
    final pw = _s(widget.list.wifiPassword);
    final hasPw = pw.isNotEmpty;
    final masked = '•' * (pw.length < 8 ? 8 : pw.length);

    return SpotCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded,
                  size: 18, color: AppColors.kAccentBright),
              const SizedBox(width: 8),
              const Text(
                'Wi-Fi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kText,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: tr('Изменить сеть', 'Edit Wi-Fi'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.kDim),
                onPressed: _editWifi,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WifiField(
            label: 'SSID',
            value: ssid.isEmpty ? '—' : ssid,
          ),
          const SizedBox(height: 10),
          _WifiField(
            label: tr('Пароль', 'Password'),
            value: !hasPw
                ? tr('Открытая сеть', 'Open network')
                : (_visible ? pw : masked),
            trailing: hasPw
                ? [
                    IconButton(
                      tooltip: _visible
                          ? tr('Скрыть', 'Hide')
                          : tr('Показать', 'Show'),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        _visible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.kDim,
                      ),
                      onPressed: () => setState(() => _visible = !_visible),
                    ),
                    IconButton(
                      tooltip: tr('Копировать пароль', 'Copy password'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: AppColors.kAccentBright),
                      onPressed: () => _copyPassword(pw),
                    ),
                  ]
                : null,
          ),
        ],
      ),
    );
  }
}

class _WifiField extends StatelessWidget {
  const _WifiField({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.kSurfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kBorder, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.kDim)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: kMonoFont,
                fontSize: 14,
                color: AppColors.kText,
              ),
            ),
          ),
          ...?trailing,
          if (trailing == null) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item tile
// ─────────────────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  const _ItemTile({super.key, required this.list, required this.item});

  final ItemList list;
  final Item item;

  Future<void> _edit(BuildContext context) async {
    final text = await showTextInputSheet(
      context,
      title: tr('Редактировать пункт', 'Edit item'),
      hint: tr('Текст пункта', 'Item text'),
      initial: item.text,
      confirmLabel: tr('Сохранить', 'Save'),
    );
    if (text != null) appState.editItem(list.id, item.id, text);
  }

  @override
  Widget build(BuildContext context) {
    final done = item.isTodo && item.done;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.kDanger,
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.kBg, size: 22),
        ),
        onDismissed: (_) {
          appState.deleteItem(list.id, item.id);
          showSpotSnack(context, tr('Пункт удалён', 'Item deleted'));
        },
        child: SpotCard(
          padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
          onTap:
              item.isTodo ? () => appState.toggleItem(list.id, item.id) : null,
          onLongPress: () => _edit(context),
          child: Row(
            children: [
              item.isTodo
                  ? _CheckMark(done: item.done)
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.circle, size: 6, color: AppColors.kDim),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: done ? AppColors.kDim : AppColors.kText,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.kDim,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: tr('Редактировать', 'Edit'),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.kDim),
                onPressed: () => _edit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.kAccentBright : Colors.transparent,
        border: Border.all(
          color: done ? AppColors.kAccentBright : AppColors.kDim,
          width: 1.5,
        ),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.kBg)
          : null,
    );
  }
}

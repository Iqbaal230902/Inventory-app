import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'format.dart';
import 'providers.dart';
import 'theme.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? cs.error : null,
      behavior: SnackBarBehavior.floating,
    ));
}

String errorText(Object e) => ApiException.from(e).message;

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String ok = 'Ya', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r == true;
}

/// Dialog input teks wajib (alasan void / koreksi).
Future<String?> promptText(BuildContext context,
    {required String title, required String label, String ok = 'Simpan'}) async {
  final ctrl = TextEditingController();
  final key = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          maxLength: 255,
          decoration: InputDecoration(labelText: label),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) Navigator.pop(c, ctrl.text.trim());
          },
          child: Text(ok),
        ),
      ],
    ),
  );
}

class StatusDot extends StatelessWidget {
  const StatusDot(this.status, {super.key, this.size = 12});
  final String status;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: statusColor(status), shape: BoxShape.circle),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color, this.icon});
  final String text;
  final Color? color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: c), const SizedBox(width: 4)],
        Flexible(child: Text(text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

/// Badge jumlah transaksi belum tersinkron — selalu terlihat di app bar (FR-11).
class SyncBadgeButton extends ConsumerWidget {
  const SyncBadgeButton({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingCountProvider).value ?? 0;
    final running = ref.watch(syncRunningProvider).value ?? false;
    final online = ref.watch(onlineProvider).value ?? true;
    final icon = running
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
        : Icon(online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined);
    return IconButton(
      tooltip: pending > 0 ? '$pending transaksi belum tersinkron' : 'Status sinkronisasi',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: pending > 0,
        backgroundColor: AppColors.warning,
        label: Text('$pending'),
        child: icon,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ?trailing,
        ]),
      );
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String? value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value ?? '-', style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: ApiException.from(error).isNetwork ? Icons.wifi_off : Icons.error_outline,
        message: errorText(error),
        action: onRetry == null ? null : OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
      );
}

/// Banner "Data per [waktu sinkron terakhir]" saat offline (FR-02).
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    final last = ref.watch(lastPullAtProvider).value;
    return MaterialBanner(
      backgroundColor: AppColors.warning.withValues(alpha: 0.15),
      leading: const Icon(Icons.cloud_off, color: AppColors.warning),
      content: Text('Mode offline. Data per ${last == null ? '-' : fmtDateTime(last)} '
          '+ transaksi lokal yang belum tersinkron.'),
      actions: const [SizedBox.shrink()],
    );
  }
}

/// Nama perusahaan pemilik aplikasi (ditampilkan di login & layar kunci).
const companyName = 'PT Berkah Azzura Mandiri';

/// Logo perusahaan dalam lingkaran putih.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 128});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Image.asset('assets/branding/logo.png', fit: BoxFit.cover),
      );
}

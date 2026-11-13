import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../main.dart';
import '../auth/auth_controller.dart';

final _versionProvider = FutureProvider((ref) async => (await PackageInfo.fromPlatform()).version);
final _baseUrlProvider = FutureProvider((ref) => ref.watch(sessionStoreProvider).baseUrl());

/// Menu "Lainnya": profil, master data, user, pengaturan, logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(context, title: 'Keluar?', message: 'Anda harus login lagi untuk memakai aplikasi.', ok: 'Keluar');
    if (!ok) return;
    try {
      await ref.read(authProvider.notifier).logout();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'PENDING_DATA') {
        final user = ref.read(currentUserProvider);
        final force = user?.isOwner == true &&
            await confirmDialog(context,
                title: 'Data belum tersinkron',
                message: '${e.message}\n\nSebagai Owner, Anda dapat memaksa logout. Data tetap tersimpan di HP '
                    'dan akan dikirim saat user yang sama login kembali.',
                ok: 'Paksa logout',
                danger: true);
        if (force) {
          await ref.read(authProvider.notifier).logout(force: true);
        } else if (context.mounted) {
          showSnack(context, e.message, error: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final mode = ref.watch(themeModeProvider);
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(children: [
        ListTile(
          leading: CircleAvatar(child: Text(user.name.characters.first.toUpperCase())),
          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${roleLabels[user.role]} · @${user.username}\n'
              '${user.allLocations ? 'Semua lokasi' : user.locations.map((l) => l.name).join(', ')}'),
          isThreeLine: true,
        ),
        const Divider(),
        if (user.isManager) ...[
          ListTile(leading: const Icon(Icons.category_outlined), title: const Text('Master Data'),
              subtitle: const Text('Produk, lokasi, kemasan, pelanggan, kendaraan, stok minimum'),
              onTap: () => context.push('/master')),
          ListTile(leading: const Icon(Icons.business_outlined), title: const Text('Profil Perusahaan & Aturan'),
              subtitle: const Text('Kop surat jalan, toleransi, batas tonase'),
              onTap: () => context.push('/settings/company')),
        ],
        if (user.isOwner)
          ListTile(leading: const Icon(Icons.manage_accounts_outlined), title: const Text('Manajemen User'),
              onTap: () => context.push('/users')),
        if (user.isManager)
          ListTile(leading: const Icon(Icons.fact_check_outlined), title: const Text('Transaksi perlu ditinjau'),
              onTap: () => context.go('/history?status=pending_approval')),
        if (user.canInput)
          ListTile(leading: const Icon(Icons.print_outlined), title: const Text('Printer Bluetooth'),
              onTap: () => context.push('/settings/printer')),
        ListTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: const Text('Tema'),
          trailing: DropdownButton<ThemeMode>(
            value: mode,
            underline: const SizedBox.shrink(),
            onChanged: (m) => ref.read(themeModeProvider.notifier).set(m!),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('Ikuti sistem')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Terang')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Gelap')),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: const Text('Server'),
          subtitle: Text(ref.watch(_baseUrlProvider).value ?? '-'),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Versi aplikasi'),
          subtitle: Text(ref.watch(_versionProvider).value ?? '-'),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
          title: Text('Keluar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: () => _logout(context, ref),
        ),
      ]),
    );
  }
}

/// Pengaturan perusahaan (FR-12): nama, alamat, logo kop SJ, toleransi, batas tonase.
class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});
  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};
  String _logo = '';
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  static const _fields = [
    ('company_name', 'Nama perusahaan', false),
    ('company_address', 'Alamat', false),
    ('company_phone', 'Telepon', false),
    ('max_net_ton_per_trx', 'Batas wajar tonase per truk (Ton)', true),
    ('duplicate_plate_window_min', 'Jendela cek input ganda No. Polisi (menit)', true),
    ('lock_after_days', 'Kunci transaksi setelah (hari)', true),
    ('shrink_tolerance_pct', 'Toleransi susut opname (%)', true),
    ('production_loss_threshold_pct', 'Ambang loss produksi (%)', true),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _c[f.$1] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ref.read(apiProvider).get<Map<String, dynamic>>('/settings');
      for (final f in _fields) {
        _c[f.$1]!.text = '${s[f.$1] ?? ''}';
      }
      _logo = '${s['company_logo_base64'] ?? ''}';
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final bytes = await FlutterImageCompress.compressWithFile(x.path, minWidth: 256, minHeight: 256, quality: 80, format: CompressFormat.png);
    if (bytes != null) setState(() => _logo = base64Encode(bytes));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).put('/settings', {
        for (final f in _fields) f.$1: _c[f.$1]!.text.trim().replaceAll(',', '.'),
        'company_logo_base64': _logo,
      });
      await ref.read(syncEngineProvider).pull();
      if (mounted) {
        showSnack(context, 'Pengaturan disimpan.');
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profil Perusahaan')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorView(_error!, onRetry: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  })
                : Form(
                    key: _form,
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      Card(
                        child: ListTile(
                          leading: _logo.isEmpty
                              ? const Icon(Icons.image_outlined, size: 40)
                              : Image.memory(base64Decode(_logo), width: 48, height: 48),
                          title: const Text('Logo kop surat jalan'),
                          subtitle: const Text('Ketuk untuk memilih gambar'),
                          trailing: _logo.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _logo = '')),
                          onTap: _pickLogo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final f in _fields) ...[
                        TextFormField(
                          controller: _c[f.$1],
                          keyboardType: f.$3 ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                          decoration: InputDecoration(labelText: f.$2),
                          validator: (v) => f.$1 == 'company_name' && (v ?? '').trim().isEmpty
                              ? 'Wajib diisi'
                              : (f.$3 && parseTon(v) == null ? 'Harus angka' : null),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ]),
                  ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(onPressed: _saving || _loading ? null : _save, child: const Text('Simpan')),
          ),
        ),
      );
}

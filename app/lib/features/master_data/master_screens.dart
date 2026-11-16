import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/local/database.dart';
import '../dashboard/dashboard_provider.dart';

enum FieldType { text, ton, integer, select, plate }

class FieldSpec {
  const FieldSpec(this.key, this.label, {this.type = FieldType.text, this.required = false, this.options = const {}});
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final Map<String, String> options;
}

class EntitySpec {
  const EntitySpec({
    required this.title,
    required this.path,
    required this.icon,
    required this.fields,
    required this.titleOf,
    required this.subtitleOf,
    this.deleteOwnerOnly = false,
    this.ownerOnly = false,
  });
  final String title;
  final String path;
  final IconData icon;
  final List<FieldSpec> fields;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;
  final bool deleteOwnerOnly;

  /// Hanya Owner (super admin) yang boleh melihat & mengelola entitas ini.
  final bool ownerOnly;
}

const _tz = {'Asia/Jakarta': 'WIB', 'Asia/Makassar': 'WITA', 'Asia/Jayapura': 'WIT'};

/// Spesifikasi master data (FR-12) — ditambah tanpa mengubah layar.
final entitySpecs = <String, EntitySpec>{
  'products': EntitySpec(
    title: 'Produk / Mesh',
    path: '/products',
    icon: Icons.grain,
    fields: const [
      FieldSpec('code', 'Kode (mis. M1420)', required: true),
      FieldSpec('name', 'Nama (mis. Mesh 14/20)', required: true),
      FieldSpec('mesh_size', 'Ukuran mesh (mis. 14/20)'),
      FieldSpec('category', 'Kategori', type: FieldType.select, required: true,
          options: {'raw': 'Bahan baku', 'finished': 'Produk jadi', 'byproduct': 'Produk samping'}),
      FieldSpec('density_ton_m3', 'Densitas (Ton/m³)', type: FieldType.ton),
      FieldSpec('sort_order', 'Urutan tampil', type: FieldType.integer),
    ],
    titleOf: (m) => '${m['name']}',
    subtitleOf: (m) => '${m['code']} · ${m['category']}${m['mesh_size'] != null ? ' · ${m['mesh_size']}' : ''}',
  ),
  'locations': EntitySpec(
    title: 'Gudang / Lokasi',
    path: '/locations',
    icon: Icons.warehouse_outlined,
    deleteOwnerOnly: true,
    ownerOnly: true,
    fields: const [
      FieldSpec('code', 'Kode (mis. GDA)', required: true),
      FieldSpec('name', 'Nama', required: true),
      FieldSpec('type', 'Tipe', type: FieldType.select, required: true,
          options: {'gudang': 'Gudang', 'tambang': 'Tambang', 'pabrik': 'Pabrik Pengolahan', 'stockpile': 'Stockpile'}),
      FieldSpec('address', 'Alamat'),
      FieldSpec('timezone', 'Zona waktu', type: FieldType.select, options: _tz),
    ],
    titleOf: (m) => '${m['name']}',
    subtitleOf: (m) => '${m['code']} · ${m['type']} · ${_tz[m['timezone']] ?? ''}',
  ),
  'packaging-units': EntitySpec(
    title: 'Kemasan',
    path: '/packaging-units',
    icon: Icons.shopping_bag_outlined,
    fields: const [
      FieldSpec('name', 'Nama (mis. Karung 50 kg)', required: true),
      FieldSpec('ton_per_unit', 'Ton per kemasan (mis. 0,050)', type: FieldType.ton, required: true),
      FieldSpec('is_bulk', 'Curah?', type: FieldType.select, options: {'false': 'Tidak', 'true': 'Ya (curah)'}),
    ],
    titleOf: (m) => '${m['name']}',
    subtitleOf: (m) => '${fmtTonStr('${m['ton_per_unit']}')} Ton/kemasan',
  ),
  'partners': EntitySpec(
    title: 'Pelanggan & Supplier',
    path: '/partners',
    icon: Icons.storefront_outlined,
    fields: const [
      FieldSpec('type', 'Jenis', type: FieldType.select, required: true,
          options: {'customer': 'Pelanggan', 'supplier': 'Supplier', 'both': 'Keduanya'}),
      FieldSpec('name', 'Nama', required: true),
      FieldSpec('phone', 'Telepon'),
      FieldSpec('address', 'Alamat'),
    ],
    titleOf: (m) => '${m['name']}',
    subtitleOf: (m) => [m['type'], m['phone'], m['address']].where((e) => e != null && '$e'.isNotEmpty).join(' · '),
  ),
  'vehicles': EntitySpec(
    title: 'Kendaraan',
    path: '/vehicles',
    icon: Icons.local_shipping_outlined,
    fields: const [
      FieldSpec('plate_number', 'No. Polisi', type: FieldType.plate, required: true),
      FieldSpec('default_driver', 'Sopir default'),
      FieldSpec('standard_tare_ton', 'Tara standar (Ton)', type: FieldType.ton),
    ],
    titleOf: (m) => formatPlate('${m['plate_number']}'),
    subtitleOf: (m) => [m['default_driver'], if (m['standard_tare_ton'] != null) 'Tara ${fmtTonStr('${m['standard_tare_ton']}')} T']
        .whereType<String>()
        .join(' · '),
  ),
};

class MasterMenuScreen extends ConsumerWidget {
  const MasterMenuScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(currentUserProvider)?.isOwner ?? false;
    return Scaffold(
        appBar: AppBar(title: const Text('Master Data')),
        body: ListView(children: [
          for (final e in entitySpecs.entries.where((e) => !e.value.ownerOnly || isOwner))
            ListTile(
              leading: Icon(e.value.icon),
              title: Text(e.value.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/master/${e.key}'),
            ),
          ListTile(
            leading: const Icon(Icons.low_priority),
            title: const Text('Stok Minimum'),
            subtitle: const Text('Batas minimum per produk per lokasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/master/min-levels'),
          ),
        ]),
      );
  }
}

final _masterListProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, path) async {
  final r = await ref.watch(apiProvider).get<List<dynamic>>(path, query: {'all': '1'});
  return r.map((e) => (e as Map).cast<String, dynamic>()).toList();
});

class MasterListScreen extends ConsumerWidget {
  const MasterListScreen({super.key, required this.entity});
  final String entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entity == 'min-levels') return const MinLevelsScreen();
    final spec = entitySpecs[entity];
    if (spec == null) return const Scaffold(body: Center(child: Text('Tidak ditemukan')));
    final async = ref.watch(_masterListProvider(spec.path));
    final user = ref.watch(currentUserProvider);
    if (spec.ownerOnly && !(user?.isOwner ?? false)) {
      return const Scaffold(body: Center(child: Text('Hanya Owner yang dapat mengelola data ini.')));
    }

    Future<void> openForm([Map<String, dynamic>? item]) async {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _MasterForm(spec: spec, item: item),
      );
      if (saved == true) {
        ref.invalidate(_masterListProvider(spec.path));
        ref.read(syncEngineProvider).pull().ignore();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(spec.title)),
      floatingActionButton: FloatingActionButton(onPressed: () => openForm(), child: const Icon(Icons.add)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(_masterListProvider(spec.path))),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_masterListProvider(spec.path)),
          child: items.isEmpty
              ? ListView(children: const [EmptyState(icon: Icons.inbox_outlined, message: 'Belum ada data.')])
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = items[i];
                    final active = m['is_active'] != false;
                    return ListTile(
                      enabled: true,
                      title: Text(spec.titleOf(m),
                          style: TextStyle(decoration: active ? null : TextDecoration.lineThrough)),
                      subtitle: Text(spec.subtitleOf(m) + (active ? '' : ' · nonaktif')),
                      onTap: () => openForm(m),
                      trailing: active && (!spec.deleteOwnerOnly || (user?.isOwner ?? false))
                          ? IconButton(
                              tooltip: 'Nonaktifkan',
                              icon: const Icon(Icons.archive_outlined),
                              onPressed: () async {
                                final ok = await confirmDialog(context,
                                    title: 'Nonaktifkan?',
                                    message: '${spec.titleOf(m)} tidak akan muncul di pilihan. Riwayat tetap tersimpan.',
                                    ok: 'Nonaktifkan',
                                    danger: true);
                                if (!ok) return;
                                try {
                                  await ref.read(apiProvider).delete('${spec.path}/${m['id']}');
                                  ref.invalidate(_masterListProvider(spec.path));
                                  ref.read(syncEngineProvider).pull().ignore();
                                } catch (e) {
                                  if (context.mounted) showSnack(context, errorText(e), error: true);
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _MasterForm extends ConsumerStatefulWidget {
  const _MasterForm({required this.spec, this.item});
  final EntitySpec spec;
  final Map<String, dynamic>? item;
  @override
  ConsumerState<_MasterForm> createState() => _MasterFormState();
}

class _MasterFormState extends ConsumerState<_MasterForm> {
  final _form = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};
  final _sel = <String, String?>{};
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.item ?? {};
    _active = m['is_active'] != false;
    for (final f in widget.spec.fields) {
      final v = m[f.key];
      if (f.type == FieldType.select) {
        _sel[f.key] = v?.toString() ?? (f.options.isNotEmpty && f.required ? f.options.keys.first : null);
      } else {
        var text = v?.toString() ?? '';
        if (f.type == FieldType.ton && text.isNotEmpty) text = text.replaceAll('.', ',');
        if (f.type == FieldType.plate) text = formatPlate(text);
        _c[f.key] = TextEditingController(text: text);
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final body = <String, dynamic>{'is_active': _active};
    for (final f in widget.spec.fields) {
      switch (f.type) {
        case FieldType.select:
          final v = _sel[f.key];
          body[f.key] = v == 'true' ? true : (v == 'false' ? false : v);
        case FieldType.ton:
          final d = parseTon(_c[f.key]!.text);
          body[f.key] = d == null ? null : tonApi(d);
        case FieldType.integer:
          body[f.key] = int.tryParse(_c[f.key]!.text);
        default:
          final t = _c[f.key]!.text.trim();
          body[f.key] = t.isEmpty ? null : t;
      }
    }
    body.removeWhere((k, v) => v == null);
    setState(() => _saving = true);
    try {
      final api = ref.read(apiProvider);
      if (widget.item == null) {
        await api.post(widget.spec.path, body);
      } else {
        await api.put('${widget.spec.path}/${widget.item!['id']}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${widget.item == null ? 'Tambah' : 'Ubah'} ${widget.spec.title}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final f in widget.spec.fields) ...[
                if (f.type == FieldType.select)
                  DropdownButtonFormField<String>(
                    initialValue: _sel[f.key],
                    decoration: InputDecoration(labelText: f.label),
                    items: f.options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setState(() => _sel[f.key] = v),
                    validator: (v) => f.required && v == null ? 'Wajib dipilih' : null,
                  )
                else
                  TextFormField(
                    controller: _c[f.key],
                    decoration: InputDecoration(labelText: f.label),
                    textCapitalization: f.type == FieldType.plate ? TextCapitalization.characters : TextCapitalization.sentences,
                    keyboardType: switch (f.type) {
                      FieldType.ton => const TextInputType.numberWithOptions(decimal: true),
                      FieldType.integer => TextInputType.number,
                      _ => TextInputType.text,
                    },
                    inputFormatters: switch (f.type) {
                      FieldType.ton => [TonInputFormatter()],
                      FieldType.integer => [FilteringTextInputFormatter.digitsOnly],
                      FieldType.plate => [PlateInputFormatter()],
                      _ => null,
                    },
                    validator: (v) {
                      if (f.required && (v ?? '').trim().isEmpty) return 'Wajib diisi';
                      if (f.type == FieldType.ton && (v ?? '').isNotEmpty && parseTon(v) == null) return 'Angka tidak valid';
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktif'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _saving ? null : _save, child: const Text('Simpan')),
            ]),
          ),
        ),
      );
}

final _minLevelsProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchMinLevels());

/// Batas stok minimum per produk per lokasi (FR-09).
class MinLevelsScreen extends ConsumerStatefulWidget {
  const MinLevelsScreen({super.key});
  @override
  ConsumerState<MinLevelsScreen> createState() => _MinLevelsScreenState();
}

class _MinLevelsScreenState extends ConsumerState<MinLevelsScreen> {
  int? _loc;

  @override
  Widget build(BuildContext context) {
    final locs = ref.watch(locationsProvider).value ?? const <Location>[];
    _loc ??= locs.firstOrNull?.id;
    final data = ref.watch(dashboardProvider).value;
    final mins = ref.watch(_minLevelsProvider).value ?? const <MinLevel>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Minimum')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<int>(
          initialValue: _loc,
          decoration: const InputDecoration(labelText: 'Lokasi'),
          items: locs.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
          onChanged: (v) => setState(() => _loc = v),
        ),
        const SizedBox(height: 12),
        ...?data?.rows.map((r) {
          final m = mins.where((x) => x.locationId == _loc && x.productId == r.product.id).firstOrNull;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(r.product.name),
              subtitle: Text('Minimum: ${m == null ? 'belum diatur' : '${fmtTonStr(m.minTon)} Ton'}'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final ctrl = TextEditingController(text: m == null ? '' : fmtTonStr(m.minTon).replaceAll('.', ''));
                final v = await showDialog<String>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text('Minimum ${r.product.name}'),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [TonInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Stok minimum (Ton)'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                      FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Simpan')),
                    ],
                  ),
                );
                final d = parseTon(v);
                if (d == null || _loc == null) return;
                try {
                  await ref.read(apiProvider).put('/min-levels', {'location_id': _loc, 'product_id': r.product.id, 'min_ton': tonApi(d)});
                  await ref.read(syncEngineProvider).pull();
                } catch (e) {
                  if (context.mounted) showSnack(context, errorText(e), error: true);
                }
              },
            ),
          );
        }),
      ]),
    );
  }
}

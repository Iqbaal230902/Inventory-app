import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/local/database.dart';
import '../../data/models.dart';

final _unsyncedProvider = StreamProvider((ref) => ref.watch(trxRepoProvider).watchUnsynced());
final _recentLocalProvider = StreamProvider((ref) => ref.watch(trxRepoProvider).watchRecent());
final _productsProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchProducts());

/// Layar 7 — Riwayat transaksi: infinite scroll, filter chip, pencarian (FR-04).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, this.initialQuery = const {}});
  final Map<String, String> initialQuery;
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final List<TrxView> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  String? _type; // in | out | ADJUSTMENT | VOID
  String? _status;
  bool _voidRequested = false;
  int? _productId;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _status = widget.initialQuery['status'];
    _voidRequested = widget.initialQuery['void_requested'] == '1';
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void didUpdateWidget(covariant HistoryScreen old) {
    super.didUpdateWidget(old);
    if (old.initialQuery != widget.initialQuery) {
      _status = widget.initialQuery['status'];
      _voidRequested = widget.initialQuery['void_requested'] == '1';
      _reload();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _query => {
        'page': '$_page',
        'per_page': '20',
        'q': _search.text.trim(),
        'type': switch (_type) {
          'in' => 'IN_PRODUCTION,IN_SUPPLIER',
          'out' => 'OUT_SALE',
          final t => t,
        },
        'status': _status,
        'void_requested': _voidRequested ? '1' : null,
        'product_id': _productId?.toString(),
        'location_id': ref.read(selectedLocationProvider)?.toString(),
        'date_from': _range?.start.toUtc().toIso8601String(),
        'date_to': _range?.end.add(const Duration(days: 1)).toUtc().toIso8601String(),
      };

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
    });
    await _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final r = await ref.read(apiProvider).get<Map<String, dynamic>>('/transactions', query: _query);
      final data = (r['data'] as List).map((e) => TrxView((e as Map).cast<String, dynamic>())).toList();
      setState(() {
        _items.addAll(data);
        _hasMore = r['has_more'] == true;
        _page++;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _hasMore = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _offline => _error != null && ApiException.from(_error!).isNetwork;

  bool _matchLocal(TrxView t) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty &&
        !t.docNo.toLowerCase().contains(q) &&
        !(t.plateNumber ?? '').toLowerCase().contains(normalizePlate(q).toLowerCase()) &&
        !(t.partnerName ?? '').toLowerCase().contains(q)) {
      return false;
    }
    if (_type == 'in' && t.trxType != 'IN_PRODUCTION' && t.trxType != 'IN_SUPPLIER') return false;
    if (_type == 'out' && t.trxType != 'OUT_SALE') return false;
    if (_type != null && _type != 'in' && _type != 'out' && t.trxType != _type) return false;
    if (_productId != null && !t.items.any((i) => i.productId == _productId)) return false;
    if (_range != null &&
        (t.trxAt.isBefore(_range!.start) || t.trxAt.isAfter(_range!.end.add(const Duration(days: 1))))) {
      return false;
    }
    return true;
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    setState(() => _range = r);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(trxRepoProvider);
    final unsynced = (ref.watch(_unsyncedProvider).value ?? const <LocalTransaction>[]).map(repo.view).where(_matchLocal).toList();
    final products = ref.watch(_productsProvider).value ?? const <Product>[];
    final user = ref.watch(currentUserProvider);
    final offlineList = _offline
        ? (ref.watch(_recentLocalProvider).value ?? const <LocalTransaction>[])
            .where((r) => r.syncState == SyncState.synced)
            .map(repo.view)
            .where(_matchLocal)
            .toList()
        : const <TrxView>[];

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [SyncBadgeButton(onTap: () => context.go('/sync'))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: 'Cari No. SJ / No. Polisi / pelanggan',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            _reload();
                          }),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  chip(_range == null ? 'Tanggal' : '${fmtDate(_range!.start)} – ${fmtDate(_range!.end)}', _range != null, () {
                    if (_range != null) {
                      setState(() => _range = null);
                      _reload();
                    } else {
                      _pickRange();
                    }
                  }),
                  for (final (k, l) in [
                    ('out', 'Keluar'),
                    ('in', 'Masuk'),
                    ('IN_RAW', 'Bahan baku'),
                    ('ADJUSTMENT', 'Penyesuaian'),
                    ('VOID', 'Void'),
                  ])
                    chip(l, _type == k, () {
                      setState(() => _type = _type == k ? null : k);
                      _reload();
                    }),
                  PopupMenuButton<int?>(
                    tooltip: 'Produk',
                    onSelected: (v) {
                      setState(() => _productId = v == -1 ? null : v);
                      _reload();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: -1, child: Text('Semua produk')),
                      ...products.map((p) => PopupMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(products.where((p) => p.id == _productId).firstOrNull?.name ?? 'Produk'),
                        avatar: const Icon(Icons.arrow_drop_down, size: 18),
                      ),
                    ),
                  ),
                  if (user?.isManager ?? false) ...[
                    chip('Perlu ditinjau', _status == 'pending_approval', () {
                      setState(() => _status = _status == 'pending_approval' ? null : 'pending_approval');
                      _reload();
                    }),
                    chip('Pengajuan void', _voidRequested, () {
                      setState(() => _voidRequested = !_voidRequested);
                      _reload();
                    }),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            if (unsynced.isNotEmpty) ...[
              SectionTitle('Belum tersinkron (${unsynced.length})'),
              ...unsynced.map((t) => TrxTile(t)),
              const Divider(height: 24),
            ],
            if (_offline) ...[
              const Padding(
                padding: EdgeInsets.all(8),
                child: Pill('Offline — menampilkan transaksi dari perangkat ini', icon: Icons.cloud_off, color: AppColors.warning),
              ),
              ...offlineList.map((t) => TrxTile(t)),
            ] else ...[
              ..._items.map((t) => TrxTile(t)),
              if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              if (_error != null) ErrorView(_error!, onRetry: _reload),
              if (!_loading && _error == null && _items.isEmpty && unsynced.isEmpty)
                const EmptyState(icon: Icons.receipt_long_outlined, message: 'Belum ada transaksi.'),
            ],
          ],
        ),
      ),
    );
  }
}

class TrxTile extends StatelessWidget {
  const TrxTile(this.t, {super.key});
  final TrxView t;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (t.direction) {
      'out' => (Icons.north_east_rounded, AppColors.danger),
      'in' => (Icons.south_west_rounded, AppColors.tertiary),
      _ => (Icons.swap_vert_rounded, AppColors.secondary),
    };
    final product = t.items.map((i) => i.productName).toSet().join(', ');
    // Bahan baku mentah dicatat per rit; pasir mesh dalam ton.
    final amount = t.totalRit != Decimal.zero && t.totalTon == Decimal.zero
        ? '${fmtQtyNum(t.totalRit, 'rit')} Rit'
        : '${fmtTon(t.totalTon)} T';
    final key = t.local != null ? t.clientUuid : 's${t.id}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => context.push('/trx/$key'),
        leading: IconCircle(icon, color: color, size: 42, filled: false),
        title: Row(children: [
          Expanded(child: Text(t.docNo, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          Text('${t.direction == 'out' ? '−' : t.direction == 'in' ? '+' : '±'}$amount',
              style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$product · ${t.typeLabel}'),
          Text([fmtDateTime(t.trxAt, tz: t.timezone), if (t.plateNumber != null) formatPlate(t.plateNumber), t.partnerName]
              .whereType<String>()
              .join(' · ')),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: TrxStatusPills.of(t)),
        ]),
        isThreeLine: true,
      ),
    );
  }
}

class TrxStatusPills {
  static List<Widget> of(TrxView t) => [
        if (t.isPending) const Pill('Belum tersinkron', icon: Icons.cloud_upload_outlined, color: AppColors.warning),
        if (t.isRejected) const Pill('Ditolak server', icon: Icons.error_outline, color: AppColors.critical),
        if (t.isVoid) const Pill('VOID', icon: Icons.block, color: AppColors.critical),
        if (t.status == 'pending_approval') const Pill('Perlu ditinjau', icon: Icons.rule, color: AppColors.warning),
        if (t.voidRequested) const Pill('Diajukan void', icon: Icons.block, color: AppColors.warning),
      ];
}

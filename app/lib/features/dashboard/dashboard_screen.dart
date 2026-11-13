import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/config.dart';
import '../../data/local/database.dart';
import '../transactions/trx_type_sheet.dart';
import 'dashboard_provider.dart';

final _packagingProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchPackaging());

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh tiap 30 detik saat online (FR-02).
    _timer = Timer.periodic(AppConfig.dashboardRefresh, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!(ref.read(onlineProvider).value ?? false)) return;
    final engine = ref.read(syncEngineProvider);
    if (silent) {
      if (engine.isRunning) return;
      try {
        await engine.pull();
      } catch (_) {}
    } else {
      final r = await engine.sync();
      if (mounted && !r.ok) showSnack(context, r.summary, error: !(r.error?.isNetwork ?? false));
    }
    ref.invalidate(todaySummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final data = ref.watch(dashboardProvider);
    final locs = ref.watch(locationsProvider).value ?? const <Location>[];
    final selected = ref.watch(selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, ${user?.name.split(' ').first ?? ''}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Text('Stok Pasir Silika'),
        ]),
        actions: [SyncBadgeButton(onTap: () => context.go('/sync')), const SizedBox(width: 8)],
      ),
      floatingActionButton: (user?.canInput ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => showTrxTypeSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Transaksi'),
            )
          : null,
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(e),
              data: (d) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (locs.length > 1 && user?.role != 'operator') _LocationPicker(locs: locs, selected: selected),
                  _TotalCard(total: d.total, rows: d.rows),
                  const SizedBox(height: 14),
                  const _TodayCard(),
                  if (d.alerts.isNotEmpty) _AlertsCard(alerts: d.alerts),
                  SectionTitle('Stok per varian'),
                  if (d.rows.isEmpty)
                    const EmptyState(icon: Icons.inventory_2_outlined, message: 'Belum ada data produk. Tarik ke bawah untuk sinkron.')
                  else
                    ...d.rows.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StockCard(row: r, maxQty: d.rows.fold(Decimal.one, (m, x) => x.qty > m ? x.qty : m)),
                        )),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LocationPicker extends ConsumerWidget {
  const _LocationPicker({required this.locs, required this.selected});
  final List<Location> locs;
  final int? selected;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<int?>(
          initialValue: selected,
          decoration: const InputDecoration(labelText: 'Lokasi', prefixIcon: Icon(Icons.place_outlined)),
          items: [
            const DropdownMenuItem(value: null, child: Text('Semua Lokasi')),
            ...locs.map((l) => DropdownMenuItem(value: l.id, child: Text('${l.name} (${l.code})'))),
          ],
          onChanged: (v) => ref.read(selectedLocationProvider.notifier).select(v),
        ),
      );
}

class _TotalCard extends ConsumerWidget {
  const _TotalCard({required this.total, required this.rows});
  final Decimal total;
  final List<StockRow> rows;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastPull = ref.watch(lastPullAtProvider).value;
    final localDelta = rows.fold(Decimal.zero, (s, r) => s + r.localDelta);
    const on = Colors.white;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const IconCircle(Icons.inventory_2_rounded, color: Colors.white24, size: 36),
          const SizedBox(width: 10),
          Text('Total stok', style: TextStyle(color: on.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(fmtTon(total),
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: on, letterSpacing: -1)),
            ),
          ),
          const SizedBox(width: 8),
          Text('Ton', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: on.withValues(alpha: 0.85))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
          child: Text('Data per ${lastPull == null ? '-' : fmtDateTime(lastPull)}',
              style: const TextStyle(fontSize: 12, color: on, fontWeight: FontWeight.w500)),
        ),
        if (localDelta != Decimal.zero) ...[
          const SizedBox(height: 8),
          Text('Termasuk ${localDelta > Decimal.zero ? '+' : ''}${fmtTon(localDelta)} Ton belum tersinkron',
              style: TextStyle(fontSize: 12, color: on.withValues(alpha: 0.9))),
        ],
      ]),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider);
    final user = ref.watch(currentUserProvider);
    final loc = ref.watch(selectedLocationProvider);
    final cs = Theme.of(context).colorScheme;
    final s = summary.value;
    String inTon, outTon, trucks;
    var fromDevice = false;
    if (s != null) {
      final t = (s['today'] as Map).cast<String, dynamic>();
      inTon = fmtTonStr(t['in_ton'] as String);
      outTon = fmtTonStr(t['out_ton'] as String);
      trucks = '${t['truck_count']}';
    } else {
      final local = localToday(ref.watch(localTrxProvider).value ?? const [], loc);
      inTon = fmtTon(local.inTon);
      outTon = fmtTon(local.outTon);
      trucks = '${local.trucks}';
      fromDevice = true;
    }
    final pendingApproval = (s?['pending_approval_count'] as int?) ?? 0;
    final voidReq = (s?['void_request_count'] as int?) ?? 0;

    Widget stat(String label, String value, IconData icon, Color color) => Expanded(
          child: Column(children: [
            IconCircle(icon, color: color, size: 42, filled: false),
            const SizedBox(height: 8),
            FittedBox(child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fromDevice ? 'Hari ini · perangkat ini' : 'Hari ini',
              style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          Row(children: [
            stat('Masuk (Ton)', inTon, Icons.south_west_rounded, AppColors.tertiary),
            stat('Keluar (Ton)', outTon, Icons.north_east_rounded, AppColors.danger),
            stat('Ritase', trucks, Icons.local_shipping_rounded, AppColors.primary),
          ]),
          if ((user?.isManager ?? false) && (pendingApproval > 0 || voidReq > 0)) ...[
            const Divider(height: 28),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (pendingApproval > 0)
                ActionChip(
                  avatar: const Icon(Icons.rule_rounded, size: 18, color: AppColors.warning),
                  label: Text('$pendingApproval perlu ditinjau'),
                  onPressed: () => context.go('/history?status=pending_approval'),
                ),
              if (voidReq > 0)
                ActionChip(
                  avatar: const Icon(Icons.block_rounded, size: 18, color: AppColors.danger),
                  label: Text('$voidReq pengajuan void'),
                  onPressed: () => context.go('/history?void_requested=1'),
                ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});
  final List<({String level, String location, String product, Decimal qty, Decimal min})> alerts;
  @override
  Widget build(BuildContext context) {
    final critical = alerts.where((a) => a.level == 'critical').length;
    final color = critical > 0 ? AppColors.critical : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        color: color.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withValues(alpha: 0.4))),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: IconCircle(Icons.warning_amber_rounded, color: color, size: 40),
            title: Text(critical > 0 ? '$critical produk di bawah minimum' : '${alerts.length} produk menipis',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: const Text('Ketuk untuk detail'),
            children: alerts
                .map((a) => ListTile(
                      dense: true,
                      leading: StatusDot(a.level),
                      title: Text('${a.product} · ${a.location}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Stok ${fmtTon(a.qty)} Ton · minimum ${fmtTon(a.min)} Ton'),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StockCard extends ConsumerWidget {
  const _StockCard({required this.row, required this.maxQty});
  final StockRow row;
  final Decimal maxQty;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = statusColor(row.status);
    final packs = ref.watch(_packagingProvider).value ?? const <PackagingUnit>[];
    final cs = Theme.of(context).colorScheme;
    // Estimasi jumlah kemasan yang bisa dibuat dari stok (informatif, FR-06).
    final estimates = packs.where((p) => !p.isBulk && row.qty > Decimal.zero).map((p) {
      final n = (row.qty / Decimal.parse(p.tonPerUnit)).toDecimal(scaleOnInfinitePrecision: 3).floor();
      return '≈ ${fmtTon(n, decimals: 0)} ${p.name}';
    }).join(' · ');
    final ratio = row.qty <= Decimal.zero ? 0.0 : (row.qty.toDouble() / maxQty.toDouble()).clamp(0.02, 1.0);
    final minRatio = row.min <= Decimal.zero ? null : (row.min.toDouble() / maxQty.toDouble()).clamp(0.0, 1.0);
    final barColor = row.status == 'ok' ? AppColors.primary : color;
    final initials = row.product.meshSize ?? row.product.code.substring(0, row.product.code.length.clamp(0, 3));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: barColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(initials, style: TextStyle(fontWeight: FontWeight.w800, color: barColor)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  row.min > Decimal.zero ? 'Minimum ${fmtTon(row.min)} Ton' : 'Tanpa batas minimum',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ]),
            ),
            Pill(
              switch (row.status) { 'critical' => 'Kritis', 'warning' => 'Menipis', _ => 'Aman' },
              color: color,
            ),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(fmtTon(row.qty),
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: row.qty < Decimal.zero ? AppColors.critical : null)),
            const SizedBox(width: 6),
            Text('Ton', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          // Bar stok relatif terhadap produk terbanyak + penanda batas minimum
          LayoutBuilder(builder: (context, c) {
            return SizedBox(
              height: 10,
              child: Stack(children: [
                Container(decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(6))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: c.maxWidth * ratio,
                  decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6)),
                ),
                if (minRatio != null)
                  Positioned(
                    left: (c.maxWidth * minRatio - 1).clamp(0, c.maxWidth - 2),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: cs.onSurface.withValues(alpha: 0.55)),
                  ),
              ]),
            );
          }),
          if (row.localDelta != Decimal.zero) ...[
            const SizedBox(height: 8),
            Text('${row.localDelta > Decimal.zero ? '+' : ''}${fmtTon(row.localDelta)} Ton belum tersinkron',
                style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700)),
          ],
          if (estimates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(estimates, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ]),
      ),
    );
  }
}

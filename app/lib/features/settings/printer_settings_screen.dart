import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../delivery_note/thermal_printer.dart';

/// Pilih printer thermal Bluetooth (sudah dipasangkan) & ukuran kertas 58/80 mm.
class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});
  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  List<BluetoothInfo>? _devices;
  String? _mac;
  String _paper = '58';
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = ref.read(dbProvider);
    _mac = await db.getKv('printer_mac');
    _paper = await db.getKv('printer_paper') ?? '58';
    await _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _devices = await ThermalPrinter.pairedPrinters();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _select(BluetoothInfo d) async {
    final db = ref.read(dbProvider);
    await db.setKv('printer_mac', d.macAdress);
    await db.setKv('printer_name', d.name);
    setState(() => _mac = d.macAdress);
  }

  Future<void> _test() async {
    if (_mac == null) return;
    setState(() => _busy = true);
    try {
      await ThermalPrinter.printBytes(_mac!, await ThermalPrinter.testPage(mm80: _paper == '80'));
      if (mounted) showSnack(context, 'Halaman tes dikirim.');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Printer Bluetooth'),
          actions: [IconButton(onPressed: _busy ? null : _scan, icon: const Icon(Icons.refresh))],
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Pasangkan (pair) printer di Pengaturan Bluetooth HP terlebih dahulu, lalu pilih di bawah.'),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '58', label: Text('58 mm')),
              ButtonSegment(value: '80', label: Text('80 mm')),
            ],
            selected: {_paper},
            onSelectionChanged: (s) {
              setState(() => _paper = s.first);
              ref.read(dbProvider).setKv('printer_paper', _paper);
            },
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_devices != null && _devices!.isEmpty)
            const EmptyState(icon: Icons.bluetooth_disabled, message: 'Tidak ada perangkat Bluetooth yang dipasangkan.'),
          ...?_devices?.map((d) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  value: d.macAdress,
                  // ignore: deprecated_member_use
                  groupValue: _mac,
                  // ignore: deprecated_member_use
                  onChanged: (_) => _select(d),
                  title: Text(d.name),
                  subtitle: Text(d.macAdress),
                ),
              )),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _mac == null || _busy ? null : _test,
            icon: const Icon(Icons.print),
            label: const Text('Cetak halaman tes'),
          ),
        ]),
      );
}

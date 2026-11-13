import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/local/database.dart';
import '../dashboard/dashboard_provider.dart';

final _usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final r = await ref.watch(apiProvider).get<List<dynamic>>('/users');
  return r.map((e) => (e as Map).cast<String, dynamic>()).toList();
});

/// Layar 15 — Manajemen user (Owner): tambah, nonaktifkan, role, lokasi.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_usersProvider);
    Future<void> open([Map<String, dynamic>? u]) async {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _UserForm(user: u),
      );
      if (saved == true) ref.invalidate(_usersProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen User')),
      floatingActionButton: FloatingActionButton(onPressed: () => open(), child: const Icon(Icons.person_add)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(_usersProvider)),
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_usersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = users[i];
              final active = u['is_active'] == true;
              final locked = u['locked_until'] != null && DateTime.parse(u['locked_until'] as String).isAfter(DateTime.now());
              final devices = (u['devices'] as List?) ?? [];
              final lastSync = devices
                  .map((d) => DateTime.tryParse('${(d as Map)['last_sync_at']}'))
                  .whereType<DateTime>()
                  .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
              return ListTile(
                leading: CircleAvatar(child: Text('${u['name']}'.characters.first.toUpperCase())),
                title: Text('${u['name']}', style: TextStyle(decoration: active ? null : TextDecoration.lineThrough)),
                subtitle: Text([
                  '${roleLabels[u['role']]} · @${u['username']}',
                  (u['locations'] as List).map((l) => (l as Map)['name']).join(', '),
                  'Perangkat terakhir sinkron: ${fmtRelative(lastSync)}',
                ].where((s) => s.isNotEmpty).join('\n')),
                isThreeLine: true,
                trailing: Wrap(spacing: 4, children: [
                  if (!active) const Pill('Nonaktif', color: Colors.grey),
                  if (locked)
                    IconButton(
                      tooltip: 'Buka kunci login',
                      icon: const Icon(Icons.lock_open),
                      onPressed: () async {
                        await ref.read(apiProvider).post('/users/${u['id']}/unlock');
                        ref.invalidate(_usersProvider);
                      },
                    ),
                ]),
                onTap: () => open(u),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({this.user});
  final Map<String, dynamic>? user;
  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?['name'] as String?);
  late final _username = TextEditingController(text: widget.user?['username'] as String?);
  late final _email = TextEditingController(text: widget.user?['email'] as String?);
  final _password = TextEditingController();
  late String _role = (widget.user?['role'] as String?) ?? 'operator';
  late bool _active = widget.user?['is_active'] != false;
  late final Set<int> _locs = {...((widget.user?['locations'] as List?) ?? []).map((l) => (l as Map)['id'] as int)};
  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_role != 'owner' && _locs.isEmpty) {
      showSnack(context, 'Pilih minimal satu lokasi.', error: true);
      return;
    }
    if (_role == 'operator' && _locs.length > 1) {
      showSnack(context, 'Operator hanya boleh 1 lokasi.', error: true);
      return;
    }
    if (widget.user != null && !_active) {
      final ok = await confirmDialog(context,
          title: 'Nonaktifkan user?', message: 'User langsung keluar dari semua perangkat.', ok: 'Nonaktifkan', danger: true);
      if (!ok) return;
    }
    setState(() => _saving = true);
    final body = {
      'name': _name.text.trim(),
      'username': _username.text.trim().toLowerCase(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'role': _role,
      'is_active': _active,
      'location_ids': _role == 'owner' ? <int>[] : _locs.toList(),
      if (_password.text.isNotEmpty) 'password': _password.text,
    };
    try {
      final api = ref.read(apiProvider);
      if (widget.user == null) {
        await api.post('/users', body);
      } else {
        await api.put('/users/${widget.user!['id']}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locs = ref.watch(locationsProvider).value ?? const <Location>[];
    final isNew = widget.user == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(isNew ? 'Tambah user' : 'Ubah user', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => RegExp(r'^[a-zA-Z0-9._-]{3,50}$').hasMatch(v ?? '') ? null : '3-50 huruf/angka'),
            const SizedBox(height: 12),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (opsional)')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: isNew ? 'Password' : 'Password baru (kosongkan jika tidak diubah)'),
              validator: (v) {
                if (isNew && (v ?? '').isEmpty) return 'Wajib diisi';
                if ((v ?? '').isNotEmpty && v!.length < 8) return 'Minimal 8 karakter';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: roleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            if (_role != 'owner') ...[
              const SizedBox(height: 12),
              Text(_role == 'operator' ? 'Lokasi (pilih 1)' : 'Lokasi yang ditugaskan'),
              Wrap(spacing: 8, children: [
                for (final l in locs)
                  FilterChip(
                    label: Text(l.name),
                    selected: _locs.contains(l.id),
                    onSelected: (s) => setState(() {
                      if (_role == 'operator') _locs.clear();
                      s ? _locs.add(l.id) : _locs.remove(l.id);
                    }),
                  ),
              ]),
            ],
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Aktif'), value: _active,
                onChanged: (v) => setState(() => _active = v)),
            FilledButton(onPressed: _saving ? null : _save, child: const Text('Simpan')),
          ]),
        ),
      ),
    );
  }
}

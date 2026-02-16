import 'package:flutter/material.dart';
import 'package:hh_protokol/services/db_service.dart';
import 'package:hh_protokol/ui/widgets.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sklepy', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _q,
            onChanged: (v) => setState(() => _query = v),
            decoration: hhInput('Szukaj', hint: 'miasto / numer / adres', icon: Icons.search_rounded),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder(
              future: DbService.instance.listStores(q: _query),
              builder: (context, snap) {
                final data = (snap.data ?? const <Map<String, Object?>>[]);
                if (data.isEmpty) {
                  return Center(
                    child: Text('Brak sklepów. Dodaj +', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                  );
                }
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final m = data[i];
                    final id = m['id'] as int;
                    final city = (m['city'] ?? '') as String;
                    final no = (m['store_no'] ?? '') as String;
                    final name = (m['name'] ?? '') as String;
                    final address = (m['address'] ?? '') as String;
                    return HHCard(
                      child: ListTile(
                        title: Text('$city ($no)', style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text([name, address].where((e) => e.trim().isNotEmpty).join(' • ')),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            await DbService.instance.deleteStore(id);
                            setState(() {});
                          },
                        ),
                        onTap: () => _edit(context, existing: m),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, {Map<String, Object?>? existing}) async {
    final id = existing?['id'] as int?;
    final city = TextEditingController(text: (existing?['city'] ?? '') as String);
    final no = TextEditingController(text: (existing?['store_no'] ?? '') as String);
    final name = TextEditingController(text: (existing?['name'] ?? '') as String);
    final addr = TextEditingController(text: (existing?['address'] ?? '') as String);
    final phone = TextEditingController(text: (existing?['phone'] ?? '') as String);
    final email = TextEditingController(text: (existing?['email'] ?? '') as String);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: HHCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(id == null ? 'Dodaj sklep' : 'Edytuj sklep', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(controller: city, decoration: hhInput('Miejscowość', icon: Icons.location_city_outlined)),
                  const SizedBox(height: 10),
                  TextField(controller: no, decoration: hhInput('Nr sklepu', hint: 'np. 0123', icon: Icons.numbers_rounded)),
                  const SizedBox(height: 10),
                  TextField(controller: name, decoration: hhInput('Nazwa', hint: 'np. Douglas', icon: Icons.storefront_outlined)),
                  const SizedBox(height: 10),
                  TextField(controller: addr, decoration: hhInput('Adres', icon: Icons.place_outlined)),
                  const SizedBox(height: 10),
                  TextField(controller: phone, decoration: hhInput('Telefon', icon: Icons.phone_outlined)),
                  const SizedBox(height: 10),
                  TextField(controller: email, decoration: hhInput('Email', icon: Icons.email_outlined)),
                  const SizedBox(height: 14),
                  HHButton(
                    label: 'Zapisz',
                    icon: Icons.check_rounded,
                    onPressed: () async {
                      if (city.text.trim().isEmpty || no.text.trim().isEmpty) return;
                      await DbService.instance.upsertStore(
                        id: id,
                        city: city.text,
                        storeNo: no.text,
                        name: name.text,
                        address: addr.text,
                        phone: phone.text,
                        email: email.text,
                      );
                      if (mounted) Navigator.of(context).pop();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hh_protokol/services/draft_service.dart';
import 'package:hh_protokol/ui/cosmic_background.dart';
import 'package:hh_protokol/ui/protocol_flow.dart';
import 'package:hh_protokol/ui/crew_screen.dart';
import 'package:hh_protokol/ui/stores_screen.dart';
import 'package:hh_protokol/ui/widgets.dart';

class HomeScreen extends StatefulWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;
  late final DraftService _draft;

  String _authorName(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    return 'Użytkownik';
  }

  @override
  void initState() {
    super.initState();
    _draft = DraftService();
  }

  @override
  Widget build(BuildContext context) {
    final author = _authorName(context);

    final pages = [
      _StartTab(authorName: author, draft: _draft),
      StoresScreen(),
      CrewScreen(),
    ];

    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: pages[_idx]),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: HHCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _idx,
              onDestinationSelected: (v) => setState(() => _idx = v),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.add_task_rounded), label: 'Protokół'),
                NavigationDestination(icon: Icon(Icons.store_mall_directory_outlined), label: 'Sklepy'),
                NavigationDestination(icon: Icon(Icons.groups_2_outlined), label: 'Ekipa'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartTab extends StatelessWidget {
  final String authorName;
  final DraftService draft;

  const _StartTab({required this.authorName, required this.draft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Magazyn Helium House',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Sporządza: $authorName',
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 18),
          HHCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nowy protokół', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Skan • zdjęcia • uwagi • podpis • PDF+ZIP → mail/WhatsApp',
                    style: TextStyle(color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 14),
                HHButton(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () async {
                    draft.reset();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProtocolFlowScreen(authorName: authorName, draft: draft),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          HHCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Szybkie akcje', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _Chip(label: 'Przekazanie'),
                    _Chip(label: 'Odebranie'),
                    _Chip(label: 'Montaż'),
                    _Chip(label: 'Demontaż'),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Świadków nie ma. 😉', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        color: Colors.white.withOpacity(0.04),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

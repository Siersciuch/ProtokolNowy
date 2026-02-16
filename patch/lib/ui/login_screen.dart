import 'package:flutter/material.dart';
import 'package:hh_protokol/services/auth_service.dart';
import 'package:hh_protokol/ui/cosmic_background.dart';
import 'package:hh_protokol/ui/home_screen.dart';
import 'package:hh_protokol/ui/widgets.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    AuthService.instance.lastUser().then((v) {
      if (v != null && mounted) {
        _name.text = v;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _doLoginOrRegister() async {
    setState(() {
      _busy = true;
      _err = null;
    });

    final fullName = _name.text.trim();
    final password = _pass.text;
    if (fullName.isEmpty || password.isEmpty) {
      setState(() {
        _busy = false;
        _err = 'Wpisz imię i nazwisko oraz hasło.';
      });
      return;
    }

    final isReg = await AuthService.instance.isUserRegistered(fullName);

    try {
      if (!isReg) {
        await AuthService.instance.register(fullName, password);
      } else {
        final ok = await AuthService.instance.login(fullName, password);
        if (!ok) {
          setState(() {
            _busy = false;
            _err = 'Złe hasło.';
          });
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.route, arguments: fullName);
    } catch (_) {
      setState(() {
        _busy = false;
        _err = 'Coś poszło nie tak. Spróbuj ponownie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
                Text(
                  'HH Protokół',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Imię i nazwisko wpisujesz ręcznie. Pierwsze logowanie = ustawienie hasła na tym telefonie.',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
                const SizedBox(height: 18),
                HHCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: hhInput('Imię i nazwisko', hint: 'np. Piotr Kowek', icon: Icons.badge_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass,
                        obscureText: true,
                        decoration: hhInput('Hasło', hint: 'bez polskich znaków', icon: Icons.lock_outline),
                      ),
                      const SizedBox(height: 12),
                      if (_err != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_err!, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      const SizedBox(height: 8),
                      HHButton(
                        label: _busy ? '...' : 'Wejdź',
                        icon: Icons.login_rounded,
                        onPressed: _busy ? null : _doLoginOrRegister,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Tip: hasło jest lokalne i nie synchronizuje się między telefonami.',
                  style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

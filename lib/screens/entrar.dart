import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/screens/painel.dart';
import 'package:nosso_quintal/widgets.dart';

// Só o feirante precisa de conta.
class EntrarScreen extends StatefulWidget {
  const EntrarScreen({super.key});

  @override
  State<EntrarScreen> createState() => _EntrarScreenState();
}

class _EntrarScreenState extends State<EntrarScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _criarConta = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    // Já entrou antes? Vai direto para o painel.
    if (FirebaseAuth.instance.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _irParaPainel());
    }
  }

  void _irParaPainel() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const PainelScreen()),
  );

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      final auth = FirebaseAuth.instance;
      if (_criarConta) {
        await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _senha.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _senha.text,
        );
      }
      if (mounted) _irParaPainel();
    } on FirebaseAuthException catch (e) {
      if (mounted) avisar(context, _erro(e.code));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _google() async {
    try {
      final google = GoogleAuthProvider();
      final auth = FirebaseAuth.instance;
      await (kIsWeb
          ? auth.signInWithPopup(google)
          : auth.signInWithProvider(google));
      if (mounted) _irParaPainel();
    } on FirebaseAuthException catch (e) {
      if (mounted && e.code != 'popup-closed-by-user') {
        avisar(context, _erro(e.code));
      }
    }
  }

  Future<void> _esqueciSenha() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      avisar(context, 'Escreva seu e-mail acima e toque de novo.');
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) {
      avisar(context, 'Mandamos um link para $email trocar a senha.');
    }
  }

  String _erro(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'E-mail ou senha não conferem.',
    'email-already-in-use' =>
      'Esse e-mail já tem conta. Toque em "Já tenho conta".',
    'weak-password' => 'A senha precisa ter pelo menos 6 letras ou números.',
    'invalid-email' => 'Esse e-mail não parece certo.',
    'too-many-requests' =>
      'Muitas tentativas. Espere um pouco e tente de novo.',
    _ => 'Não deu certo ($code). Tente de novo.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Área do feirante')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Largura(
              max: 460,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Logo(altura: 130),
                  const SizedBox(height: 12),
                  Text(
                    _criarConta
                        ? 'Cadastre sua banca'
                        : 'Entre para cuidar da sua banca',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v ?? '').contains('@') ? null : 'Escreva seu e-mail',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _senha,
                    obscureText: true,
                    onFieldSubmitted: (_) => _entrar(),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'Mínimo de 6 letras ou números'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _carregando ? null : _entrar,
                    child: _carregando
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Text(_criarConta ? 'Criar minha conta' : 'Entrar'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => setState(() => _criarConta = !_criarConta),
                    child: Text(
                      _criarConta
                          ? 'Já tenho conta'
                          : 'Primeira vez? Criar conta',
                    ),
                  ),
                  if (!_criarConta)
                    TextButton(
                      onPressed: _esqueciSenha,
                      child: const Text('Esqueci minha senha'),
                    ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ou'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _google,
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    label: const Text('Entrar com Google'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

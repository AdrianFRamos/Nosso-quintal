import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/repo.dart';
import 'package:nosso_quintal/screens/banca_form.dart';
import 'package:nosso_quintal/screens/produto_form.dart';
import 'package:nosso_quintal/theme.dart';
import 'package:nosso_quintal/widgets.dart';

class PainelScreen extends StatefulWidget {
  const PainelScreen({super.key});

  @override
  State<PainelScreen> createState() => _PainelScreenState();
}

class _PainelScreenState extends State<PainelScreen> {
  late Future<Banca?> _banca;

  @override
  void initState() {
    super.initState();
    _banca = buscarBanca(uidAtual!);
  }

  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Banca?>(
      future: _banca,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final banca = snap.data;
        // Primeira vez: cadastra a banca antes de tudo.
        if (banca == null) {
          return BancaFormScreen(
            primeiraVez: true,
            onSalvo: () => setState(() => _banca = buscarBanca(uidAtual!)),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(banca.nome),
              actions: [
                TextButton.icon(
                  onPressed: _sair,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.eco_outlined), text: 'Produtos'),
                  Tab(
                    icon: Icon(Icons.receipt_long_outlined),
                    text: 'Encomendas',
                  ),
                  Tab(
                    icon: Icon(Icons.storefront_outlined),
                    text: 'Minha banca',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _AbaProdutos(banca: banca),
                _AbaEncomendas(banca: banca),
                BancaFormScreen(
                  banca: banca,
                  embutido: true,
                  onSalvo: () =>
                      setState(() => _banca = buscarBanca(uidAtual!)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AbaProdutos extends StatefulWidget {
  final Banca banca;
  const _AbaProdutos({required this.banca});

  @override
  State<_AbaProdutos> createState() => _AbaProdutosState();
}

class _AbaProdutosState extends State<_AbaProdutos> {
  late Future<List<Produto>> _produtos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() =>
      setState(() => _produtos = buscarProdutosDaBanca(widget.banca.id));

  Future<void> _abrirForm([Produto? produto]) async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProdutoFormScreen(banca: widget.banca, produto: produto),
      ),
    );
    if (salvou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Cores.tomate,
        foregroundColor: Colors.white,
        onPressed: () => _abrirForm(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo produto',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<Produto>>(
        future: _produtos,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final produtos = snap.data!;
          if (produtos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Cadastre o que você leva para a feira.\nToque em "Novo produto".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const Largura(
                max: 760,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ligue o que você vai levar nesta semana. O que estiver desligado aparece como "acabou".',
                    style: TextStyle(fontSize: 16, color: Cores.musgo),
                  ),
                ),
              ),
              for (final p in produtos)
                Largura(
                  max: 760,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            EmojiProduto(p.emoji, tamanho: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _abrirForm(p),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nome,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      p.precoTexto,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Cores.tomate,
                                      ),
                                    ),
                                    const Text(
                                      'toque para editar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Cores.musgo,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Transform.scale(
                                  scale: 1.25,
                                  child: Switch(
                                    value: p.disponivel,
                                    onChanged: (v) async {
                                      await marcarDisponivel(p.id, v);
                                      _carregar();
                                    },
                                  ),
                                ),
                                Text(
                                  p.disponivel ? 'Tem' : 'Acabou',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: p.disponivel
                                        ? Cores.musgo
                                        : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AbaEncomendas extends StatefulWidget {
  final Banca banca;
  const _AbaEncomendas({required this.banca});

  @override
  State<_AbaEncomendas> createState() => _AbaEncomendasState();
}

class _AbaEncomendasState extends State<_AbaEncomendas> {
  late Future<List<Encomenda>> _encomendas;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() =>
      setState(() => _encomendas = buscarEncomendas(widget.banca.id));

  Future<void> _status(Encomenda e, String status) async {
    await mudarStatusEncomenda(e.id, status);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Encomenda>>(
      future: _encomendas,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final lista = snap.data!;
        if (lista.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma encomenda ainda.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _carregar(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in lista)
                Largura(
                  max: 760,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: e.status == 'nova' ? Cores.tomate : Cores.mata,
                          width: e.status == 'nova' ? 2.4 : 1.4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.clienteNome,
                                    style: GoogleFonts.lora(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    statusEncomenda[e.status] ?? e.status,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Retira: ${e.feiraNome}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Cores.musgo,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final i in e.itens)
                              Text(
                                '• ${quantidade((i['quantidade'] as num).toDouble())} ${i['unidade']} de ${i['nome']}',
                                style: const TextStyle(fontSize: 17),
                              ),
                            if (e.observacao.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Recado: ${e.observacao}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'Total: ${reais(e.total)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Cores.tomate,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (e.status == 'nova')
                                  ElevatedButton(
                                    onPressed: () => _status(e, 'separada'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                    ),
                                    child: const Text('Já separei'),
                                  ),
                                if (e.status == 'separada')
                                  ElevatedButton(
                                    onPressed: () => _status(e, 'entregue'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 48),
                                      backgroundColor: Cores.musgo,
                                    ),
                                    child: const Text('Entreguei'),
                                  ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  icon: const Icon(Icons.chat_outlined),
                                  label: const Text('WhatsApp do cliente'),
                                  onPressed: () => abrirWhatsapp(
                                    e.clienteTelefone,
                                    'Olá, ${e.clienteNome}! Aqui é da ${widget.banca.nome}, sobre sua encomenda do Nosso Quintal.',
                                  ),
                                ),
                                if (e.status == 'nova' ||
                                    e.status == 'separada')
                                  TextButton(
                                    onPressed: () => _status(e, 'cancelada'),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

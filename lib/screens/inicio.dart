import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/repo.dart';
import 'package:nosso_quintal/screens/banca.dart';
import 'package:nosso_quintal/screens/entrar.dart';
import 'package:nosso_quintal/theme.dart';
import 'package:nosso_quintal/widgets.dart';

// Vitrine aberta: ninguém precisa de conta para ver a feira ou encomendar.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late Future<(List<Feira>, List<Banca>, List<Produto>)> _dados;
  String _busca = '';
  String? _categoria;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _dados = (() async => (
        await buscarFeiras(),
        await buscarBancas(),
        await buscarProdutosDisponiveis(),
      ))();
    });
  }

  Future<void> _abrirBanca(Banca banca) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BancaScreen(banca: banca)),
    );
    _carregar();
  }

  List<Produto> _filtrar(List<Produto> produtos) {
    final q = _busca.trim().toLowerCase();
    return produtos.where((p) {
      final bateBusca =
          q.isEmpty ||
          p.nome.toLowerCase().contains(q) ||
          p.bancaNome.toLowerCase().contains(q);
      return bateBusca && (_categoria == null || p.categoria == _categoria);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nosso Quintal'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              icon: const Icon(Icons.storefront),
              label: const Text('Sou feirante'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EntrarScreen()),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _dados,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Não foi possível carregar a feira.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _carregar,
                      child: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (feiras, bancas, produtos) = snap.data!;
          final bancasPorId = {for (final b in bancas) b.id: b};
          final visiveis = _filtrar(produtos);

          return RefreshIndicator(
            onRefresh: () async => _carregar(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: Largura(child: _cabecalho(feiras))),
                SliverToBoxAdapter(child: Largura(child: _buscaECategorias())),
                if (_busca.isEmpty &&
                    _categoria == null &&
                    bancas.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Largura(
                      child: TituloSecao(
                        'As bancas',
                        subtitulo: 'Quem planta, colhe e traz para a feira',
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Largura(child: _listaBancas(bancas, produtos)),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Largura(
                    child: TituloSecao(
                      _categoria ??
                          (_busca.isEmpty
                              ? 'Tem na feira esta semana'
                              : 'Resultado da busca'),
                      subtitulo: '${visiveis.length} produto(s)',
                    ),
                  ),
                ),
                if (visiveis.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Nada encontrado por aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Largura(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final p in visiveis)
                              _CartaoProduto(
                                produto: p,
                                onTap: bancasPorId[p.bancaId] == null
                                    ? null
                                    : () =>
                                          _abrirBanca(bancasPorId[p.bancaId]!),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabecalho(List<Feira> feiras) {
    final hoje = DateTime.now();
    final proximas = [...feiras]
      ..sort((a, b) => a.proximaData(hoje).compareTo(b.proximaData(hoje)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          const Logo(altura: 170),
          const SizedBox(height: 8),
          Text(
            'Da roça de União da Vitória para a sua mesa',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Cores.musgo,
            ),
          ),
          const SizedBox(height: 16),
          for (final f in proximas.take(2))
            _CartaoFeira(feira: f, data: f.proximaData(hoje), hoje: hoje),
        ],
      ),
    );
  }

  Widget _buscaECategorias() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => _busca = v),
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'O que você procura? Ex.: alface, mel, ovos',
              prefixIcon: Icon(Icons.search, size: 28),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final (nome, emoji) in categorias)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Text(emoji, style: const TextStyle(fontSize: 18)),
                    label: Text(nome),
                    selected: _categoria == nome,
                    onSelected: (s) =>
                        setState(() => _categoria = s ? nome : null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _listaBancas(List<Banca> bancas, List<Produto> produtos) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: bancas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final b = bancas[i];
          final qtd = produtos.where((p) => p.bancaId == b.id).length;
          return SizedBox(
            width: 250,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _abrirBanca(b),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (b.feirante.isNotEmpty)
                        Text(b.feirante, style: const TextStyle(fontSize: 16)),
                      if (b.origem.isNotEmpty)
                        Text(
                          b.origem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Cores.musgo,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '$qtd produto(s) esta semana  →',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Cores.tomate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartaoFeira extends StatelessWidget {
  final Feira feira;
  final DateTime data;
  final DateTime hoje;
  const _CartaoFeira({
    required this.feira,
    required this.data,
    required this.hoje,
  });

  @override
  Widget build(BuildContext context) {
    final ehHoje =
        data.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays == 0;
    final quando = ehHoje
        ? 'Hoje'
        : '${nomesDiaSemana[feira.diaSemana][0].toUpperCase()}${nomesDiaSemana[feira.diaSemana].substring(1)}, '
              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ehHoje ? Cores.mata : Colors.white,
          border: Border.all(color: Cores.mata, width: 1.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event,
              size: 36,
              color: ehHoje ? Cores.papel : Cores.tomate,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$quando · ${feira.horario}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ehHoje ? Cores.papel : Cores.mata,
                    ),
                  ),
                  Text(
                    '${feira.nome} — ${feira.local}',
                    style: TextStyle(
                      fontSize: 16,
                      color: ehHoje ? Cores.papelEscuro : Cores.musgo,
                    ),
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

class _CartaoProduto extends StatelessWidget {
  final Produto produto;
  final VoidCallback? onTap;
  const _CartaoProduto({required this.produto, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                EmojiProduto(produto.emoji, tamanho: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        produto.precoTexto,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Cores.tomate,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              produto.bancaNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Cores.musgo,
                              ),
                            ),
                          ),
                          if (produto.organico) ...[
                            const SizedBox(width: 6),
                            const SeloOrganico(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

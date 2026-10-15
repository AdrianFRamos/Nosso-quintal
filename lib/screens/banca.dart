import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/repo.dart';
import 'package:nosso_quintal/screens/encomenda.dart';
import 'package:nosso_quintal/theme.dart';
import 'package:nosso_quintal/widgets.dart';

class BancaScreen extends StatefulWidget {
  final Banca banca;
  const BancaScreen({super.key, required this.banca});

  @override
  State<BancaScreen> createState() => _BancaScreenState();
}

class _BancaScreenState extends State<BancaScreen> {
  late Future<(List<Produto>, List<Feira>)> _dados;
  final Map<String, double> _quantidades = {}; // produtoId -> quantidade

  @override
  void initState() {
    super.initState();
    _dados = (() async =>
        (await buscarProdutosDaBanca(widget.banca.id), await buscarFeiras()))();
  }

  void _mudar(Produto p, int direcao) {
    setState(() {
      final nova =
          (_quantidades[p.id] ?? 0) + direcao * passoDaUnidade(p.unidade);
      if (nova <= 0) {
        _quantidades.remove(p.id);
      } else {
        _quantidades[p.id] = nova;
      }
    });
  }

  List<ItemEncomenda> _itens(List<Produto> produtos) => [
    for (final p in produtos)
      if ((_quantidades[p.id] ?? 0) > 0) ItemEncomenda(p, _quantidades[p.id]!),
  ];

  @override
  Widget build(BuildContext context) {
    final banca = widget.banca;
    return FutureBuilder(
      future: _dados,
      builder: (context, snap) {
        final produtos = snap.data?.$1 ?? const <Produto>[];
        final feiras = (snap.data?.$2 ?? const <Feira>[])
            .where((f) => banca.feiras.contains(f.id))
            .toList();
        final disponiveis = produtos.where((p) => p.disponivel).toList();
        final acabaram = produtos.where((p) => !p.disponivel).toList();
        final itens = _itens(disponiveis);
        final total = itens.fold(0.0, (s, i) => s + i.subtotal);

        return Scaffold(
          appBar: AppBar(title: Text(banca.nome)),
          body: !snap.hasData
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Largura(
                      max: 760,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banca.nome,
                              style: GoogleFonts.lora(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (banca.feirante.isNotEmpty)
                              Text(
                                'com ${banca.feirante}',
                                style: const TextStyle(fontSize: 18),
                              ),
                            if (banca.origem.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    color: Cores.musgo,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      banca.origem,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Cores.musgo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (banca.descricao.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                banca.descricao,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (feiras.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final f in feiras)
                                    Chip(
                                      avatar: const Icon(Icons.event, size: 18),
                                      label: Text(
                                        '${nomesDiaSemana[f.diaSemana]} · ${f.nome}',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (banca.whatsapp.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.chat_outlined),
                                label: const Text('Conversar no WhatsApp'),
                                onPressed: () => abrirWhatsapp(
                                  banca.whatsapp,
                                  'Olá! Vi a ${banca.nome} no Nosso Quintal e queria tirar uma dúvida.',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Largura(
                      max: 760,
                      child: TituloSecao(
                        'Tem esta semana',
                        subtitulo: disponiveis.isEmpty
                            ? null
                            : 'Toque em + para separar na sua encomenda',
                      ),
                    ),
                    if (disponiveis.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Esta banca ainda não colocou os produtos da semana.',
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    for (final p in disponiveis)
                      Largura(
                        max: 760,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: _LinhaProduto(
                            produto: p,
                            qtd: _quantidades[p.id] ?? 0,
                            onMenos: () => _mudar(p, -1),
                            onMais: () => _mudar(p, 1),
                          ),
                        ),
                      ),
                    if (acabaram.isNotEmpty) ...[
                      const Largura(
                        max: 760,
                        child: TituloSecao('Acabou esta semana'),
                      ),
                      for (final p in acabaram)
                        Largura(
                          max: 760,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Opacity(
                              opacity: 0.5,
                              child: _LinhaProduto(produto: p, qtd: 0),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
          bottomNavigationBar: itens.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Cores.papel,
                      border: Border(
                        top: BorderSide(color: Cores.mata, width: 1.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Largura(
                      max: 760,
                      child: ElevatedButton(
                        onPressed: () async {
                          final enviada = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EncomendaScreen(
                                banca: banca,
                                itens: itens,
                                feiras: feiras,
                              ),
                            ),
                          );
                          if (enviada == true) setState(_quantidades.clear);
                        },
                        child: Text(
                          'Encomendar ${itens.length} item(ns) · ${reais(total)}',
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _LinhaProduto extends StatelessWidget {
  final Produto produto;
  final double qtd;
  final VoidCallback? onMenos;
  final VoidCallback? onMais;
  const _LinhaProduto({
    required this.produto,
    required this.qtd,
    this.onMenos,
    this.onMais,
  });

  @override
  Widget build(BuildContext context) {
    final escolhido = qtd > 0;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: escolhido ? Cores.tomate : Cores.mata,
          width: escolhido ? 2.4 : 1.4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            EmojiProduto(produto.emoji, tamanho: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produto.nome,
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
                  if (produto.organico)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: SeloOrganico(),
                    ),
                ],
              ),
            ),
            if (onMais != null) ...[
              _BotaoRedondo(
                icone: Icons.remove,
                onPressed: escolhido ? onMenos : null,
                rotulo: 'Tirar',
              ),
              SizedBox(
                width: 64,
                child: Text(
                  escolhido ? '${quantidade(qtd)}\n${produto.unidade}' : '0',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              _BotaoRedondo(
                icone: Icons.add,
                onPressed: onMais,
                rotulo: 'Pôr',
                destaque: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotaoRedondo extends StatelessWidget {
  final IconData icone;
  final VoidCallback? onPressed;
  final String rotulo;
  final bool destaque;
  const _BotaoRedondo({
    required this.icone,
    required this.onPressed,
    required this.rotulo,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: rotulo,
      iconSize: 28,
      constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
      style: IconButton.styleFrom(
        backgroundColor: destaque ? Cores.tomate : Cores.papelEscuro,
        foregroundColor: destaque ? Colors.white : Cores.mata,
        disabledBackgroundColor: Cores.papelEscuro.withValues(alpha: 0.5),
      ),
      onPressed: onPressed,
      icon: Icon(icone),
    );
  }
}

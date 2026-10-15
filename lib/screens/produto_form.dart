import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/repo.dart';
import 'package:nosso_quintal/theme.dart';
import 'package:nosso_quintal/widgets.dart';

// Emojis para o feirante escolher a "foto" do produto (sem precisar fotografar).
const _emojis = [
  '🥬',
  '🥦',
  '🥒',
  '🌽',
  '🥕',
  '🧅',
  '🧄',
  '🥔',
  '🍠',
  '🍅',
  '🌶️',
  '🫑',
  '🍆',
  '🎃',
  '🫘',
  '🥜',
  '🍓',
  '🍎',
  '🍐',
  '🍊',
  '🍋',
  '🍌',
  '🍇',
  '🍑',
  '🍉',
  '🍍',
  '🥝',
  '🫐',
  '🥑',
  '🥚',
  '🧀',
  '🥛',
  '🍯',
  '🥖',
  '🍞',
  '🥐',
  '🍪',
  '🥧',
  '🍰',
  '🫙',
  '🌿',
  '🌱',
  '🌻',
  '🌷',
  '🪴',
  '🍄',
  '🧺',
  '🧶',
  '🪵',
];

class ProdutoFormScreen extends StatefulWidget {
  final Banca banca;
  final Produto? produto;
  const ProdutoFormScreen({super.key, required this.banca, this.produto});

  @override
  State<ProdutoFormScreen> createState() => _ProdutoFormScreenState();
}

class _ProdutoFormScreenState extends State<ProdutoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.produto?.nome);
  late final _preco = TextEditingController(
    text: widget.produto == null
        ? ''
        : widget.produto!.preco.toStringAsFixed(2).replaceAll('.', ','),
  );
  late String _categoria = widget.produto?.categoria ?? categorias.first.$1;
  late String _emoji = widget.produto?.emoji ?? emojiDaCategoria(_categoria);
  late String _unidade = widget.produto?.unidade ?? 'kg';
  late bool _organico = widget.produto?.organico ?? false;
  late bool _disponivel = widget.produto?.disponivel ?? true;
  bool _salvando = false;

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await salvarProduto(
        Produto(
          id: widget.produto?.id ?? '',
          bancaId: widget.banca.id,
          bancaNome: widget.banca.nome,
          nome: _nome.text.trim(),
          categoria: _categoria,
          emoji: _emoji,
          preco: lerPreco(_preco.text)!,
          unidade: _unidade,
          organico: _organico,
          disponivel: _disponivel,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) avisar(context, 'Não deu para salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar este produto?'),
        content: Text(
          widget.produto!.nome,
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await excluirProduto(widget.produto!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      texto,
      style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produto == null ? 'Novo produto' : 'Editar produto'),
        actions: [
          if (widget.produto != null)
            IconButton(
              onPressed: _excluir,
              tooltip: 'Apagar',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Largura(
              max: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: EmojiProduto(_emoji, tamanho: 56)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto',
                      hintText: 'Ex.: Alface crespa',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Escreva o nome' : null,
                  ),
                  _rotulo('Tipo'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (nome, emoji) in categorias)
                        ChoiceChip(
                          avatar: Text(
                            emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          label: Text(nome),
                          selected: _categoria == nome,
                          onSelected: (_) => setState(() {
                            // Troca o emoji junto, se ainda for o padrão da categoria antiga.
                            if (_emoji == emojiDaCategoria(_categoria)) {
                              _emoji = emoji;
                            }
                            _categoria = nome;
                          }),
                        ),
                    ],
                  ),
                  _rotulo('Desenho do produto'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in _emojis)
                        InkWell(
                          onTap: () => setState(() => _emoji = e),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _emoji == e
                                  ? Cores.papelEscuro
                                  : Colors.white,
                              border: Border.all(
                                color: _emoji == e
                                    ? Cores.tomate
                                    : Cores.papelEscuro,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                    ],
                  ),
                  _rotulo('Preço'),
                  TextFormField(
                    controller: _preco,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      suffixText: 'por $_unidade',
                    ),
                    validator: (v) {
                      final p = lerPreco(v ?? '');
                      return p == null || p <= 0
                          ? 'Coloque o preço, ex.: 5,00'
                          : null;
                    },
                  ),
                  _rotulo('Vende por'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final u in unidades)
                        ChoiceChip(
                          label: Text(u),
                          selected: _unidade == u,
                          onSelected: (_) => setState(() => _unidade = u),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _organico,
                    onChanged: (v) => setState(() => _organico = v),
                    title: const Text(
                      'Orgânico / sem veneno',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _disponivel,
                    onChanged: (v) => setState(() => _disponivel = v),
                    title: const Text(
                      'Tem esta semana',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: const Text('Salvar produto'),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/repo.dart';
import 'package:nosso_quintal/widgets.dart';

// Cadastro/edição da banca. "embutido" = dentro da aba do painel (sem AppBar própria).
class BancaFormScreen extends StatefulWidget {
  final Banca? banca;
  final bool primeiraVez;
  final bool embutido;
  final VoidCallback onSalvo;
  const BancaFormScreen({
    super.key,
    this.banca,
    this.primeiraVez = false,
    this.embutido = false,
    required this.onSalvo,
  });

  @override
  State<BancaFormScreen> createState() => _BancaFormScreenState();
}

class _BancaFormScreenState extends State<BancaFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.banca?.nome);
  late final _feirante = TextEditingController(text: widget.banca?.feirante);
  late final _origem = TextEditingController(text: widget.banca?.origem);
  late final _descricao = TextEditingController(text: widget.banca?.descricao);
  late final _whatsapp = TextEditingController(text: widget.banca?.whatsapp);
  late final Set<String> _feiras = {...?widget.banca?.feiras};
  late final Future<List<Feira>> _todasFeiras = buscarFeiras();
  bool _salvando = false;

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await salvarBanca(
        Banca(
          id: uidAtual!,
          nome: _nome.text.trim(),
          feirante: _feirante.text.trim(),
          origem: _origem.text.trim(),
          descricao: _descricao.text.trim(),
          whatsapp: _whatsapp.text.trim(),
          feiras: _feiras.toList(),
        ),
      );
      if (mounted) avisar(context, 'Banca salva!');
      widget.onSalvo();
    } catch (e) {
      if (mounted) avisar(context, 'Não deu para salvar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _obrigatorio(String? v) =>
      (v ?? '').trim().isEmpty ? 'Preencha este campo' : null;

  @override
  Widget build(BuildContext context) {
    final corpo = Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Largura(
            max: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.primeiraVez) ...[
                  Text(
                    'Bem-vindo ao Nosso Quintal!',
                    style: GoogleFonts.lora(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Conte um pouco da sua banca. Isso aparece para os clientes.',
                    style: TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome da banca',
                    hintText: 'Ex.: Sítio Boa Vista',
                  ),
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _feirante,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Como os clientes te chamam',
                    hintText: 'Ex.: Dona Maria',
                  ),
                  validator: _obrigatorio,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp da banca',
                    hintText: '(42) 99999-9999',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                      ? 'Coloque o DDD e o número'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _origem,
                  decoration: const InputDecoration(
                    labelText: 'De onde vêm seus produtos',
                    hintText:
                        'Ex.: Linha São Pedro, interior de União da Vitória',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descricao,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Sua história (opcional)',
                    hintText:
                        'Ex.: Plantamos sem veneno há 20 anos, eu e meus filhos.',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Em quais feiras você está?',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FutureBuilder<List<Feira>>(
                  future: _todasFeiras,
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator();
                    return Column(
                      children: [
                        for (final f in snap.data!)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _feiras.contains(f.id),
                            onChanged: (v) => setState(
                              () =>
                                  v! ? _feiras.add(f.id) : _feiras.remove(f.id),
                            ),
                            title: Text(
                              f.nome,
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle: Text(
                              '${nomesDiaSemana[f.diaSemana]} · ${f.horario} · ${f.local}',
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: Text(
                    widget.primeiraVez ? 'Criar minha banca' : 'Salvar',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (widget.embutido) return corpo;
    return Scaffold(
      appBar: AppBar(title: const Text('Sua banca')),
      body: corpo,
    );
  }
}

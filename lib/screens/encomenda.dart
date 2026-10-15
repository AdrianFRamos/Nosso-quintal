import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/repo.dart';
import 'package:nosso_quintal/theme.dart';
import 'package:nosso_quintal/widgets.dart';

// Cliente não precisa de conta: nome + WhatsApp bastam.
// A encomenda fica salva para o feirante e vai também pelo WhatsApp.
class EncomendaScreen extends StatefulWidget {
  final Banca banca;
  final List<ItemEncomenda> itens;
  final List<Feira> feiras;
  const EncomendaScreen({
    super.key,
    required this.banca,
    required this.itens,
    required this.feiras,
  });

  @override
  State<EncomendaScreen> createState() => _EncomendaScreenState();
}

class _EncomendaScreenState extends State<EncomendaScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _obs = TextEditingController();
  String? _feira;
  bool _enviando = false;
  String? _mensagemEnviada; // depois de salvar, guarda o texto para o WhatsApp

  @override
  void initState() {
    super.initState();
    if (widget.feiras.isNotEmpty) _feira = _rotuloFeira(widget.feiras.first);
  }

  String _rotuloFeira(Feira f) {
    final d = f.proximaData(DateTime.now());
    return '${f.nome} (${nomesDiaSemana[f.diaSemana]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')})';
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final feira = _feira ?? 'combinar com o feirante';
    try {
      await criarEncomenda(
        banca: widget.banca,
        clienteNome: _nome.text.trim(),
        clienteTelefone: _telefone.text.trim(),
        feiraNome: feira,
        observacao: _obs.text.trim(),
        itens: widget.itens,
      );
      setState(() {
        _mensagemEnviada = mensagemEncomenda(
          banca: widget.banca,
          cliente: _nome.text.trim(),
          feira: feira,
          itens: widget.itens,
          observacao: _obs.text,
        );
      });
    } catch (e) {
      if (mounted) {
        avisar(
          context,
          'Não deu para enviar. Confira a internet e tente de novo.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sua encomenda')),
      body: _mensagemEnviada != null ? _enviada() : _formulario(),
    );
  }

  Widget _formulario() {
    final total = widget.itens.fold(0.0, (s, i) => s + i.subtotal);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Largura(
            max: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.banca.nome,
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final i in widget.itens)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  i.produto.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${quantidade(i.quantidade)} ${i.produto.unidade} de ${i.produto.nome}',
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                                Text(
                                  reais(i.subtotal),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              reais(total),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Cores.tomate,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Você paga na banca, na hora de retirar (Pix ou dinheiro).',
                          style: TextStyle(fontSize: 15, color: Cores.musgo),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Escreva seu nome' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Seu WhatsApp',
                    hintText: '(42) 99999-9999',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10
                      ? 'Coloque o DDD e o número'
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'Onde vai retirar?',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.feiras.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'O feirante vai combinar com você pelo WhatsApp.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                else
                  RadioGroup<String>(
                    groupValue: _feira,
                    onChanged: (v) => setState(() => _feira = v),
                    child: Column(
                      children: [
                        for (final f in widget.feiras)
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: _rotuloFeira(f),
                            title: Text(
                              _rotuloFeira(f),
                              style: const TextStyle(fontSize: 17),
                            ),
                            subtitle: Text('${f.local} · ${f.horario}'),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _obs,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Recado para o feirante (opcional)',
                    hintText: 'Ex.: alface bem verdinha, chego às 9h',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Enviar encomenda'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enviada() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Largura(
          max: 560,
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 88,
                color: Cores.musgo,
              ),
              const SizedBox(height: 12),
              Text(
                'Encomenda enviada!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.banca.feirante.isNotEmpty ? widget.banca.feirante : 'O feirante'} já pode ver no app. '
                'Para garantir, mande também pelo WhatsApp:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (widget.banca.whatsapp.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: BotaoWhatsapp(
                    rotulo: 'Mandar no WhatsApp',
                    onPressed: () =>
                        abrirWhatsapp(widget.banca.whatsapp, _mensagemEnviada!),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Voltar para a feira'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

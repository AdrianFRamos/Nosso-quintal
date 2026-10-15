import 'package:flutter_test/flutter_test.dart';
import 'package:nosso_quintal/models.dart';

Feira feira(int dia) => Feira(id: 'f', nome: 'Feira', local: 'Centro', diaSemana: dia, horario: '7h');

void main() {
  test('reais e quantidade no padrão brasileiro', () {
    expect(reais(5), 'R\$ 5,00');
    expect(reais(1234.5), 'R\$ 1.234,50');
    expect(quantidade(2), '2');
    expect(quantidade(1.5), '1,5');
    expect(lerPreco('4,50'), 4.5);
    expect(lerPreco('4.50'), 4.5);
    expect(lerPreco('1.200,00'), 1200);
  });

  test('próxima feira cai no dia da semana certo', () {
    final quarta = DateTime(2026, 10, 14); // quarta-feira
    expect(feira(3).proximaData(quarta), DateTime(2026, 10, 14)); // hoje é dia de feira
    expect(feira(6).proximaData(quarta), DateTime(2026, 10, 17)); // sábado
    expect(feira(1).proximaData(quarta), DateTime(2026, 10, 19)); // segunda seguinte
  });

  test('telefone vira número do WhatsApp com 55', () {
    expect(telefoneWhatsapp('(42) 99876-5432'), '5542998765432');
    expect(telefoneWhatsapp('+55 42 99876-5432'), '5542998765432');
  });

  test('mensagem da encomenda lista itens e total', () {
    final banca = Banca(id: 'b', nome: 'Sítio Boa Vista', feirante: 'Dona Maria', descricao: '', origem: '', whatsapp: '', feiras: []);
    Produto p(String nome, double preco, String un) => Produto(
        bancaId: 'b', bancaNome: 'Sítio', nome: nome, categoria: 'Verduras', emoji: '🥬', preco: preco, unidade: un);
    final msg = mensagemEncomenda(
      banca: banca,
      cliente: 'Ana',
      feira: 'Feira do Produtor',
      itens: [ItemEncomenda(p('Alface', 3, 'unidade'), 2), ItemEncomenda(p('Tomate', 8, 'kg'), 1.5)],
    );
    expect(msg, contains('Olá, Dona Maria! Sou Ana'));
    expect(msg, contains('• 2 unidade de Alface — R\$ 6,00'));
    expect(msg, contains('• 1,5 kg de Tomate — R\$ 12,00'));
    expect(msg, contains('Total: R\$ 18,00'));
    expect(msg, contains('Retiro na: Feira do Produtor'));
  });
}

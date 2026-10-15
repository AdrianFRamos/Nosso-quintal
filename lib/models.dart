import 'package:cloud_firestore/cloud_firestore.dart';

// Categorias da feira: (nome, emoji). O emoji também é a "foto" padrão do produto.
const categorias = <(String, String)>[
  ('Verduras', '🥬'),
  ('Frutas', '🍓'),
  ('Legumes', '🥕'),
  ('Ovos e laticínios', '🥚'),
  ('Mel e doces', '🍯'),
  ('Pães e quitutes', '🥖'),
  ('Temperos', '🌿'),
  ('Mudas e flores', '🌻'),
  ('Artesanato', '🧺'),
];

String emojiDaCategoria(String categoria) => categorias
    .firstWhere((c) => c.$1 == categoria, orElse: () => ('', '🧺'))
    .$2;

const unidades = [
  'kg',
  'unidade',
  'maço',
  'dúzia',
  'pote',
  'pacote',
  'bandeja',
  'litro',
];

// No kg dá para pedir de meio em meio quilo; o resto vai de 1 em 1.
double passoDaUnidade(String unidade) => unidade == 'kg' ? 0.5 : 1;

// 1234.5 -> "R$ 1.234,50"
String reais(double valor) {
  final partes = valor.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $inteiro,${partes[1]}';
}

// 1.0 -> "1", 1.5 -> "1,5"
String quantidade(double q) => q == q.roundToDouble()
    ? q.toInt().toString()
    : q.toString().replaceAll('.', ',');

// Aceita "12,50", "1.234,56" e "12.50".
double? lerPreco(String texto) {
  final t = texto.trim();
  return double.tryParse(
    t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t,
  );
}

// Só dígitos, com DDI 55 (para o link do WhatsApp).
String telefoneWhatsapp(String telefone) {
  final d = telefone.replaceAll(RegExp(r'\D'), '');
  return d.startsWith('55') && d.length >= 12 ? d : '55$d';
}

class Feira {
  final String id;
  final String nome;
  final String local;
  final int
  diaSemana; // 1 = segunda ... 7 = domingo (igual ao DateTime.weekday)
  final String horario;

  Feira({
    required this.id,
    required this.nome,
    required this.local,
    required this.diaSemana,
    required this.horario,
  });

  factory Feira.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Feira(
      id: d.id,
      nome: m['nome'] ?? '',
      local: m['local'] ?? '',
      diaSemana: (m['diaSemana'] as num?)?.toInt() ?? 6,
      horario: m['horario'] ?? '',
    );
  }

  // Próximo dia de feira a partir de hoje (hoje conta).
  DateTime proximaData(DateTime hoje) {
    final dia = DateTime(hoje.year, hoje.month, hoje.day);
    return dia.add(Duration(days: (diaSemana - dia.weekday + 7) % 7));
  }
}

const nomesDiaSemana = [
  '',
  'segunda',
  'terça',
  'quarta',
  'quinta',
  'sexta',
  'sábado',
  'domingo',
];

class Banca {
  final String id; // = uid do feirante
  final String nome; // "Sítio Boa Vista"
  final String feirante; // "Dona Maria"
  final String descricao;
  final String origem; // "Colônia Iguaçu, interior de União da Vitória"
  final String whatsapp;
  final List<String> feiras; // ids das feiras em que a banca está

  Banca({
    required this.id,
    required this.nome,
    required this.feirante,
    required this.descricao,
    required this.origem,
    required this.whatsapp,
    required this.feiras,
  });

  factory Banca.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Banca(
      id: d.id,
      nome: m['nome'] ?? '',
      feirante: m['feirante'] ?? '',
      descricao: m['descricao'] ?? '',
      origem: m['origem'] ?? '',
      whatsapp: m['whatsapp'] ?? '',
      feiras: List<String>.from(m['feiras'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'feirante': feirante,
    'descricao': descricao,
    'origem': origem,
    'whatsapp': whatsapp,
    'feiras': feiras,
  };
}

class Produto {
  final String id;
  final String bancaId;
  final String bancaNome;
  final String nome;
  final String categoria;
  final String emoji;
  final double preco;
  final String unidade;
  final bool disponivel; // "tem esta semana"
  final bool organico;

  Produto({
    this.id = '',
    required this.bancaId,
    required this.bancaNome,
    required this.nome,
    required this.categoria,
    required this.emoji,
    required this.preco,
    required this.unidade,
    this.disponivel = true,
    this.organico = false,
  });

  factory Produto.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final categoria = m['categoria'] ?? 'Verduras';
    return Produto(
      id: d.id,
      bancaId: m['bancaId'] ?? '',
      bancaNome: m['bancaNome'] ?? '',
      nome: m['nome'] ?? '',
      categoria: categoria,
      emoji: m['emoji'] ?? emojiDaCategoria(categoria),
      preco: (m['preco'] as num?)?.toDouble() ?? 0,
      unidade: m['unidade'] ?? 'unidade',
      disponivel: m['disponivel'] ?? true,
      organico: m['organico'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'bancaId': bancaId,
    'bancaNome': bancaNome,
    'nome': nome,
    'categoria': categoria,
    'emoji': emoji,
    'preco': preco,
    'unidade': unidade,
    'disponivel': disponivel,
    'organico': organico,
  };

  String get precoTexto => '${reais(preco)} / $unidade';
}

class ItemEncomenda {
  final Produto produto;
  final double quantidade;
  const ItemEncomenda(this.produto, this.quantidade);
  double get subtotal => produto.preco * quantidade;
}

const statusEncomenda = {
  'nova': 'Nova',
  'separada': 'Separada',
  'entregue': 'Entregue',
  'cancelada': 'Cancelada',
};

class Encomenda {
  final String id;
  final String bancaId;
  final String clienteNome;
  final String clienteTelefone;
  final String feiraNome;
  final String observacao;
  final List<Map<String, dynamic>> itens; // {nome, quantidade, unidade, preco}
  final double total;
  final String status;
  final DateTime? criadaEm;

  Encomenda({
    required this.id,
    required this.bancaId,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.feiraNome,
    required this.observacao,
    required this.itens,
    required this.total,
    required this.status,
    this.criadaEm,
  });

  factory Encomenda.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Encomenda(
      id: d.id,
      bancaId: m['bancaId'] ?? '',
      clienteNome: m['clienteNome'] ?? '',
      clienteTelefone: m['clienteTelefone'] ?? '',
      feiraNome: m['feiraNome'] ?? '',
      observacao: m['observacao'] ?? '',
      itens: List<Map<String, dynamic>>.from(m['itens'] ?? const []),
      total: (m['total'] as num?)?.toDouble() ?? 0,
      status: m['status'] ?? 'nova',
      criadaEm: (m['criadaEm'] as Timestamp?)?.toDate(),
    );
  }
}

// Texto que vai pronto para o WhatsApp do feirante.
String mensagemEncomenda({
  required Banca banca,
  required String cliente,
  required String feira,
  required List<ItemEncomenda> itens,
  String observacao = '',
}) {
  final total = itens.fold(0.0, (s, i) => s + i.subtotal);
  final linhas = [
    'Olá, ${banca.feirante.isNotEmpty ? banca.feirante : banca.nome}! Sou $cliente e fiz uma encomenda pelo Nosso Quintal:',
    '',
    for (final i in itens)
      '• ${quantidade(i.quantidade)} ${i.produto.unidade} de ${i.produto.nome} — ${reais(i.subtotal)}',
    '',
    'Total: ${reais(total)}',
    'Retiro na: $feira',
    if (observacao.trim().isNotEmpty) 'Obs.: ${observacao.trim()}',
  ];
  return linhas.join('\n');
}

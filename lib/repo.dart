import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nosso_quintal/models.dart';

// Coleções:
//   feiras/{id}        cadastradas pela organização (console do Firebase)
//   bancas/{uid}       uma por feirante
//   produtos/{id}      bancaId = uid do feirante
//   encomendas/{id}    criadas por qualquer cliente, lidas só pelo feirante
final _db = FirebaseFirestore.instance;

String? get uidAtual => FirebaseAuth.instance.currentUser?.uid;

Future<List<Feira>> buscarFeiras() async {
  final snap = await _db.collection('feiras').get();
  return snap.docs.map(Feira.fromDoc).toList()
    ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));
}

Future<List<Banca>> buscarBancas() async {
  final snap = await _db.collection('bancas').get();
  return snap.docs.map(Banca.fromDoc).toList()
    ..sort((a, b) => a.nome.compareTo(b.nome));
}

Future<Banca?> buscarBanca(String id) async {
  final d = await _db.collection('bancas').doc(id).get();
  return d.exists ? Banca.fromDoc(d) : null;
}

Future<void> salvarBanca(Banca banca) async {
  await _db
      .collection('bancas')
      .doc(banca.id)
      .set(banca.toMap(), SetOptions(merge: true));
  // Mantém o nome da banca atualizado nos produtos (aparece na vitrine).
  final produtos = await _db
      .collection('produtos')
      .where('bancaId', isEqualTo: banca.id)
      .get();
  final lote = _db.batch();
  for (final p in produtos.docs) {
    lote.update(p.reference, {'bancaNome': banca.nome});
  }
  await lote.commit();
}

// Vitrine: tudo que tem na feira esta semana.
Future<List<Produto>> buscarProdutosDisponiveis() async {
  final snap = await _db
      .collection('produtos')
      .where('disponivel', isEqualTo: true)
      .get();
  return snap.docs.map(Produto.fromDoc).toList()
    ..sort((a, b) => a.nome.compareTo(b.nome));
}

Future<List<Produto>> buscarProdutosDaBanca(String bancaId) async {
  final snap = await _db
      .collection('produtos')
      .where('bancaId', isEqualTo: bancaId)
      .get();
  return snap.docs.map(Produto.fromDoc).toList()
    ..sort((a, b) => a.nome.compareTo(b.nome));
}

Future<void> salvarProduto(Produto p) async {
  final col = _db.collection('produtos');
  if (p.id.isEmpty) {
    await col.add({...p.toMap(), 'criadoEm': FieldValue.serverTimestamp()});
  } else {
    await col.doc(p.id).update(p.toMap());
  }
}

Future<void> marcarDisponivel(String produtoId, bool disponivel) => _db
    .collection('produtos')
    .doc(produtoId)
    .update({'disponivel': disponivel});

Future<void> excluirProduto(String produtoId) =>
    _db.collection('produtos').doc(produtoId).delete();

Future<void> criarEncomenda({
  required Banca banca,
  required String clienteNome,
  required String clienteTelefone,
  required String feiraNome,
  required String observacao,
  required List<ItemEncomenda> itens,
}) async {
  await _db.collection('encomendas').add({
    'bancaId': banca.id,
    'clienteNome': clienteNome,
    'clienteTelefone': clienteTelefone,
    'feiraNome': feiraNome,
    'observacao': observacao,
    'itens': [
      for (final i in itens)
        {
          'produtoId': i.produto.id,
          'nome': i.produto.nome,
          'quantidade': i.quantidade,
          'unidade': i.produto.unidade,
          'preco': i.produto.preco,
        },
    ],
    'total': itens.fold(0.0, (s, i) => s + i.subtotal),
    'status': 'nova',
    'criadaEm': FieldValue.serverTimestamp(),
  });
}

// ponytail: ordena no app para não precisar de índice composto; troque por orderBy + índice se passar de centenas.
Future<List<Encomenda>> buscarEncomendas(String bancaId) async {
  final snap = await _db
      .collection('encomendas')
      .where('bancaId', isEqualTo: bancaId)
      .get();
  final lista = snap.docs.map(Encomenda.fromDoc).toList();
  lista.sort(
    (a, b) =>
        (b.criadaEm ?? DateTime(3000)).compareTo(a.criadaEm ?? DateTime(3000)),
  );
  return lista;
}

Future<void> mudarStatusEncomenda(String id, String status) =>
    _db.collection('encomendas').doc(id).update({'status': status});

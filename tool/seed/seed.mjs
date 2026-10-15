// Popula o Firestore do Nosso Quintal com feiras, bancas e produtos de EXEMPLO.
//
//   cd tool/seed
//   npm install
//   node seed.mjs           -> cria/atualiza os dados de exemplo
//   node seed.mjs --limpar  -> apaga tudo que foi criado por este script
//
// Credencial: Console do Firebase > Configurações do projeto > Contas de serviço >
// Gerar nova chave privada -> salve como tool/seed/service-account.json (no .gitignore).
//
// Tudo é fictício e marcado com seed: true. As bancas de exemplo NÃO têm WhatsApp
// (um número inventado poderia ser de alguém de verdade).
// As feiras são exemplos: troque nome, local e horário pelas feiras reais da cidade.

import { readFileSync } from 'node:fs';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const key = JSON.parse(readFileSync(new URL('./service-account.json', import.meta.url)));
initializeApp({ credential: cert(key) });
const db = getFirestore();

const feiras = [
  { id: 'feira-centro', nome: 'Feira do Produtor', local: 'Centro (exemplo)', diaSemana: 6, horario: '7h às 12h' },
  { id: 'feira-tarde', nome: 'Feira da Tarde', local: 'Bairro (exemplo)', diaSemana: 3, horario: '16h às 20h' },
];

const bancas = [
  {
    id: 'seed-boa-vista', nome: 'Sítio Boa Vista', feirante: 'Dona Cida', feiras: ['feira-centro', 'feira-tarde'],
    origem: 'Interior de União da Vitória',
    descricao: 'Verduras colhidas na sexta à tarde, direto da horta para a banca. Plantamos com a família há 25 anos.',
  },
  {
    id: 'seed-recanto', nome: 'Chácara Recanto Verde', feirante: 'Seu Jair e Dona Lurdes', feiras: ['feira-centro'],
    origem: 'Interior de União da Vitória',
    descricao: 'Frutas da estação, ovos caipira e queijo colonial feito em casa.',
  },
  {
    id: 'seed-apiario', nome: 'Apiário Flor do Campo', feirante: 'Marcos', feiras: ['feira-centro', 'feira-tarde'],
    origem: 'Interior de União da Vitória',
    descricao: 'Mel puro de flores silvestres, própolis e cera. Pode provar na banca!',
  },
  {
    id: 'seed-nona', nome: 'Quitutes da Nona', feirante: 'Dona Ivone', feiras: ['feira-centro'],
    origem: 'Centro de União da Vitória',
    descricao: 'Pão caseiro, cuca e bolachas de receita de família, assados no forno a lenha.',
  },
  {
    id: 'seed-tres-irmas', nome: 'Horta Três Irmãs', feirante: 'Rosane, Rita e Regina', feiras: ['feira-tarde'],
    origem: 'Interior de União da Vitória',
    descricao: 'Horta orgânica, sem veneno. Temperos, mudas e flores.',
  },
];

// [banca, nome, categoria, emoji, preço, unidade, orgânico, tem esta semana]
const produtos = [
  ['seed-boa-vista', 'Alface crespa', 'Verduras', '🥬', 3.0, 'unidade', false, true],
  ['seed-boa-vista', 'Couve manteiga', 'Verduras', '🥬', 4.0, 'maço', false, true],
  ['seed-boa-vista', 'Tomate', 'Legumes', '🍅', 8.0, 'kg', false, true],
  ['seed-boa-vista', 'Cenoura', 'Legumes', '🥕', 6.0, 'kg', false, true],
  ['seed-boa-vista', 'Batata-doce', 'Legumes', '🍠', 7.0, 'kg', false, false],
  ['seed-recanto', 'Morango', 'Frutas', '🍓', 12.0, 'bandeja', false, true],
  ['seed-recanto', 'Ovos caipira', 'Ovos e laticínios', '🥚', 14.0, 'dúzia', false, true],
  ['seed-recanto', 'Queijo colonial', 'Ovos e laticínios', '🧀', 45.0, 'kg', false, true],
  ['seed-recanto', 'Laranja', 'Frutas', '🍊', 5.0, 'kg', false, true],
  ['seed-apiario', 'Mel silvestre', 'Mel e doces', '🍯', 35.0, 'pote', false, true],
  ['seed-apiario', 'Própolis', 'Mel e doces', '🫙', 25.0, 'unidade', false, true],
  ['seed-nona', 'Pão caseiro', 'Pães e quitutes', '🍞', 15.0, 'unidade', false, true],
  ['seed-nona', 'Cuca de banana', 'Pães e quitutes', '🥧', 22.0, 'unidade', false, true],
  ['seed-nona', 'Bolacha caseira', 'Pães e quitutes', '🍪', 18.0, 'pacote', false, true],
  ['seed-tres-irmas', 'Cheiro-verde', 'Temperos', '🌿', 3.0, 'maço', true, true],
  ['seed-tres-irmas', 'Rúcula', 'Verduras', '🥬', 4.5, 'maço', true, true],
  ['seed-tres-irmas', 'Muda de tempero', 'Mudas e flores', '🌱', 5.0, 'unidade', true, true],
  ['seed-tres-irmas', 'Girassol', 'Mudas e flores', '🌻', 10.0, 'maço', true, true],
];

async function limpar() {
  for (const col of ['produtos', 'bancas', 'feiras']) {
    const snap = await db.collection(col).where('seed', '==', true).get();
    const lote = db.batch();
    snap.docs.forEach((d) => lote.delete(d.ref));
    await lote.commit();
    console.log(`${col}: ${snap.size} apagado(s)`);
  }
}

async function popular() {
  const lote = db.batch();
  for (const { id, ...f } of feiras) lote.set(db.collection('feiras').doc(id), { ...f, seed: true });
  for (const { id, ...b } of bancas) lote.set(db.collection('bancas').doc(id), { ...b, whatsapp: '', seed: true });
  produtos.forEach(([bancaId, nome, categoria, emoji, preco, unidade, organico, disponivel], i) => {
    // id fixo: rodar de novo atualiza em vez de duplicar
    lote.set(db.collection('produtos').doc(`seed-produto-${i + 1}`), {
      bancaId,
      bancaNome: bancas.find((b) => b.id === bancaId).nome,
      nome, categoria, emoji, preco, unidade, organico, disponivel,
      criadoEm: FieldValue.serverTimestamp(),
      seed: true,
    });
  });
  await lote.commit();
  console.log(`${feiras.length} feiras, ${bancas.length} bancas e ${produtos.length} produtos gravados.`);
}

await (process.argv.includes('--limpar') ? limpar() : popular());

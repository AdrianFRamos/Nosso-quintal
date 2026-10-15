# Nosso Quintal

As bancas da feira de União da Vitória (PR) na palma da mão: o cliente vê o que tem na feira da
semana e encomenda para retirar na banca; o feirante cuida dos produtos e das encomendas.

Site: https://nosso-quintal-uv.web.app

## Como funciona

- **Cliente (sem conta):** vitrine com a próxima feira, busca e categorias → página da banca →
  escolhe as quantidades → encomenda com nome + WhatsApp → mensagem pronta para o WhatsApp do feirante.
  O pagamento é na banca.
- **Feirante (com conta):** cadastra a banca, liga/desliga "tem esta semana" em cada produto
  e acompanha as encomendas (nova → separada → entregue).

## Tecnologia

Flutter (web e Android) + Firebase (Auth, Firestore, Hosting). Projeto Firebase: `nosso-quintal-uv`.

```
lib/
  models.dart      modelos, categorias, formatação de preço, mensagem do WhatsApp
  repo.dart        acesso ao Firestore
  theme.dart       cores e fontes (tiradas da logo)
  widgets.dart     componentes comuns
  screens/         telas (início, banca, encomenda, entrar, painel, formulários)
firestore.rules    regras de segurança
tool/seed/         script que cria feiras, bancas e produtos de exemplo
```

## Rodar e publicar

```bash
flutter test
flutter run -d chrome
flutter build web && firebase deploy --only hosting
firebase deploy --only firestore   # regras
```

## Dados de exemplo

```bash
cd tool/seed && npm install
node seed.mjs           # cria
node seed.mjs --limpar  # apaga
```

Precisa de `tool/seed/service-account.json` (Console do Firebase → Configurações → Contas de serviço).
Esse arquivo está no `.gitignore` e **nunca** deve ir para o repositório.

As feiras ficam na coleção `feiras` (nome, local, diaSemana 1–7, horário) e são editadas pelo console do Firebase.

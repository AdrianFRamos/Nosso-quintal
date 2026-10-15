import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nosso_quintal/models.dart';
import 'package:nosso_quintal/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class Logo extends StatelessWidget {
  final double altura;
  const Logo({super.key, this.altura = 120});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/logo.png',
    height: altura,
    semanticLabel: 'Nosso Quintal',
  );
}

// "Foto" do produto: emoji grande num quadro de papel, no traço da logo.
class EmojiProduto extends StatelessWidget {
  final String emoji;
  final double tamanho;
  const EmojiProduto(this.emoji, {super.key, this.tamanho = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho * 1.6,
      height: tamanho * 1.6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Cores.papelEscuro,
        borderRadius: BorderRadius.circular(tamanho * 0.4),
      ),
      child: Text(emoji, style: TextStyle(fontSize: tamanho)),
    );
  }
}

class SeloOrganico extends StatelessWidget {
  const SeloOrganico({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Cores.colheita.withValues(alpha: 0.2),
        border: Border.all(color: Cores.colheita, width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'orgânico',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7A5510),
        ),
      ),
    );
  }
}

class TituloSecao extends StatelessWidget {
  final String texto;
  final String? subtitulo;
  const TituloSecao(this.texto, {super.key, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: GoogleFonts.lora(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Cores.mata,
            ),
          ),
          if (subtitulo != null)
            Text(
              subtitulo!,
              style: const TextStyle(fontSize: 16, color: Cores.musgo),
            ),
        ],
      ),
    );
  }
}

// Abre o WhatsApp com a mensagem pronta (app no celular, web no computador).
Future<bool> abrirWhatsapp(String telefone, String mensagem) {
  final uri = Uri.https('wa.me', '/${telefoneWhatsapp(telefone)}', {
    'text': mensagem,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class BotaoWhatsapp extends StatelessWidget {
  final String rotulo;
  final VoidCallback? onPressed;
  const BotaoWhatsapp({super.key, required this.rotulo, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.chat),
      label: Text(rotulo),
      style: ElevatedButton.styleFrom(backgroundColor: Cores.whatsapp),
    );
  }
}

void avisar(BuildContext context, String mensagem) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(mensagem)));

// Centraliza o conteúdo no computador sem esticar.
class Largura extends StatelessWidget {
  final Widget child;
  final double max;
  const Largura({super.key, required this.child, this.max = 1000});

  @override
  // heightFactor: 1 -> não cresce na vertical (ex.: dentro da barra de baixo).
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      // ocupa a largura toda até o máximo, para títulos ficarem alinhados à esquerda
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

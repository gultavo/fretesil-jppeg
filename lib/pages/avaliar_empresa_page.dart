import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'avaliacao_form.dart';

/// Tela onde o motorista avalia a empresa após a entrega.
///
/// A estrutura visual vem de [AvaliacaoForm], compartilhada com
/// `AvaliarMotoristaPage`.
class AvaliarEmpresaPage extends StatelessWidget {
  final int cargaId;
  final String empresaNome;

  const AvaliarEmpresaPage({
    super.key,
    required this.cargaId,
    required this.empresaNome,
  });

  @override
  Widget build(BuildContext context) {
    return AvaliacaoForm(
      titulo: 'Avaliar empresa',
      avaliado: empresaNome,
      pergunta: 'Como foi carregar com esta empresa?',
      hintComentario: 'Conte como foi o carregamento, o pátio, a espera…',
      rotuloOpcaoA: 'Banheiro limpo',
      rotuloOpcaoB: 'Local seguro',
      onEnviar: ({
        required int nota,
        required String comentario,
        required bool opcaoA,
        required bool opcaoB,
      }) =>
          ApiService.avaliarEmpresa(
        cargaId: cargaId,
        nota: nota,
        comentario: comentario,
        temBanheiroLimpo: opcaoA,
        localSeguro: opcaoB,
      ),
    );
  }
}

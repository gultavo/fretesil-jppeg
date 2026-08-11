import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'avaliacao_form.dart';

/// Tela onde a empresa avalia o motorista após a entrega.
///
/// A estrutura visual vem de [AvaliacaoForm], compartilhada com
/// `AvaliarEmpresaPage`.
class AvaliarMotoristaPage extends StatelessWidget {
  final int cargaId;
  final int caminhoneiroId;
  final String caminhoneiroNome;

  const AvaliarMotoristaPage({
    super.key,
    required this.cargaId,
    required this.caminhoneiroId,
    required this.caminhoneiroNome,
  });

  @override
  Widget build(BuildContext context) {
    return AvaliacaoForm(
      titulo: 'Avaliar motorista',
      avaliado: caminhoneiroNome,
      pergunta: 'Como foi a entrega?',
      hintComentario: 'Conte como foi trabalhar com este motorista…',
      rotuloOpcaoA: 'Entregou no prazo',
      rotuloOpcaoB: 'Cuidou bem da carga',
      onEnviar: ({
        required int nota,
        required String comentario,
        required bool opcaoA,
        required bool opcaoB,
      }) =>
          ApiService.avaliarMotorista(
        caminhoneiroId: caminhoneiroId,
        cargaId: cargaId,
        nota: nota,
        comentario: comentario,
        entregaNoPrazo: opcaoA,
        cuidadoComCarga: opcaoB,
      ),
    );
  }
}

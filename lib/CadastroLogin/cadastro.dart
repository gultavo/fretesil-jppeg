import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaginaCadastro extends StatefulWidget {
  const PaginaCadastro({super.key});

  @override
  State<PaginaCadastro> createState() => _PaginaCadastroState();
}

class _PaginaCadastroState extends State<PaginaCadastro> {
  String _tipoSelecionado = 'empresa';
  bool _carregando = false;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _cpfController = TextEditingController();
  final _placaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cnpjController.dispose();
    _cpfController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _carregando = true);

    try {
      late Map<String, dynamic> resultado;

      if (_tipoSelecionado == 'empresa') {
        resultado = await ApiService.cadastrarEmpresa({
          'razao_social': _nomeController.text.trim(),
          'cnpj': _cnpjController.text.trim().replaceAll(RegExp(r'\D'), ''),
          'email': _emailController.text.trim(),
          'senha': _senhaController.text,
        });
      } else {
        resultado = await ApiService.cadastrarCaminhoneiro({
          'nome_completo': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim().replaceAll(RegExp(r'\D'), ''),
          'placa_veiculo': _placaController.text.trim().toUpperCase(),
          'email': _emailController.text.trim(),
          'senha': _senhaController.text,
        });
      }

      if (!mounted) return;

      if (resultado['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado! Faça login para continuar.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final erros = resultado['body'] as Map<String, dynamic>;
        final mensagem = erros.values
            .map((v) => v is List ? v.join(', ') : v.toString())
            .join('\n');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro de conexão. Servidor: ${ApiService.baseUrl}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Criar conta'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const SizedBox(height: 8),
            Text(
              'Cadastre-se!',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Preencha os dados abaixo para começar.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),

            Text('Tipo de conta',
                style: textTheme.labelLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'empresa',
                  label: Text('Empresa'),
                  icon: Icon(Icons.business_outlined),
                ),
                ButtonSegment(
                  value: 'freteiro',
                  label: Text('Freteiro'),
                  icon: Icon(Icons.local_shipping_outlined),
                ),
              ],
              selected: {_tipoSelecionado},
              onSelectionChanged: (s) =>
                  setState(() => _tipoSelecionado = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: colorScheme.primaryContainer,
                selectedForegroundColor: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Card dados principais
            _buildCard(
              title: _tipoSelecionado == 'empresa'
                  ? 'Dados da empresa'
                  : 'Dados do freteiro',
              children: [
                TextFormField(
                  controller: _nomeController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  decoration: InputDecoration(
                    labelText: _tipoSelecionado == 'empresa'
                        ? 'Razão Social'
                        : 'Nome completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                ),
                const SizedBox(height: 12),
                if (_tipoSelecionado == 'empresa') ...[
                  TextFormField(
                    controller: _cnpjController,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o CNPJ' : null,
                    decoration: InputDecoration(
                      labelText: 'CNPJ (somente números)',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                    decoration: InputDecoration(
                      labelText: 'CPF (somente números)',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _placaController,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a placa' : null,
                    decoration: InputDecoration(
                      labelText: 'Placa do veículo',
                      prefixIcon:
                          const Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Card dados de acesso
            _buildCard(
              title: 'Dados de acesso',
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senhaController,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Senha deve ter ao menos 6 caracteres'
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            FilledButton(
              onPressed: _carregando ? null : _cadastrar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _carregando
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Criar conta',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Já tem uma conta? ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

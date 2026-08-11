import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class PaginaCadastro extends StatefulWidget {
  const PaginaCadastro({super.key});

  @override
  State<PaginaCadastro> createState() => _PaginaCadastroState();
}

class _PaginaCadastroState extends State<PaginaCadastro> {
  String _tipoSelecionado = 'empresa';
  bool _carregando = false;
  bool _senhaVisivel = false;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _cpfController = TextEditingController();
  final _placaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _ehEmpresa => _tipoSelecionado == 'empresa';

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
      final resultado = _ehEmpresa
          ? await ApiService.cadastrarEmpresa({
              'razao_social': _nomeController.text.trim(),
              'cnpj':
                  _cnpjController.text.trim().replaceAll(RegExp(r'\D'), ''),
              'email': _emailController.text.trim(),
              'senha': _senhaController.text,
            })
          : await ApiService.cadastrarCaminhoneiro({
              'nome_completo': _nomeController.text.trim(),
              'cpf': _cpfController.text.trim().replaceAll(RegExp(r'\D'), ''),
              'placa_veiculo': _placaController.text.trim().toUpperCase(),
              'email': _emailController.text.trim(),
              'senha': _senhaController.text,
            });

      if (!mounted) return;

      if (resultado['statusCode'] == 201) {
        AppSnack.success(context, 'Cadastro realizado! Faça login para continuar.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final erros = resultado['body'] as Map<String, dynamic>;
        final mensagem = erros.values
            .map((v) => v is List ? v.join(', ') : v.toString())
            .join('\n');
        AppSnack.error(context, mensagem);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(
        context,
        'Erro de conexão com o servidor (${ApiService.baseUrl}).',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: AppBody(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              const SizedBox(height: AppSpacing.sm),
              const AppPageIntro(
                title: 'Cadastre-se!',
                subtitle: 'Preencha os dados abaixo para começar.',
              ),
              const SizedBox(height: AppSpacing.xxl),

              const AppSectionHeader(
                label: 'Tipo de conta',
                icon: Icons.switch_account_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
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
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppSection(
                title: _ehEmpresa ? 'Dados da empresa' : 'Dados do freteiro',
                children: [
                  TextFormField(
                    controller: _nomeController,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                    decoration: InputDecoration(
                      labelText: _ehEmpresa ? 'Razão social' : 'Nome completo',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_ehEmpresa)
                    TextFormField(
                      controller: _cnpjController,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe o CNPJ' : null,
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        hintText: 'Somente números',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _cpfController,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        hintText: 'Somente números',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _placaController,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a placa' : null,
                      decoration: const InputDecoration(
                        labelText: 'Placa do veículo',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              AppSection(
                title: 'Dados de acesso',
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_senhaVisivel,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'A senha deve ter ao menos 6 caracteres'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip:
                            _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppPrimaryButton(
                label: 'Criar conta',
                loadingLabel: 'Criando…',
                icon: Icons.person_add_alt,
                loading: _carregando,
                onPressed: _cadastrar,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta?',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: AppCompactButton.text,
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

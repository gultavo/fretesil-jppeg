import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin> {
  String _tipoSelecionado = 'empresa';
  bool _carregando = false;
  bool _senhaVisivel = false;

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);

    try {
      final resultado = await ApiService.login(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );

      if (!mounted) return;

      if (resultado['statusCode'] == 200) {
        final data = resultado['body'] as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);

        final tipo = data['tipo_usuario'] as String;
        await prefs.setString('tipo_usuario', tipo);

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          tipo == 'empresa' ? '/homeEmpresa' : '/homeFreteiro',
          (route) => false,
        );
      } else {
        final body = resultado['body'];
        var mensagem = 'E-mail ou senha incorretos.';
        if (body is Map && body.containsKey('detail')) {
          mensagem = body['detail'].toString();
        }
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
      appBar: AppBar(title: const Text('Entrar')),
      body: AppBody(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              const SizedBox(height: AppSpacing.sm),
              const AppPageIntro(
                title: 'Entre na sua conta',
                subtitle: 'Preencha os dados abaixo para continuar.',
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
                    onFieldSubmitted: (_) => _carregando ? null : _login(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
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
                label: 'Entrar',
                loadingLabel: 'Entrando…',
                icon: Icons.login,
                loading: _carregando,
                onPressed: _login,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ainda não tem uma conta?',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/cadastro'),
                    style: AppCompactButton.text,
                    child: const Text('Cadastrar-se'),
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

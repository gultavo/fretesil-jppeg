import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'CadastroLogin/cadastro.dart';
import 'CadastroLogin/login.dart';
import 'home/home_empresa.dart';
import 'home/home_freteiro.dart';
import 'pages/nova_carga_page.dart';
import 'theme/app_theme.dart';

/// Raiz do aplicativo: tema, rotas e comportamento de rolagem.
///
/// Esta é a única definição do app — `main.dart` apenas a executa.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Toque fora de um campo fecha o teclado.
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Frete Sil',

        // Tema único do app. Para forçar um modo, troque [themeMode]
        // para ThemeMode.light ou ThemeMode.dark.
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,

        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const PaginaLogin(),
          '/cadastro': (context) => const PaginaCadastro(),
          '/homeEmpresa': (context) => const HomeEmpresa(),
          '/homeFreteiro': (context) => const HomeFreteiro(),
          '/novaCarga': (context) => const NovaCargaPage(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'CadastroLogin/cadastro.dart';
import 'CadastroLogin/login.dart';
import 'home/home_empresa.dart';
import 'home/home_freteiro.dart';
import 'pages/nova_carga_page.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Frete Sil',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const PaginaLogin(),
          '/cadastro': (context) => const PaginaCadastro(),
          '/homeEmpresa': (context) => const HomeEmpresa(),
          '/homeFreteiro': (context) => const HomeFreteiro(),
          '/novaCarga': (context) => const NovaCargaPage()
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_application_1/CadastroLogin/cadastro.dart';
import 'package:flutter_application_1/CadastroLogin/login.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        initialRoute: '/cadastro',
        routes: {
          '/cadastro': (context) => const PaginaCadastro(),
          '/login': (context) => const PaginaLogin(),
        },
      ),
    );
  }
}
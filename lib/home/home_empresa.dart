import 'package:flutter/material.dart';

class HomeEmpresa extends StatelessWidget {
  const HomeEmpresa({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Empresa'),
        elevation: 0,
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seção de Boas-vindas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie suas cargas e acompanhe seus fretes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botão de Cadastrar Carga
              ElevatedButton.icon(
                onPressed: () {
                  // Navegar para tela de cadastro de carga
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ir para cadastro de carga')),
                  );
                },
                icon: const Icon(Icons.add_circle),
                label: const Text('Cadastrar Nova Carga'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Seção de Minhas Cargas
              Text(
                'Minhas Cargas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Lista de Cargas (exemplo com dados estáticos)
              _buildCargaCard(
                context,
                origem: 'São Paulo - SP',
                destino: 'Rio de Janeiro - RJ',
                peso: '500 kg',
                status: 'Ativa',
                data: '15/01/2024',
              ),
              const SizedBox(height: 12),
              _buildCargaCard(
                context,
                origem: 'Belo Horizonte - MG',
                destino: 'Brasília - DF',
                peso: '1200 kg',
                status: 'Entregue',
                data: '10/01/2024',
              ),
              const SizedBox(height: 12),
              _buildCargaCard(
                context,
                origem: 'Curitiba - PR',
                destino: 'Porto Alegre - RS',
                peso: '800 kg',
                status: 'Ativa',
                data: '12/01/2024',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCargaCard(
    BuildContext context, {
    required String origem,
    required String destino,
    required String peso,
    required String status,
    required String data,
  }) {
    Color statusColor = status == 'Ativa' ? Colors.orange : Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$origem → $destino',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Peso: $peso',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Data: $data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ver detalhes da carga')),
                    );
                  },
                  child: const Text('Detalhes', style: TextStyle(color: Colors.indigo)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

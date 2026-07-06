# Este app cuida apenas do cadastro público (registro) de empresas e
# motoristas. Os modelos de verdade ficam em `usuario.models` — as views e
# serializers daqui reutilizam esses modelos. Antes existiam classes Empresa e
# Caminhoneiro duplicadas aqui, que criavam tabelas nunca usadas; foram removidas.

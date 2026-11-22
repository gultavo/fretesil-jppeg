# FreteSil

Plataforma de intermediação de fretes com API em Django REST Framework, banco PostgreSQL e aplicativo em Flutter. Empresas publicam cargas, caminhoneiros se candidatam, a empresa seleciona um motorista e a viagem é acompanhada até a entrega.

## Pré-requisitos

- Python 3.12 ou superior
- PostgreSQL 16, ou Docker Desktop
- Flutter 3.44 ou superior

## 1. Configurar o ambiente

Na raiz do projeto, copie o arquivo de exemplo:

```powershell
Copy-Item .env.example .env
```

Gere uma chave e coloque-a em `SECRET_KEY`. Depois escolha uma senha para `DB_PASSWORD`.

```powershell
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

A API não inicia sem `SECRET_KEY`, `DB_NAME`, `DB_USER` e `DB_PASSWORD`.

| Variável | Função |
| --- | --- |
| `DEBUG` | `True` em desenvolvimento. Com `False`, a API exige uma chave própria e não serve as fotos. |
| `ALLOWED_HOSTS` | Endereços aceitos pela API, separados por vírgula. Para celular físico, inclua o IP do computador. |
| `CORS_ALLOWED_ORIGINS` | Origens web permitidas quando `DEBUG=False`. |
| `PRECO_COMBUSTIVEL_PADRAO` | Preço do litro usado quando a carga não informa um valor próprio. |

## 2. Configurar o PostgreSQL

### Opção A: Docker (API e banco juntos)

```powershell
docker compose up --build
```

A API fica em `http://localhost:8000` e as migrações são aplicadas automaticamente. Os dados e as fotos ficam em volumes do Docker.

Se o volume do banco já existia, ele mantém a senha antiga. Use essa mesma senha em `DB_PASSWORD` ou altere-a no banco:

```powershell
docker compose exec db psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'nova_senha';"
```

### Opção B: PostgreSQL instalado

Crie o banco e mantenha `DB_HOST=localhost` e `DB_PORT=5432` no `.env`:

```sql
CREATE DATABASE fretesil;
```

## 3. Executar a API sem Docker

```powershell
cd backend/fretesil
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

## 4. Iniciar o aplicativo Flutter

Com a API em execução, na raiz do projeto:

```powershell
flutter pub get
flutter run
```

O app usa `localhost:8000` na web e no desktop, e `10.0.2.2:8000` no emulador Android. Para celular físico, altere `baseUrl` em `lib/services/api_service.dart` para o IP do computador e inclua esse IP em `ALLOWED_HOSTS`.

## Testes e demonstração

Na pasta `backend/fretesil`:

```powershell
python manage.py test
python manage.py demonstrar_fluxo
```

O segundo comando executa o fluxo completo pela API e desfaz tudo no final, sem deixar dados no banco.

## Fluxo de contratação

```text
disponivel → aguardando_aceite → acoplar_carreta → em_transito → finalizado
```

- Ao selecionar um candidato, os demais são recusados automaticamente.
- Se o motorista selecionado desistir, a carga volta a ficar disponível e os candidatos recusados automaticamente voltam a concorrer.
- Um motorista não pode ter duas viagens ativas, e etapas fora de ordem são bloqueadas.
- Seleções simultâneas são protegidas por bloqueio de linha no PostgreSQL.

## Cálculo do lucro estimado

```text
Lucro = valor bruto - comissão (0,2%) - pedágio - combustível
Combustível = (distância / consumo) x preço do litro
```

| Item | Valor |
| --- | ---: |
| Valor bruto | R$ 5.000,00 |
| Comissão (0,2%) | R$ 10,00 |
| Pedágio | R$ 200,00 |
| Combustível (700 km / 2,5 km/l = 280 L x R$ 6,00) | R$ 1.680,00 |
| **Total de despesas** | **R$ 1.890,00** |
| **Lucro estimado** | **R$ 3.110,00** |

O preço pode ser informado em cada carga. O consumo é cadastrado pelo motorista no perfil.

## Privacidade dos perfis

| Dado do motorista | Próprio motorista | Empresa com viagem ativa | Demais usuários |
| --- | :---: | :---: | :---: |
| Nome, foto, cidade, avaliações | Sim | Sim | Sim |
| Telefone e placa | Sim | Sim | Não |
| CPF e consumo | Sim | Não | Não |

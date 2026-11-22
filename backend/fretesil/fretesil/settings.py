import os
import dotenv
from decimal import Decimal, InvalidOperation
from pathlib import Path
from datetime import timedelta

from django.core.exceptions import ImproperlyConfigured

dotenv.load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent


def _obrigatoria(nome):
    """Lê uma variável de ambiente que não pode ter valor predefinido no código."""
    valor = os.getenv(nome, '').strip()
    if not valor:
        raise ImproperlyConfigured(
            f'Defina a variável de ambiente {nome} (veja o .env.example).'
        )
    return valor


def _lista(nome, padrao=''):
    return [v.strip() for v in os.getenv(nome, padrao).split(',') if v.strip()]


DEBUG = os.getenv('DEBUG', 'False').strip().lower() == 'true'

SECRET_KEY = _obrigatoria('SECRET_KEY')
if not DEBUG and SECRET_KEY.startswith(('django-insecure', 'troque')):
    raise ImproperlyConfigured('Use uma SECRET_KEY própria quando DEBUG=False.')

# 10.0.2.2 é o endereço do computador visto pelo emulador Android.
ALLOWED_HOSTS = _lista('ALLOWED_HOSTS', 'localhost,127.0.0.1,10.0.2.2')

# Preço usado nas cargas publicadas sem um valor próprio de combustível.
try:
    PRECO_COMBUSTIVEL_PADRAO = Decimal(os.getenv('PRECO_COMBUSTIVEL_PADRAO', '6.00'))
except InvalidOperation as exc:
    raise ImproperlyConfigured('PRECO_COMBUSTIVEL_PADRAO deve ser um número.') from exc
if not PRECO_COMBUSTIVEL_PADRAO.is_finite() or PRECO_COMBUSTIVEL_PADRAO <= 0:
    raise ImproperlyConfigured('PRECO_COMBUSTIVEL_PADRAO deve ser maior que zero.')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Pacotes
    'rest_framework',
    'corsheaders',
    # Apps do projeto
    'cadastro_usuario',
    'usuario',
    'avaliacao',
    'cargas',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # DEVE ser o primeiro
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'fretesil.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'fretesil.wsgi.application'

DB_ENGINE = os.getenv('DB_ENGINE') or 'django.db.backends.postgresql'

if DB_ENGINE == 'django.db.backends.postgresql':
    DATABASES = {
        'default': {
            'ENGINE': DB_ENGINE,
            'NAME': _obrigatoria('DB_NAME'),
            'USER': _obrigatoria('DB_USER'),
            'PASSWORD': _obrigatoria('DB_PASSWORD'),
            'HOST': os.getenv('DB_HOST') or 'localhost',
            'PORT': os.getenv('DB_PORT') or '5432',
        }
    }
else:
    DATABASES = {'default': {'ENGINE': DB_ENGINE, 'NAME': _obrigatoria('DB_NAME')}}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Uploads (fotos de perfil, cargas, logos)
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Django REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    # Rotas públicas (login e cadastro) declaram AllowAny explicitamente.
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_RENDERER_CLASSES': (
        ('rest_framework.renderers.JSONRenderer',
         'rest_framework.renderers.BrowsableAPIRenderer')
        if DEBUG else ('rest_framework.renderers.JSONRenderer',)
    ),
}

# JWT
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
}

# CORS
CORS_ALLOW_ALL_ORIGINS = DEBUG  # Flutter Web usa uma porta aleatória em desenvolvimento
CORS_ALLOWED_ORIGINS = _lista('CORS_ALLOWED_ORIGINS')
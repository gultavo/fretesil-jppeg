# Backend Django - FreteSil
FROM python:3.12-slim

# Configuracoes do Python no container
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Dependencias de sistema (psycopg precisa de libpq)
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Instala as dependencias Python primeiro (melhor cache de build)
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Copia o codigo do projeto
COPY . .

# Usuario sem privilegios
RUN useradd --create-home appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Coleta estaticos, aplica migracoes e sobe o gunicorn
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py collectstatic --noinput && gunicorn fretesil.wsgi:application --bind 0.0.0.0:8000"]

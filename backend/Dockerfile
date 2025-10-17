# Utiliser une image Python officielle comme base
FROM python:3.12.10-slim as base

# Définir les variables d'environnement
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Installer les dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installer Poetry
RUN pip install poetry==1.8.3

# Configurer Poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de configuration de Poetry
COPY pyproject.toml ./
COPY poetry.lock ./

# Installer les dépendances
RUN poetry install --only=main && rm -rf $POETRY_CACHE_DIR

# Stage de production
FROM python:3.12.10-slim as production

# Installer les dépendances système minimales
RUN apt-get update && apt-get install -y \
    libjpeg-dev \
    zlib1g-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur non-root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Définir le répertoire de travail
WORKDIR /app

# Copier l'environnement virtuel depuis le stage précédent
COPY --from=base /app/.venv /app/.venv

# Copier le code de l'application
COPY . .

# Créer le répertoire pour les logs
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

# Changer vers l'utilisateur non-root
USER appuser

# Exposer le port
EXPOSE 8000

# Variables d'environnement
ENV PATH="/app/.venv/bin:$PATH"

# Commande de démarrage (uvicorn est déjà dans le venv)
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]

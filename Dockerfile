# Utiliser une version spécifique d'Alpine pour la reproductibilité
FROM alpine:latest

# Installer les dépendances système nécessaires
RUN apk add --no-cache --update \
    python3 \
    py3-pip \
    bash \
    python3-dev \
    libffi-dev \
    gcc \
    musl-dev \
    libffi-dev

# Créer l'environnement virtuel avant d'installer les dépendances
RUN python3 -m venv /opt/venv

# Configurer le PATH pour l'environnement virtuel
ENV PATH="/opt/venv/bin:$PATH"

# Installer pip et setuptools à jour dans l'environnement virtuel
RUN pip install --no-cache-dir --upgrade pip setuptools

# Copier le fichier requirements séparément pour optimiser le cache
COPY ./webapp/requirements.txt /tmp/requirements.txt

# Installer les dépendances Python dans l'environnement virtuel
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Ajouter le code de l'application
COPY ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Créer un utilisateur non-root avec un répertoire personnel
RUN adduser -D -h /home/myuser -s /bin/sh myuser && \
    chown -R myuser:myuser /opt/webapp

# Basculer vers l'utilisateur non-root
USER myuser

# Configurer la variable d'environnement PORT avec une valeur par défaut
ENV PORT=8000

# Commande d'exécution avec paramètre configurable
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} wsgi"]

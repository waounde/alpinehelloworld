# Utiliser l'image Alpine la plus récente
FROM alpine:latest

# Installer Python, pip, bash, et les outils nécessaires pour créer un environnement virtuel
RUN apk add --no-cache --update python3 py3-pip bash python3-dev libffi-dev

# Installer virtualenv pour gérer les environnements virtuels
RUN pip3 install --no-cache-dir virtualenv

# Créer un environnement virtuel dans /opt/venv
RUN python3 -m venv /opt/venv

# Modifier le PATH pour que l'environnement virtuel soit activé par défaut
ENV PATH="/opt/venv/bin:$PATH"

# Ajouter le fichier requirements.txt dans le conteneur
ADD ./webapp/requirements.txt /tmp/requirements.txt

# Installer les dépendances dans l'environnement virtuel
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Ajouter le code de l'application
ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Créer un utilisateur non-root pour des raisons de sécurité
RUN adduser -D myuser
USER myuser

# Exécuter l'application. Le port sera défini par Heroku.
CMD gunicorn --bind 0.0.0.0:$PORT wsgi

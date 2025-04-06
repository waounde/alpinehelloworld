# Utiliser l'image Alpine la plus récente
FROM alpine:latest

# Installer Python, pip et bash
RUN apk add --no-cache --update python3 py3-pip bash python3-dev libffi-dev

# Installer virtualenv pour gérer les environnements virtuels
RUN pip3 install --no-cache-dir virtualenv

# Créer un environnement virtuel dans le dossier /opt/venv
RUN python3 -m venv /opt/venv

# Activer l'environnement virtuel en modifiant le PATH
ENV PATH="/opt/venv/bin:$PATH"

# Ajouter le fichier requirements.txt dans le container
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

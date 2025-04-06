# Grab the latest alpine image
FROM alpine:latest

# Install python and pip
RUN apk add --no-cache --update python3 py3-pip bash python3-dev libffi-dev

# Install virtualenv
RUN pip3 install --no-cache-dir virtualenv

# Create and activate a virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Add the requirements file to the container
ADD ./webapp/requirements.txt /tmp/requirements.txt

# Install dependencies in the virtual environment
RUN pip install --no-cache-dir -q -r /tmp/requirements.txt

# Add the application code
ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

# Create a non-root user for security
RUN adduser -D myuser
USER myuser

# Run the app. CMD is required to run on Heroku
# $PORT is set by Heroku
CMD gunicorn --bind 0.0.0.0:$PORT wsgi

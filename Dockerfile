# Grab the latest alpine image
FROM alpine:latest

# Install python and pip
RUN apk add --no-cache --update python3 py3-pip bash

# Add requirements file
ADD ./webapp/requirements.txt /tmp/requirements.txt

# Install dependencies
RUN pip3 install --no-cache-dir -q -r /tmp/requirements.txt

# Add the application code
ADD ./webapp /opt/webapp/

# Ensure correct permissions for non-root user
RUN chown -R myuser:myuser /opt/webapp

# Switch to non-root user
RUN adduser -D myuser
USER myuser

# Set working directory to the webapp folder
WORKDIR /opt/webapp

# CMD for Heroku, where $PORT is automatically set by the platform
CMD gunicorn --bind 0.0.0.0:$PORT wsgi

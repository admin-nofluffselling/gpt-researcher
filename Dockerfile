# Stage 1: Browser and build tools installation
FROM python:3.11.4-slim-bullseye AS install-browser

# Install Chromium, Chromedriver, Firefox, Geckodriver, and build tools in one layer
RUN apt-get update && \
    apt-get satisfy -y "chromium, chromium-driver (>= 115.0)" && \
    apt-get install -y --no-install-recommends firefox-esr wget build-essential curl supervisor && \
    wget https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz && \
    tar -xvzf geckodriver-v0.33.0-linux64.tar.gz && \
    chmod +x geckodriver && \
    mv geckodriver /usr/local/bin/ && \
    rm geckodriver-v0.33.0-linux64.tar.gz && \
    chromium --version && chromedriver --version && \
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    # Create supervisor directory
    mkdir -p /etc/supervisor/conf.d && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Build frontend
WORKDIR /usr/src/frontend
COPY frontend/nextjs/package*.json ./
RUN npm install --legacy-peer-deps

COPY frontend/nextjs/ ./
RUN npm run build

# Stage 3: Python dependencies installation
WORKDIR /usr/src/app

# Copy and install Python dependencies including LangGraph
COPY ./requirements.txt ./requirements.txt
COPY ./multi_agents/requirements.txt ./multi_agents/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r multi_agents/requirements.txt && \
    pip install langgraph-cli supervisor

# Stage 4: Final setup
# Create necessary directories and set permissions
RUN mkdir -p /usr/src/app/outputs /usr/src/app/logs && \
    chmod 777 /usr/src/app/outputs && \
    chmod 777 /usr/src/app/logs

# Copy the backend application
COPY . .

# Create supervisor configuration
RUN echo "[supervisord]\n\
nodaemon=true\n\
logfile=/dev/stdout\n\
logfile_maxbytes=0\n\
\n\
[program:backend]\n\
command=uvicorn main:app --host 0.0.0.0 --port 8000 --log-level debug\n\
directory=/usr/src/app\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
autorestart=true\n\
\n\
[program:frontend]\n\
command=npm run start\n\
directory=/usr/src/frontend\n\
environment=PORT=3000,NODE_ENV=production,NEXT_PUBLIC_API_URL=https://gpt-researcher-broken-violet-1285.fly.dev:8000\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
autorestart=true" > /etc/supervisor/conf.d/supervisord.conf

# Create a startup script to wait for ports to be available
RUN echo '#!/bin/bash\n\
\n\
# Wait for ports to be available\n\
timeout 30 bash -c "until nc -z localhost 3000; do sleep 1; done"\n\
timeout 30 bash -c "until nc -z localhost 8000; do sleep 1; done"\n\
\n\
exec "$@"' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose both ports
EXPOSE 3000 8000

# Use the entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
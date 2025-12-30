FROM n8nio/n8n:latest

USER root

# Install dependencies for cloudflared on Alpine
RUN apk add --no-cache curl libc6-compat

# Download and install the cloudflared binary
RUN curl -L --output /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# Create a start script to run n8n and the tunnel together
RUN echo '#!/bin/sh\n\
n8n start &\n\
cloudflared tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}' > /start.sh && chmod +x /start.sh

# Render expects the app on port 5678 (or whatever you set N8N_PORT to)
ENV N8N_PORT=5678
EXPOSE 5678

CMD ["/start.sh"]

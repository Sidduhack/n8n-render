# --- Stage 1: Download Cloudflare in a temporary builder ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
RUN chmod +x /cloudflared

# --- Stage 2: Final n8n image ---
FROM n8nio/n8n:latest

USER root

# Copy the pre-downloaded cloudflared binary from the builder stage
COPY --from=builder /cloudflared /usr/local/bin/cloudflared

# Create a start script to run both n8n and the tunnel
RUN echo '#!/bin/sh\n\
n8n start &\n\
cloudflared tunnel --no-autoupdate run --token ${TUNNEL_TOKEN}' > /start.sh && chmod +x /start.sh

# Set permissions for the n8n user
RUN chown node:node /start.sh
USER node

# Render configuration
ENV N8N_PORT=5678
EXPOSE 5678

CMD ["/bin/sh", "/start.sh"]

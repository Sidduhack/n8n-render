# --- Stage 1: Download Cloudflare ---
FROM alpine:latest AS builder
RUN apk add --no-cache curl
RUN curl -L --output /cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
RUN chmod +x /cloudflared

# --- Stage 2: Final n8n image ---
FROM n8nio/n8n:latest

USER root

# Copy cloudflared from builder
COPY --from=builder /cloudflared /usr/local/bin/cloudflared

# Create the start script using printf (more reliable than echo for newlines)
RUN printf "#!/bin/sh\n\
n8n start &\n\
sleep 5\n\
cloudflared tunnel --no-autoupdate run --token \${TUNNEL_TOKEN}\n" > /start.sh \
    && chmod +x /start.sh \
    && chown node:node /start.sh

# Reset the Entrypoint so n8n doesn't try to "eat" our command
ENTRYPOINT []

# Switch to node user for security
USER node

# n8n port
ENV N8N_PORT=5678
EXPOSE 5678

# Run the script using sh
CMD ["sh", "/start.sh"]

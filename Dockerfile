# --- Stage 2: Final image ---
FROM n8nio/n8n:latest
USER root

# ADD THIS LINE TO INSTALL CURL PERMANENTLY:
RUN apk add --no-cache curl

COPY --from=builder /cloudflared /usr/local/bin/cloudflared
# ... (rest of the file stays the same)

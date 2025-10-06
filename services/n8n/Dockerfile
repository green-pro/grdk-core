FROM n8nio/n8n:1.112.5
USER node
WORKDIR /home/node/.n8n/nodes
RUN test -f package.json || npm init -y \
    && npm install --save --omit=dev \
    n8n-nodes-document-generator@1.0.10 \
    n8n-nodes-text-manipulation@1.4.0
WORKDIR /home/node/.n8n

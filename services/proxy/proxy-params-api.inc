proxy_redirect     off;
proxy_set_header   X-Real-IP $remote_addr;
proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header   X-Forwarded-Host $server_name;
proxy_set_header   X-Forwarded-Proto $scheme;
proxy_set_header   X-Scheme $scheme;

# Configurações necessárias para o upstream keepalive funcionar
proxy_http_version 1.1;
proxy_set_header Connection "";

# Configuração de Buffers (Crucial para performance)
proxy_buffering on;
proxy_buffers 32 16k;
proxy_buffer_size 16k;
proxy_busy_buffers_size 32k;

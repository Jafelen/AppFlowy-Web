FROM oven/bun:latest AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm && pnpm config set store-dir /root/.pnpm-store

# Install dependencies and build the project
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build

# --- Runtime image ---
FROM oven/bun:latest

WORKDIR /app

# Install required packages
RUN apt-get update && apt-get install -y nginx supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install server dependencies
RUN bun install cheerio pino pino-pretty

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy deployment scripts and configuration
COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY deploy/start.sh /app/start.sh
COPY deploy/supervisord.conf /app/supervisord.conf
COPY deploy/server.ts /app/server.ts

RUN chmod +x /app/start.sh /app/supervisord.conf

EXPOSE 80

CMD ["supervisord", "-c", "/app/supervisord.conf"]

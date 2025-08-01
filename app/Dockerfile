
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install --production && npm cache clean --force

FROM node:18-alpine AS production

WORKDIR /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY package*.json ./

COPY --from=builder /app/node_modules ./node_modules

COPY --chown=nodejs:nodejs . .

RUN mkdir -p public && chown -R nodejs:nodejs /app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "const http = require('http'); \
    const options = { hostname: 'localhost', port: 3000, path: '/health', timeout: 2000 }; \
    const req = http.request(options, (res) => { \
        if (res.statusCode === 200) process.exit(0); \
        else process.exit(1); \
    }); \
    req.on('error', () => process.exit(1)); \
    req.on('timeout', () => process.exit(1)); \
    req.end();"

USER nodejs

CMD ["node", "server.js"]
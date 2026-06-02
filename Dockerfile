# syntax=docker/dockerfile:1

# ---- Deps compartilhado (npm ci roda UMA vez, cacheia para todos os serviços) ----
FROM node:22-alpine AS deps
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package*.json tsconfig.base.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# ---- Builder por serviço (herda deps já instalados) ----
FROM deps AS builder
ARG SERVICE_NAME
COPY shared/ ./shared/
COPY services/${SERVICE_NAME}/ ./services/${SERVICE_NAME}/
RUN cd services/${SERVICE_NAME} && npm run build

# ---- Runtime ----
FROM node:22-alpine
ARG SERVICE_NAME
ARG SERVICE_PORT=3000
ENV SERVICE_NAME=${SERVICE_NAME}
WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
# Schema files needed for drizzle-kit push at startup
COPY --from=builder /app/shared/ ./shared/
COPY --from=builder /app/services/${SERVICE_NAME}/ ./services/${SERVICE_NAME}/
COPY --from=builder /app/tsconfig.base.json ./

EXPOSE ${SERVICE_PORT}
# Run db:push (only if drizzle.config.ts exists) then start service
CMD ["sh", "-c", "if [ -f services/${SERVICE_NAME}/drizzle.config.ts ]; then cd services/${SERVICE_NAME} && npx drizzle-kit push --force 2>/dev/null; cd /app; fi && node dist/services/${SERVICE_NAME}/src/main"]

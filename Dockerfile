# syntax=docker/dockerfile:1

FROM node:22-alpine AS deps
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package*.json tsconfig.base.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

FROM deps AS builder
ARG SERVICE_NAME
COPY shared/ ./shared/
COPY services/${SERVICE_NAME}/ ./services/${SERVICE_NAME}/
RUN cd services/${SERVICE_NAME} && npm run build

FROM node:22-alpine
ARG SERVICE_NAME
ARG SERVICE_PORT=3000
ENV SERVICE_NAME=${SERVICE_NAME}
WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/shared/ ./shared/
COPY --from=builder /app/services/${SERVICE_NAME}/ ./services/${SERVICE_NAME}/
COPY --from=builder /app/tsconfig.base.json ./

EXPOSE ${SERVICE_PORT}
CMD ["sh", "-c", "if [ -f services/${SERVICE_NAME}/drizzle.config.ts ]; then cd services/${SERVICE_NAME} && npx drizzle-kit migrate 2>&1; cd /app; fi && node dist/services/${SERVICE_NAME}/src/main"]

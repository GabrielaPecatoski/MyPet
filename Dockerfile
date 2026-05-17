FROM node:22-alpine AS builder
ARG SERVICE_NAME
WORKDIR /app

# Root config & deps
COPY package*.json tsconfig.base.json ./
RUN npm ci

# Shared module
COPY shared/ ./shared/

# Service source
COPY services/${SERVICE_NAME}/ ./services/${SERVICE_NAME}/

# Service deps
RUN npm ci --prefix services/${SERVICE_NAME}

# Build (nest outputs to /app/dist/services/${SERVICE_NAME}/src/main.js)
RUN cd services/${SERVICE_NAME} && npm run build

# ---- Runtime ----
FROM node:22-alpine
ARG SERVICE_NAME
ARG SERVICE_PORT=3000
ENV SERVICE_NAME=${SERVICE_NAME}
WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

EXPOSE ${SERVICE_PORT}
CMD ["sh", "-c", "node dist/services/${SERVICE_NAME}/src/main"]

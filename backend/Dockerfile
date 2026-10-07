# ---- Build stage ----
FROM node:20-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# ---- Production stage ----
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
# SQL migration dosyalarını derlenmiş çıktının yanına taşı.
COPY --from=build /app/src/db/migrations ./dist/db/migrations
EXPOSE 4000
CMD ["node", "dist/server.js"]

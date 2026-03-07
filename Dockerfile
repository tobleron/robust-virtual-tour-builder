# syntax=docker/dockerfile:1

FROM node:20-bookworm-slim AS frontend-builder
WORKDIR /app
COPY package*.json ./
COPY rescript.json ./
COPY rsbuild.config.mjs ./
COPY postcss.config.js ./
COPY tailwind.config.js ./
COPY scripts ./scripts
COPY src ./src
COPY tests ./tests
COPY css ./css
COPY public ./public
COPY lib ./lib
COPY jsconfig.json ./
COPY index.html ./
RUN npm install -g npm@11.6.2
RUN npm ci
RUN npm run build

FROM rust:1.88-bookworm AS backend-builder
WORKDIR /app/backend
ENV CARGO_PROFILE_RELEASE_LTO=false
ENV CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/src ./src
COPY backend/migrations ./migrations
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app/backend
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates ffmpeg \
  && rm -rf /var/lib/apt/lists/*

COPY --from=backend-builder /app/backend/target/release/backend /app/backend/backend
COPY --from=backend-builder /app/backend/migrations /app/backend/migrations
COPY --from=frontend-builder /app/dist /app/dist
COPY --from=frontend-builder /app/public /app/public

ENV NODE_ENV=production
ENV RUST_LOG=info
ENV PORT=8080
EXPOSE 8080

CMD ["/app/backend/backend"]

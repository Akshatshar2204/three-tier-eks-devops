FROM node:24-trixie-slim AS build

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

FROM debian:trixie-slim AS runtime

ENV NODE_ENV=production
WORKDIR /usr/src/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        dumb-init \
        libatomic1 \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node \
        --shell /usr/sbin/nologin --create-home node

COPY --from=build /usr/local/bin/node /usr/local/bin/node
COPY --from=build --chown=node:node /usr/src/app /usr/src/app

USER node

EXPOSE 3500

CMD ["dumb-init", "--", "node", "index.js"]

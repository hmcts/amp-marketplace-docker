# web-api-marketplace on public node (the repo's image needs an ACR login)
FROM node:22.23.2-alpine
WORKDIR /opt/app
RUN corepack enable && chown node:node /opt/app
USER node
ENV HOME=/tmp COREPACK_HOME=/tmp/.corepack
# puppeteer is test-only and its Chromium download fails on Alpine
ENV PUPPETEER_SKIP_DOWNLOAD=true PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
COPY --chown=node:node . .
RUN yarn install --immutable && yarn build:prod
EXPOSE 3344
CMD ["yarn", "start"]

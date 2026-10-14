# amp-marketplace-docker

Runs the API Marketplace locally with nothing in Azure: `web-api-marketplace`, `service-api-marketplace`,
Postgres and a mock Entra External ID ([navikt/mock-oauth2-server](https://github.com/navikt/mock-oauth2-server)).

## Setup

Requires Docker Desktop. Clone all three repos into the same folder:

```bash
git clone git@github.com:hmcts/amp-marketplace-docker.git
git clone git@github.com:hmcts/web-api-marketplace.git
git clone git@github.com:hmcts/service-api-marketplace.git
```

Each app is built from whatever branch is checked out in its clone.

## Run it

```bash
cd amp-marketplace-docker
docker compose up --build      # first build takes a few minutes
```

Open <http://localhost:3344>, choose **Sign in** and enter `local@amp.com` as the username. There is no password.

| Service | Address | Source |
| --- | --- | --- |
| web | <http://localhost:3344> | `../web-api-marketplace` |
| service-api | <http://localhost:8080/health> | `../service-api-marketplace` |
| entra-mock | <http://localhost:4600> | `ghcr.io/navikt/mock-oauth2-server:6.0.3` + `entra-mock.json` |
| postgres | `localhost:5432`, db `marketplace`, `postgres` / `postgres` | `postgres:18-alpine` |

| Task | Command |
| --- | --- |
| Rebuild one app after a code change | `docker compose up --build web` (or `service-api`) |
| Follow an app's logs | `docker compose logs -f web` |
| Stop everything | `docker compose down` |
| Stop and empty the database | `docker compose down -v` |

## Test users

The username is the token's subject (`sub`). Claims are shaped like External ID's: `oid`, `tid`, `email`, `name`, `ver` 2.0.

| Username | `oid` | `name` |
| --- | --- | --- |
| `local@amp.com` | `11111111-1111-4111-8111-111111111111` | Local User |
| `test@amp.com` | `22222222-2222-4222-8222-222222222222` | Test User |
| anything else | the username | the username |

- **New user:** sign in with any other username, and the app treats it as a first sign-in.
- **Add a named user:** add a mapping to `entra-mock.json`, then run `docker compose restart entra-mock web`.

## How the mock fits in

- It issues RS256-signed ID tokens with discovery and published keys, so the web app's checks run as they do against Entra: signature, issuer, audience, nonce and `oid`.
- web shares the mock's network (`network_mode: service:entra-mock`), so the browser and the web server both reach it at `localhost:4600`. That's why web's port 3344 is published on `entra-mock`.

## What still needs the sandbox tenant

The mock accepts any client ID, secret and redirect URI, and has no sign-up journey: `prompt=create` shows the same page. Check redirect URIs, the client secret and Entra's own sign-in and sign-up pages against `hmctsextsbox`. The web repo's README covers how.

## Differences from AKS

- Images build on public `node` and `eclipse-temurin`, because `hmctsprod.azurecr.io/base/*` needs an ACR login.
- Sessions are held in memory (no Redis), and App Insights is off.
- service-api has no Azure credentials, so its API Management and Graph features fail.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| web unreachable after restarting the mock | `docker compose restart entra-mock web`: web shares the mock's network |
| `port is already allocated` | Stop whatever is using 3344, 4600, 8080 or 5432, such as a local `yarn start:dev` or Postgres |
| Sign-in fails after editing `entra-mock.json` | Check the JSON is valid, then restart `entra-mock web` |

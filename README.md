# infisical-railway

Wrapper image for deploying [Infisical](https://github.com/Infisical/infisical) — the
open-source secrets manager — on [Railway](https://railway.com).

Upstream image pinned by digest (v0.146.2). The wrapper adds three things a Railway
template cannot express as variables:

1. **The instance administrator is seeded before the public port opens.** Upstream
   exposes `POST /api/v1/admin/bootstrap` with no authentication; it refuses only once
   the instance is already initialised, and the account it creates is a `superAdmin`
   with an organisation and an org-admin machine identity token. On a public URL that
   means the first stranger to call it owns the secrets manager. This image starts the
   server on loopback, bootstraps it, stops it, and only then binds `$PORT`.
2. **The Node heap is sized from the container's cgroup limit** instead of the 1024 MB
   the upstream image bakes into `NODE_OPTIONS`.
3. **Telemetry is off by default.**

The container refuses to start unless `INFISICAL_ADMIN_EMAIL` and
`INFISICAL_ADMIN_PASSWORD` are both set.

Image: `ghcr.io/bon5co/infisical-railway:v0.146.2`

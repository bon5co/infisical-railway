# Infisical for Railway.
#
# Upstream image, pinned by digest (v0.146.2, the `latest-postgres` line).
# The wrapper exists to do three things a Railway template cannot express in
# variables:
#   1. seed the instance administrator BEFORE the public port opens, so the
#      unauthenticated /api/v1/admin/bootstrap route cannot be used by a
#      stranger to claim the secrets manager;
#   2. size the Node heap from the container's cgroup limit instead of the
#      1024 MB the upstream image bakes in;
#   3. turn product telemetry off by default.
FROM infisical/infisical@sha256:36438985877fb5ab99c76ee1a9c73611e44d8518b44a77304b5d4c05451f8c62

ENV TELEMETRY_ENABLED=false \
    INFISICAL_ORG_NAME="Admin Org" \
    NODE_OPTIONS=""

COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY bootstrap.mjs /usr/local/bin/bootstrap.mjs

USER root
RUN chmod +x /usr/local/bin/railway-entrypoint.sh
USER non-root-user

ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]

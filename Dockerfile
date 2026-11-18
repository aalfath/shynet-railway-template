# Shynet v0.14.0, the official image from milesmcc/shynet.
# Upstream's v0.14.0 release workflow published this image under the tag
# `latest-type-ref` only (Docker Hub and GHCR have no `v0.14.0` tag). Its
# `org.opencontainers.image.revision` label is ca35caba3af2b888acc990b99152c500a1c44461,
# the commit tagged v0.14.0. The digest below pins that exact image (amd64 + arm64).
FROM milesmcc/shynet@sha256:fa98c732e07db0fd431248a8cf90583d10d3ea6e3926beae60d7183389f8ceb0

LABEL org.opencontainers.image.source="https://github.com/aalfath/shynet-railway-template" \
      org.opencontainers.image.version="0.14.0"

# Fixed settings with sensible defaults. Override any of them with a service variable.
ENV SHYNET_VERSION=0.14.0 \
    PORT=8080 \
    TIME_ZONE=Etc/UTC \
    ACCOUNT_SIGNUPS_ENABLED=False \
    ACCOUNT_EMAIL_VERIFICATION=none \
    ONLY_SUPERUSERS_CREATE=True \
    AGGRESSIVE_HASH_SALTING=True \
    SCRIPT_USE_HTTPS=True \
    NUM_WORKERS=1

COPY --chmod=755 railway-start.sh /usr/src/shynet/railway-start.sh

EXPOSE 8080
CMD ["/usr/src/shynet/railway-start.sh"]

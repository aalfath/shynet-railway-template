[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/shynet?utm_medium=integration&utm_source=button&utm_campaign=shynet)

# Shynet on Railway

A one-click [Railway](https://railway.com) template for [Shynet](https://github.com/milesmcc/shynet), the privacy-friendly web analytics server that works without cookies (and even without JavaScript, through a tracking pixel).

**Version:** Shynet `0.14.0` (2026-03-15), from the official `milesmcc/shynet` image pinned by digest in the [`Dockerfile`](Dockerfile). Upstream published the v0.14.0 image under the tag `latest-type-ref` only; its revision label is the commit tagged `v0.14.0`.

## What the template deploys

| Service | Built from | Role | Public | State |
|---|---|---|---|---|
| `Shynet` | this repository ([`Dockerfile`](Dockerfile)) | Dashboard, tracking script and ingress (gunicorn) | yes | none: everything is in Postgres |
| `Postgres` | Railway's Postgres | Sites, sessions, hits and users | no | Railway volume |

- The Shynet service builds from this repository, so Railway tells deployers when a new version is merged here.
- [`railway-start.sh`](railway-start.sh) adds the Railway domain to `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS`, waits for Postgres, runs the migrations, creates the first admin once, and starts Shynet on `PORT`.
- Health check: `/healthz/` (checks the database and cache, no login).
- It refuses to start without `DJANGO_SECRET_KEY`, so it never runs on Shynet's built-in development key.
- Public sign-ups are off. Only admins can add sites (`ONLY_SUPERUSERS_CREATE=True`).

## Variables

| Variable | Value | Notes |
|---|---|---|
| `ADMIN_EMAIL` | you fill it in | Email of the first admin, created on the first deploy |
| `ADMIN_PASSWORD` | random, 24 characters | The first admin's password. Read it in the service's Variables tab. Used only when the instance has no users yet; change the password in Shynet afterwards |
| `DJANGO_SECRET_KEY` | random, 50 characters | Django's signing key |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Private network connection to Postgres |
| `PORT` | `8080` | Port gunicorn listens on |

Fixed defaults are set in the `Dockerfile` (`TIME_ZONE=Etc/UTC`, sign-ups off, aggressive hash salting on, HTTPS tracking script). Override any of them, or any other [Shynet setting](https://github.com/milesmcc/shynet/blob/master/TEMPLATE.env), with a service variable. For a custom domain, add it to `ALLOWED_HOSTS` and `https://` plus it to `CSRF_TRUSTED_ORIGINS`; the Railway domain is added for you.

## After deploying

1. Open the Shynet service's URL and log in with `ADMIN_EMAIL` and `ADMIN_PASSWORD`.
2. Click **+ Create Service**, enter your site's name and domain, and copy the tracking snippet into your site's HTML.
3. Optional: set `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `EMAIL_USE_SSL` (or `EMAIL_USE_TLS`) and `SERVER_EMAIL` to send password-reset and invite emails.
4. Optional: add more admins later from the service shell with `./manage.py registeradmin you@example.com` (it prints a generated password).

## Updates

When this repository bumps the Shynet version, Railway shows an "update available" notice on your project and you choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Migrations run on every start.

## License

Shynet is Apache-2.0, see [milesmcc/shynet](https://github.com/milesmcc/shynet). This wrapper is MIT.

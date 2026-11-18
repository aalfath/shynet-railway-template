#!/bin/bash
# Railway start script for Shynet: maps Railway's domain onto Django's host
# settings, waits for Postgres, runs migrations, creates the first admin once,
# then starts Shynet's own web server (gunicorn on $PORT).
set -euo pipefail
cd /usr/src/shynet

# Hosts Django answers to: your extra ALLOWED_HOSTS (custom domains), the Railway
# public and private domains, Railway's health checker, and localhost.
hosts="${ALLOWED_HOSTS:-}"
for h in "${RAILWAY_PUBLIC_DOMAIN:-}" "${RAILWAY_PRIVATE_DOMAIN:-}" healthcheck.railway.app localhost 127.0.0.1; do
  [ -n "$h" ] && hosts="${hosts:+$hosts,}$h"
done
export ALLOWED_HOSTS="$hosts"

origins="${CSRF_TRUSTED_ORIGINS:-}"
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  origins="${origins:+$origins,}https://${RAILWAY_PUBLIC_DOMAIN}"
fi
export CSRF_TRUSTED_ORIGINS="$origins"

if [ -z "${DJANGO_SECRET_KEY:-}" ]; then
  echo "DJANGO_SECRET_KEY is not set; refusing to start with Shynet's built-in development key." >&2
  exit 1
fi
if [ -z "${DATABASE_URL:-}" ] && [ -z "${DB_HOST:-}" ] && [ "${SQLITE:-False}" != "True" ]; then
  echo "DATABASE_URL is not set; link it to your Postgres service (\${{Postgres.DATABASE_URL}})." >&2
  exit 1
fi

# Wait up to 2 minutes for the database (Postgres starts alongside Shynet on the first deploy).
python - <<'PY'
import os, sys, time
url = os.environ.get("DATABASE_URL")
if not url:
    sys.exit(0)
import psycopg2
for i in range(60):
    try:
        psycopg2.connect(url, connect_timeout=3).close()
        print("Database is reachable.")
        sys.exit(0)
    except Exception as e:
        print(f"Waiting for the database ({e.__class__.__name__})...", flush=True)
        time.sleep(2)
sys.exit("Database did not become reachable in 2 minutes.")
PY

echo "Running database migrations..."
python manage.py migrate --noinput

# First admin: created once, only while the instance has no users at all.
python manage.py shell -c '
import os, uuid
from core.models import User
email = os.environ.get("ADMIN_EMAIL", "").strip()
password = os.environ.get("ADMIN_PASSWORD", "")
if User.objects.exists():
    print("Admin setup: users already exist, nothing to do.")
elif not email:
    print("Admin setup: ADMIN_EMAIL is empty, so no admin was created. Set it and redeploy.")
elif len(password) < 12:
    print("Admin setup: ADMIN_PASSWORD is missing or shorter than 12 characters, so no admin was created.")
else:
    User.objects.create_superuser(str(uuid.uuid4()), email=email, password=password)
    print(f"Admin setup: created the admin user {email}. Its password is the ADMIN_PASSWORD variable.")
'

exec ./webserver.sh

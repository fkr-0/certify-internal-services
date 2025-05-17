#!/bin/sh
set -e

# 1. start dnsmasq (now running as user 'app' thanks to file caps)
dnsmasq --keep-in-foreground \
  --conf-file=/config/dnsmasq.conf \
  --pid-file=/data/dnsmasq.pid &

DNSMASQ_PID=$!

# 2. lightweight cron in foreground (crond happily runs unprivileged)
# crontab /config/renew.cron # TODO does it, though?
crond -f -l 8 &
curl https://get.acme.sh | sh -s # email=TODO necessary?

# 3. kick off the supervisor once for good measure
python3 /app/cert-manager.py initial || true

# 4. keep container alive as long as dnsmasq is
wait ${DNSMASQ_PID}

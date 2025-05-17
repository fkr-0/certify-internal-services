#!/bin/sh
set -e

echo "▶️  Installing runtime deps (root, once)…"
apk add --no-cache \
  dnsmasq \
  openssh-client rsync \
  curl jq git \
  python3 py3-pip py3-yaml \
  logrotate tzdata \
  su-exec libcap openssl

# ----- create dedicated user/group --------------------------------
echo '▶️  Adding lower priv user "app"…'
adduser -D -h /home/app -s /sbin/nologin app || echo 'user "app" lready existing, OK'
chown -R app:app /data /config /app /root

# ------------------------------------------------------------------
# BusyBox crontab needs root for the *write*, so load it *before*
# we drop privileges.  We install the crontab *for the app user*:
crontab -u app /config/renew-cert.cron
# ------------------------------------------------------------------

# ----- allow dnsmasq to bind to :53 & use raw sockets -------------
setcap 'cap_net_bind_service,cap_net_raw=ep' /usr/sbin/dnsmasq

# ----- crontab suid -----
# sudo chmod u+s $(which crontab)

# ----- install acme.sh under /home/app ----------------------------
echo "▶️  Installing acme.sh…"
cd /app

[ -f /config/dnsmasq.conf ] || {
  echo "▶️  Copying default dnsmasq.conf…"
  cp /config/dnsmasq.conf-def /config/dnsmasq.conf
}
# /sbin/su-exec app sh -c 'curl https://get.acme.sh | sh'

# ----- jump into unprivileged runtime -----------------------------
echo "▶️  Dropping to uid=$(id -u app) / gid=$(id -g app)…"
exec su-exec app /app/boot_user.sh # never returns

#!/bin/bash
# Runs once at first boot (as root). Log: /var/log/cloud-init-output.log
set -euxo pipefail

dnf install -y nginx docker

# --- Instance metadata (IMDSv2) ---
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
md() {
  curl -sS -H "X-aws-ec2-metadata-token: ${TOKEN}" \
    "http://169.254.169.254/latest/meta-data/$1"
}
INSTANCE_ID=$(md instance-id)
AZ=$(md placement/availability-zone)
PRIVATE_IP=$(md local-ipv4)

# --- nginx (port 80): show which instance / AZ served the request ---
cat > /usr/share/nginx/html/index.html <<EOF
<!doctype html>
<html>
<head><meta charset="utf-8"><title>aws-learn</title></head>
<body style="font-family: sans-serif; margin: 2rem;">
  <h1>aws-learn: nginx</h1>
  <table>
    <tr><th align="left">Instance ID</th><td>${INSTANCE_ID}</td></tr>
    <tr><th align="left">AZ</th><td>${AZ}</td></tr>
    <tr><th align="left">Private IP</th><td>${PRIVATE_IP}</td></tr>
  </table>
  <p>Reload to see the other instance. <a href="/whoami">/whoami</a></p>
</body>
</html>
EOF
systemctl enable --now nginx

# --- traefik/whoami (port 8080) in Docker ---
systemctl enable --now docker
docker run -d --name whoami --restart always -p 8080:80 traefik/whoami

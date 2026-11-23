#!/bin/bash

# 1. Update the operating system and install required tools (Node.js and Unzip)
dnf update -y
dnf install -y nodejs unzip

# 2. Create a folder for your application and move into it
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# 3. Download the zipped application code from your S3 bucket
# IMPORTANT: Replace the bucket name below with YOUR exact bucket name!
aws s3 cp s3://keval-cloudserver-artifacts-123/app.zip .

# 4. Unzip the code
unzip app.zip

# 5. Install the Node.js dependencies
npm install --production

# 6. Create a systemd service so the app runs on port 80 and stays alive after boot
cat << 'EOF' > /etc/systemd/system/cloudserver.service
[Unit]
Description=CloudServer Node.js App
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/ec2-user/app
Environment=PORT=80
ExecStart=/usr/bin/node dist/server.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 7. Start the service and print logs + health check to the AWS System Log
systemctl daemon-reload
systemctl enable --now cloudserver
sleep 3
systemctl status cloudserver --no-pager || true
journalctl -u cloudserver -n 20 --no-pager || true
curl -s http://localhost/health || true
SCRIPT_EOF
#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Flask webapp deployment at $(date)"

# Update system
dnf update -y

# Install required packages
dnf install -y python3 python3-pip python3-devel gcc git nginx
# Create application directory
APP_DIR="/opt/${app_name}"
mkdir -p $APP_DIR
chown ec2-user:ec2-user $APP_DIR
cd $APP_DIR

# Clone the repository
echo "Cloning repository: ${github_repo}"
git clone ${github_repo} .

# Install Python dependencies
echo "Installing Python dependencies"
pip3 install --upgrade pip
pip3 install flask flask-mysql

# Create a systemd service for the Flask app
cat > /etc/systemd/system/flask-app.service << EOF
[Unit]
Description=Flask Web Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$APP_DIR
Environment=FLASK_APP=app.py
Environment=FLASK_ENV=production
ExecStart=/usr/bin/python3 -m flask run --host=0.0.0.0 --port=5000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the Flask service
systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app

# Configure nginx as a reverse proxy
cat > /etc/nginx/conf.d/flask-app.conf << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable and restart nginx
systemctl enable nginx
systemctl restart nginx

# Check service status
echo "Flask app service status:"
systemctl status flask-app

echo "Flask webapp deployment completed at $(date)"
echo "Application should be accessible at http://$(curl -s http://checkip.amazonaws.com):5000"
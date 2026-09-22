const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('--- Updating reviewsgateway.conf with support-chat and socket.io locations ---');

  const confContent = `server {
    server_name reviewsgateway.in www.reviewsgateway.in;

    root /var/www/buyer-web;
    index index.html;

    client_max_body_size 50M;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location = /flutter_service_worker.js {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location = /version.json {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 60;
    }

    # Support Chat REST API & Uploads
    location /support-chat/ {
        proxy_pass http://127.0.0.1:3005/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300;
    }

    # Support Chat Real-time WebSocket
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3005/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/reviewsgateway.in/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/reviewsgateway.in/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    listen 3001;
    server_name _;

    root /var/www/buyer-web;
    index index.html;

    client_max_body_size 50M;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 60;
    }

    # Support Chat REST API & Uploads
    location /support-chat/ {
        proxy_pass http://127.0.0.1:3005/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300;
    }

    # Support Chat Real-time WebSocket
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3005/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
}

server {
    if ($host = www.reviewsgateway.in) {
        return 301 https://$host$request_uri;
    }


    if ($host = reviewsgateway.in) {
        return 301 https://$host$request_uri;
    }


    listen 80;
    server_name reviewsgateway.in www.reviewsgateway.in;
    return 301 https://$host$request_uri;
}
`;

  const base64 = Buffer.from(confContent).toString('base64');
  await ssh.execCommand(`echo "${base64}" | base64 -d > /etc/nginx/conf.d/reviewsgateway.conf`);

  console.log('Testing Nginx config...');
  const t = await ssh.execCommand('nginx -t');
  console.log(t.stdout || t.stderr);

  console.log('Reloading Nginx...');
  await ssh.execCommand('systemctl reload nginx');
  console.log('Nginx reloaded successfully!');

  // Test local curl via Nginx
  const testLocal = await ssh.execCommand('curl -s https://reviewsgateway.in/support-chat/health');
  console.log('Health check via domain:', testLocal.stdout);

  ssh.dispose();
}

run().catch(console.error);

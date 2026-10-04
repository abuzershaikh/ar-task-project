const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('--- Applying comprehensive Nginx configuration for reviewsgateway.in ---');

  const confContent = `server {
    server_name reviewsgateway.in www.reviewsgateway.in;

    root /var/www/buyer-web;
    index index.html;

    client_max_body_size 50M;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    # Support Chat REST API & Uploads
    location ^~ /support-chat/ {
        proxy_pass http://127.0.0.1:3005/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300;
    }

    location = /support-chat {
        return 301 /support-chat/;
    }

    # Support Chat Real-time WebSocket
    location ^~ /socket.io/ {
        proxy_pass http://127.0.0.1:3005/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    # Task Engine API
    location ^~ /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 60;
    }

    # No-cache for web app bundle assets
    location ~* \\.(js|json|html)$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Frontend Single Page App fallback
    location / {
        try_files $uri $uri/ /index.html;
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

    location ^~ /support-chat/ {
        proxy_pass http://127.0.0.1:3005/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300;
    }

    location = /support-chat {
        return 301 /support-chat/;
    }

    location ^~ /socket.io/ {
        proxy_pass http://127.0.0.1:3005/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    location ^~ /api/v1/ {
        proxy_pass http://127.0.0.1:3000/api/v1/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 60;
    }

    location ~* \\.(js|json|html)$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location / {
        try_files $uri $uri/ /index.html;
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

  if ((t.stdout || t.stderr).includes('successful')) {
    console.log('Reloading Nginx...');
    await ssh.execCommand('systemctl reload nginx');
    console.log('Nginx reloaded successfully!');
  } else {
    console.error('Nginx test failed! Not reloading.');
    ssh.dispose();
    return;
  }

  console.log('\n--- Verifying HTTPS Support Chat endpoints ---');
  const h = await ssh.execCommand('curl -s https://reviewsgateway.in/support-chat/health');
  console.log('Health:', h.stdout);

  const c = await ssh.execCommand('curl -s https://reviewsgateway.in/support-chat/api/support/conversations?limit=2');
  console.log('Conversations:', c.stdout);

  const m = await ssh.execCommand('curl -s https://reviewsgateway.in/support-chat/api/support/conversations/5928786b-7903-401a-be17-52e8ff833f20/messages');
  console.log('Messages:', m.stdout);

  const sock = await ssh.execCommand('curl -s "https://reviewsgateway.in/socket.io/?EIO=4&transport=polling"');
  console.log('Socket.IO Polling handshake:', sock.stdout);

  ssh.dispose();
}

run().catch(console.error);

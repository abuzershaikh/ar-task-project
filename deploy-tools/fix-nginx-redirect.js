const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function fixNginx() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const conf = `server {
    server_name reviewsgateway.in www.reviewsgateway.in;

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
}

server {
    listen 80;
    server_name reviewsgateway.in www.reviewsgateway.in;
    return 301 https://$host$request_uri;
}
`;

    console.log('Writing clean Nginx config...');
    await ssh.execCommand(`cat << 'EOF' > /etc/nginx/conf.d/reviewsgateway.conf\n${conf}\nEOF`);

    console.log('Testing Nginx config...');
    const t = await ssh.execCommand('nginx -t');
    console.log(t.stdout || t.stderr);

    console.log('Reloading Nginx...');
    await ssh.execCommand('nginx -s reload');

    console.log('Done!');
  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

fixNginx();

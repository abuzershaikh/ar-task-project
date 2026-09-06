const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

const nginxConfig = `server {
    listen 80;
    server_name reviewsgateway.in www.reviewsgateway.in swiftcommerce.in www.swiftcommerce.in;

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
`;

async function update() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('Connected to VPS.');

    // Save to /etc/nginx/conf.d/reviewsgateway.conf and remove old if needed
    await ssh.execCommand(`cat << 'EOF' > /etc/nginx/conf.d/reviewsgateway.conf\n${nginxConfig}\nEOF`);
    await ssh.execCommand('rm -f /etc/nginx/conf.d/swiftcommerce.conf');

    console.log('Testing Nginx syntax...');
    const t = await ssh.execCommand('nginx -t');
    console.log(t.stdout || t.stderr);

    if (t.stdout.includes('syntax is ok') || t.stderr.includes('syntax is ok')) {
      console.log('Reloading Nginx...');
      await ssh.execCommand('nginx -s reload');
      console.log('Nginx reloaded successfully.');

      const testRes = await ssh.execCommand('curl -sI -H "Host: reviewsgateway.in" http://127.0.0.1');
      console.log('Local test for reviewsgateway.in:\n', testRes.stdout);

      const testResWww = await ssh.execCommand('curl -sI -H "Host: www.reviewsgateway.in" http://127.0.0.1');
      console.log('Local test for www.reviewsgateway.in:\n', testResWww.stdout);
    } else {
      console.error('Nginx test failed!');
    }
  } catch (e) {
    console.error('Error:', e.message);
  } finally {
    ssh.dispose();
    process.exit(0);
  }
}

update();

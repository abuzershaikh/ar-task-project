const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('=== STEP 1: CREATE SELINUX MODULE FROM AUDIT.LOG ===');
    const c1 = await ssh.execCommand('cd /root && grep "pm2.pid" /var/log/audit/audit.log | audit2allow -M pm2_systemd');
    console.log('c1:', c1.stdout || c1.stderr);

    console.log('\n=== STEP 2: INSTALL SELINUX MODULE IF GENERATED ===');
    const c2 = await ssh.execCommand('cd /root && if [ -f pm2_systemd.pp ]; then semodule -i pm2_systemd.pp && echo "Module installed successfully"; else echo "pp file not found"; fi');
    console.log('c2:', c2.stdout || c2.stderr);

    console.log('\n=== STEP 3: CONFIGURE PM2-ROOT SERVICE ===');
    // Using Type=oneshot with RemainAfterExit=yes is the bulletproof solution recommended for PM2 resurrect
    // because PM2 resurrect launches the daemon and returns immediately.
    const serviceContent = `[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=oneshot
User=root
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
Environment=PM2_HOME=/root/.pm2
ExecStart=/usr/lib/node_modules/pm2/bin/pm2 resurrect
ExecReload=/usr/lib/node_modules/pm2/bin/pm2 reload all
ExecStop=/usr/lib/node_modules/pm2/bin/pm2 kill
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
`;
    await ssh.execCommand(`cat <<'EOF' > /etc/systemd/system/pm2-root.service\n${serviceContent}EOF`);

    console.log('\n=== STEP 4: SYSTEMCTL DAEMON-RELOAD & RESTART ===');
    console.log((await ssh.execCommand('systemctl daemon-reload')).stdout);
    console.log((await ssh.execCommand('systemctl restart pm2-root')).stdout);

    console.log('\n=== STEP 5: CHECK SYSTEMCTL STATUS ===');
    console.log((await ssh.execCommand('systemctl status pm2-root --no-pager')).stdout);

    console.log('\n=== STEP 6: SAVE PM2 STATE ===');
    console.log((await ssh.execCommand('pm2 save')).stdout);

    console.log('\n=== STEP 7: CHECK PM2 STATUS ===');
    console.log((await ssh.execCommand('pm2 status')).stdout);

    ssh.dispose();
  } catch (err) {
    console.error('SSH Error:', err.message);
    ssh.dispose();
  }
})();

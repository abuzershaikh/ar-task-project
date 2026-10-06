const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 30000,
  });

  const testWorkerLogin = await ssh.execCommand(`node -e '
    const jwt = require("/opt/task-engine/node_modules/jsonwebtoken");
    const secret = "super_secret_jwt_key_1234567890";
    const token = jwt.sign({ sub: "k3Rj11xqJvcxvJojOnunvc35Z6q2", id: "k3Rj11xqJvcxvJojOnunvc35Z6q2", email: "narutobhai968@gmail.com", role: "worker" }, secret, { expiresIn: "1h" });
    
    const http = require("http");
    const req = http.request("http://localhost:3000/api/v1/worker/earnings/wallet", {
      headers: { "Authorization": "Bearer " + token }
    }, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try {
          const json = JSON.parse(data);
          console.log("SUCCESS:", json.success);
          console.log("Worker minWithdrawalLimit from API:", json.wallet?.minWithdrawalLimit);
          console.log("Worker availableBalance from API:", json.wallet?.availableBalance);
        } catch(e) {
          console.log("Raw response:", data);
        }
      });
    });
    req.end();
  '`);

  console.log(testWorkerLogin.stdout);
  ssh.dispose();
}

main().catch(console.error);

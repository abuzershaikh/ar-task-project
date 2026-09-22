const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function parseBackupUsers() {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const pyScript = `
with open("/root/task_platform_backup_before_wipe.sql", "r", errors="ignore") as f:
    for line in f:
        if line.startswith("INSERT INTO \`users\`"):
            # Split rows: '),('
            rows = line.split("),(")
            print(f"Total user rows in backup: {len(rows)}")
            for r in rows:
                parts = r.split(",")
                # email is usually 2nd or 3rd part
                print(r[:150])
`;
    await ssh.execCommand(`cat << 'EOF' > /root/parse_users.py\n${pyScript}\nEOF`);
    const res = await ssh.execCommand('python3 /root/parse_users.py');
    console.log(res.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

parseBackupUsers();

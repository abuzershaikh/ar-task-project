const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
    readyTimeout: 60000,
  });

  await ssh.execCommand("mysql -e 'UPDATE task_platform.tasks SET requirements = JSON_SET(requirements, \"$.platform\", \"playstore\", \"$.category\", \"Play Store\") WHERE task_type LIKE \"PLAYSTORE%\";'");

  const res2 = await ssh.execCommand("mysql -e 'SELECT task_type, JSON_UNQUOTE(JSON_EXTRACT(requirements, \"$.platform\")) as platform, JSON_UNQUOTE(JSON_EXTRACT(requirements, \"$.category\")) as category, count(*) as count FROM task_platform.tasks GROUP BY task_type, platform, category;'");
  console.log('Final Task groupings:\n', res2.stdout);

  ssh.dispose();
}

run();

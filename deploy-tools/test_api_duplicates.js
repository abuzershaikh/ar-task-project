const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

(async () => {
  try {
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    const res = await ssh.execCommand("curl -s 'http://localhost:3005/api/support/conversations?limit=200'");
    const data = JSON.parse(res.stdout);
    const convs = data.data.conversations;
    console.log('Total conversations returned from API (limit 200):', convs.length);

    const emailCounts = {};
    const idCounts = {};
    const convIdCounts = {};

    for (const c of convs) {
      if (c.worker_email) {
        emailCounts[c.worker_email] = (emailCounts[c.worker_email] || 0) + 1;
      }
      if (c.worker_id) {
        idCounts[c.worker_id] = (idCounts[c.worker_id] || 0) + 1;
      }
      convIdCounts[c.id] = (convIdCounts[c.id] || 0) + 1;
    }

    const dupEmails = Object.entries(emailCounts).filter(([_, count]) => count > 1);
    const dupIds = Object.entries(idCounts).filter(([_, count]) => count > 1);
    const dupConvIds = Object.entries(convIdCounts).filter(([_, count]) => count > 1);

    console.log('Duplicate conversation IDs:', dupConvIds);
    console.log('Duplicate worker emails:', dupEmails);
    console.log('Duplicate worker IDs:', dupIds);

    const naxm = convs.filter(c => c.worker_email === 'workinhomex@gmail.com' || (c.worker_name && c.worker_name.includes('Naxm')));
    console.log('Naxm count in API response:', naxm.length);

    const prashant = convs.filter(c => c.worker_email === 'prashantsinghtomar9589@gmail.com');
    console.log('Prashant count in API response:', prashant.length);

    ssh.dispose();
  } catch (e) {
    console.error(e);
  }
})();

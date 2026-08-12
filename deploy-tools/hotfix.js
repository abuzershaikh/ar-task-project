const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function hotfix() {
    await ssh.connect({
      host: '95.179.178.6',
      username: 'root',
      password: 'i_G72#y}(6gACDDU'
    });
    
    console.log('Uploading hotfix...');
    await ssh.putFile(
      'd:/AR Task Project/Task engine/matching-engine/matching-engine.module.ts',
      '/var/www/task-engine/matching-engine/matching-engine.module.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/allocation-engine/allocation-engine.module.ts',
      '/var/www/task-engine/allocation-engine/allocation-engine.module.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/services/services.module.ts',
      '/var/www/task-engine/shared/services/services.module.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/apps/api/main.ts',
      '/var/www/task-engine/apps/api/main.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/config/database.config.ts',
      '/var/www/task-engine/shared/config/database.config.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/common/filters/http-exception.filter.ts',
      '/var/www/task-engine/shared/common/filters/http-exception.filter.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/database/entities/user.entity.ts',
      '/var/www/task-engine/shared/database/entities/user.entity.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/database/entities/service-catalog.entity.ts',
      '/var/www/task-engine/shared/database/entities/service-catalog.entity.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/database/entities/task-generation-job.entity.ts',
      '/var/www/task-engine/shared/database/entities/task-generation-job.entity.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/database/entities/campaign-worker-participation.entity.ts',
      '/var/www/task-engine/shared/database/entities/campaign-worker-participation.entity.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/auth/dto/google-auth.dto.ts',
      '/var/www/task-engine/shared/auth/dto/google-auth.dto.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/shared/auth/auth.service.ts',
      '/var/www/task-engine/shared/auth/auth.service.ts'
    );
    await ssh.putFile(
      'd:/AR Task Project/Task engine/apps/api/controllers/auth/auth.controller.ts',
      '/var/www/task-engine/apps/api/controllers/auth/auth.controller.ts'
    );
    
    console.log('Rebuilding...');
    const build = await ssh.execCommand('cd /var/www/task-engine && npm run build');
    console.log(build.stdout);
    if(build.stderr) console.error(build.stderr);
    
    console.log('Restarting PM2...');
    await ssh.execCommand('pm2 restart task-engine --update-env');
    
    ssh.dispose();
}
hotfix();

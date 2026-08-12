const AdmZip = require('adm-zip');
console.log('Zipping temp_deploy directory...');
const zip = new AdmZip();
zip.addLocalFolder('d:/temp_deploy');
zip.writeZip('task-engine.zip');
console.log('task-engine.zip created successfully with forward slashes.');

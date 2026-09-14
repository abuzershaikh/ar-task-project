const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function updateTaskRealistic() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const taskId = 'd9cc0d1c-b523-4e70-8305-d7d530e14c96';

  // 1. Fetch current task
  const res = await ssh.execCommand(
    `mysql -u taskapp -ptaskapp_password task_platform -N -e "SELECT requirements FROM tasks WHERE id = '${taskId}';"`
  );

  if (!res.stdout) {
    console.error('Task not found!');
    process.exit(1);
  }

  let req = {};
  try {
    req = JSON.parse(res.stdout.trim());
  } catch (e) {
    console.error('Error parsing requirements JSON:', e);
  }

  console.log('Old reviewText/commentText:', req.reviewText || req.commentText || req.customText);

  // New realistic human review for A2m Infotech (25 words, realistic IT customer):
  const realisticHumanReview = "Approached A2m Infotech for customized software and website development. The team understood our requirements patiently and delivered a very smooth, fast loading platform. Clear communication and honest pricing throughout.";

  req.commentText = realisticHumanReview;
  req.comment_text = realisticHumanReview;
  req.reviewText = realisticHumanReview;
  req.review_text = realisticHumanReview;
  req.customText = realisticHumanReview;
  req.minWords = 20;
  req.maxWords = 40;

  const updatedJsonStr = JSON.stringify(req).replace(/'/g, "\\'");

  await ssh.execCommand(
    `mysql -u taskapp -ptaskapp_password task_platform -e "UPDATE tasks SET requirements = '${updatedJsonStr}' WHERE id = '${taskId}';"`
  );

  console.log('✓ Successfully updated task to realistic human review:');
  console.log(`"${realisticHumanReview}" (${realisticHumanReview.split(/\s+/).length} words)`);

  process.exit(0);
}

updateTaskRealistic().catch(console.error);

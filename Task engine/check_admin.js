const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const admins = await prisma.user.findMany({
    where: {
      role: {
        in: ['ADMIN', 'SUPER_ADMIN']
      }
    },
    select: {
      email: true,
      role: true,
      status: true
    }
  });

  console.log('Admins in DB:', admins);
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());

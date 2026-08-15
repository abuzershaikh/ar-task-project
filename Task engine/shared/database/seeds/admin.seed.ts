import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole, UserStatus } from '../entities/user.entity';
import { ServiceCatalog } from '../entities/service-catalog.entity';
import { ServicePricing } from '../entities/service-pricing.entity';
import { MarginType } from '../../modules/service-catalog/enums/margin-type.enum';

export async function seedAdminAndServices(dataSource: DataSource) {
  const userRepo = dataSource.getRepository(User);
  const serviceRepo = dataSource.getRepository(ServiceCatalog);
  const pricingRepo = dataSource.getRepository(ServicePricing);

  // 1. Seed Super Admin User
  const adminEmail = 'admin@taskpost.com';
  let admin = await userRepo.findOne({ where: { email: adminEmail } });

  if (!admin) {
    const hashedPassword = await bcrypt.hash('Admin@123456', 10);
    admin = userRepo.create({
      email: adminEmail,
      fullName: 'Super Admin',
      password: hashedPassword,
      role: UserRole.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      emailVerified: true,
      phoneVerified: true,
    });
    await userRepo.save(admin);
    console.log('✅ SuperAdmin created: admin@taskpost.com / Admin@123456');
  }

  // 1.5. Seed Second Super Admin User
  const adminEmail2 = 'snapbizux@gmail.com';
  let admin2 = await userRepo.findOne({ where: { email: adminEmail2 } });

  if (!admin2) {
    const hashedPassword2 = await bcrypt.hash('80978097', 10);
    admin2 = userRepo.create({
      email: adminEmail2,
      fullName: 'Snapbiz Admin',
      password: hashedPassword2,
      role: UserRole.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
      emailVerified: true,
      phoneVerified: true,
    });
    await userRepo.save(admin2);
    console.log('✅ SuperAdmin created: snapbizux@gmail.com / 80978097');
  }

  // 2. Seed Default Service Catalog & Pricing
  const defaultServices = [
    {
      code: 'YOUTUBE_LIKE',
      name: 'YouTube Video Like',
      description: 'High quality real user likes on YouTube videos',
      buyerUnitPrice: 2.00,
      marginType: MarginType.FIXED,
      marginValue: 0.50,
      workerReward: 1.50,
    },
    {
      code: 'YOUTUBE_SUBSCRIBE',
      name: 'YouTube Channel Subscribe',
      description: 'Permanent subscribers from verified accounts',
      buyerUnitPrice: 5.00,
      marginType: MarginType.FIXED,
      marginValue: 1.50,
      workerReward: 3.50,
    },
    {
      code: 'APP_INSTALL',
      name: 'Android App Install & Open',
      description: 'Install app from Play Store and keep open for 1 minute',
      buyerUnitPrice: 10.00,
      marginType: MarginType.PERCENTAGE,
      marginValue: 30.00, // 30% margin
      workerReward: 7.00,
    },
  ];

  for (const item of defaultServices) {
    let service = await serviceRepo.findOne({ where: { code: item.code } });
    if (!service) {
      service = serviceRepo.create({
        code: item.code,
        name: item.name,
        description: item.description,
        isActive: true,
        version: 1,
      });
      await serviceRepo.save(service);

      const pricing = pricingRepo.create({
        serviceId: service.id,
        buyerUnitPrice: item.buyerUnitPrice,
        marginType: item.marginType,
        marginValue: item.marginValue,
        workerReward: item.workerReward,
        currency: 'INR',
        version: 1,
        isActive: true,
      });
      await pricingRepo.save(pricing);
      console.log(`✅ Service seeded: ${item.name} (${item.code})`);
    }
  }
}

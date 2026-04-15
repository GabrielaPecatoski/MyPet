import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MarketplaceModule } from './marketplace/marketplace.module';
import { Product } from './marketplace/entities/product.entity';
import { Order } from './marketplace/entities/order.entity';
import { OrderItem } from './marketplace/entities/order-item.entity';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL ?? 'postgresql://postgres:root@localhost:5432/mypet',
      entities: [Product, Order, OrderItem],
      synchronize: true,
      ssl: false,
    }),
    MarketplaceModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: ConsulService,
      useValue: new ConsulService({ serviceName: 'marketplace-service', servicePort: 3004 }),
    },
  ],
})
export class AppModule {}

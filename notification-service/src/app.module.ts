import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NotificationModule } from './notification/notification.module';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { Notification } from './notification/entities/notification.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [Notification],
      synchronize: true,
      ssl: false,
    }),
    NotificationModule,
  ],
  controllers: [HealthController],
  providers: [{
    provide: ConsulService,
    useValue: new ConsulService({ serviceName: 'notification-service', servicePort: 3006 }),
  }],
})
export class AppModule {}

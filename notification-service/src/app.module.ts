import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { NotificationHandler } from './notification/notification.handler';
import { NotificationService } from './notification/notification.service';

const SERVICE_NAME = 'notification-service';
const SERVICE_PORT = 3006;

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
  ],
  controllers: [
    AppController,
    HealthController,
    NotificationHandler,
  ],
  providers: [
    AppService,
    NotificationService,
    {
      provide: ConsulService,
      useValue: new ConsulService({ serviceName: 'notification-service', servicePort: 3006 }),
    },
  ],
})
export class AppModule {}
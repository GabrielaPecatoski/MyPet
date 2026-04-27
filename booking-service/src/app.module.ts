import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true })],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    {
      provide: ConsulService,
      useValue: new ConsulService({
        serviceName: 'booking-service',
        servicePort: 3005,
      }),
    },
  ],
})
export class AppModule {}

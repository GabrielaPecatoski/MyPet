import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { User } from './auth/entities/user.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [User],
      synchronize: true,
      ssl: false,
    }),
    AuthModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: ConsulService,
      useValue: new ConsulService({ serviceName: 'auth-service', servicePort: 3001 }),
    },
  ],
})
export class AppModule {}

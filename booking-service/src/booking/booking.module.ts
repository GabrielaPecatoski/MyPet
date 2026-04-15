import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { Booking } from './entities/booking.entity';
import { BookingController } from './booking.controller';
import { BookingService } from './booking.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Booking]),
    ClientsModule.register([{
      name: 'RABBITMQ_CLIENT',
      transport: Transport.RMQ,
      options: {
        urls: [process.env.RABBITMQ_URL ?? 'amqp://mypet:mypet123@localhost:5672'],
        queue: 'mypet_events',
        queueOptions: { durable: true },
      },
    }]),
  ],
  controllers: [BookingController],
  providers: [BookingService],
})
export class BookingModule {}

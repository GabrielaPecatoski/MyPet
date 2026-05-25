import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from './prisma.service';

export type PaymentMethod = 'PIX' | 'CREDIT_CARD' | 'DEBIT_CARD' | 'CASH' | 'BOLETO';
export type PaymentStatus = 'PENDING' | 'PROCESSING' | 'APPROVED' | 'REJECTED' | 'CANCELLED' | 'REFUNDED';

export interface CreatePaymentDto {
  orderId: string;
  userId: string;
  amount: number;
  method: PaymentMethod;
  deliveryMethod?: 'PICKUP' | 'DELIVERY';
  deliveryAddress?: string;
  cardNumber?: string;
  installments?: number;
}

@Injectable()
export class PaymentService {
  constructor(private readonly prisma: PrismaService) {}

  async processPayment(dto: CreatePaymentDto) {
    const order = await this.prisma.order.findUnique({ where: { id: dto.orderId } });
    if (!order) throw new NotFoundException('Pedido não encontrado');

    const { status, pixKey, boletoCode, cardLastFour, rejectionReason } =
      this.simulate(dto.method, dto.cardNumber);

    const payment = await this.prisma.payment.create({
      data: {
        orderId: dto.orderId,
        userId: dto.userId,
        amount: dto.amount,
        method: dto.method,
        status,
        pixKey,
        boletoCode,
        cardLastFour,
        installments: dto.installments ?? 1,
        deliveryMethod: dto.deliveryMethod ?? 'PICKUP',
        deliveryAddress: dto.deliveryAddress,
        rejectionReason,
        processedAt: status === 'APPROVED' ? new Date() : null,
      },
    });

    const orderStatus =
      status === 'APPROVED' ? 'CONFIRMED'
      : status === 'REJECTED' ? 'PAYMENT_FAILED'
      : 'AWAITING_PAYMENT';

    await this.prisma.order.update({
      where: { id: dto.orderId },
      data: { status: orderStatus },
    });

    return payment;
  }

  async findById(id: string) {
    const payment = await this.prisma.payment.findUnique({
      where: { id },
      include: { order: { include: { items: { include: { product: true } } } } },
    });
    if (!payment) throw new NotFoundException('Pagamento não encontrado');
    return payment;
  }

  async findByOrder(orderId: string) {
    return this.prisma.payment.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findByUser(userId: string) {
    return this.prisma.payment.findMany({
      where: { userId },
      include: { order: { include: { items: { include: { product: true } } } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async cancel(id: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException('Pagamento não encontrado');
    if (!['PENDING', 'PROCESSING'].includes(payment.status)) {
      throw new BadRequestException('Apenas pagamentos pendentes podem ser cancelados');
    }
    const updated = await this.prisma.payment.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });
    await this.prisma.order.update({
      where: { id: payment.orderId },
      data: { status: 'CANCELLED' },
    });
    return updated;
  }

  async refund(id: string) {
    const payment = await this.prisma.payment.findUnique({ where: { id } });
    if (!payment) throw new NotFoundException('Pagamento não encontrado');
    if (payment.status !== 'APPROVED') {
      throw new BadRequestException('Apenas pagamentos aprovados podem ser estornados');
    }
    const updated = await this.prisma.payment.update({
      where: { id },
      data: { status: 'REFUNDED' },
    });
    await this.prisma.order.update({
      where: { id: payment.orderId },
      data: { status: 'REFUNDED' },
    });
    return updated;
  }

  private simulate(method: PaymentMethod, cardNumber?: string) {
    switch (method) {
      case 'PIX':
        return {
          status: 'APPROVED' as PaymentStatus,
          pixKey: `mypet-${Date.now()}-pix@mypet.com`,
          boletoCode: undefined,
          cardLastFour: undefined,
          rejectionReason: undefined,
        };

      case 'DEBIT_CARD':
        return {
          status: 'APPROVED' as PaymentStatus,
          pixKey: undefined,
          boletoCode: undefined,
          cardLastFour: this.lastFour(cardNumber),
          rejectionReason: undefined,
        };

      case 'CREDIT_CARD': {
        const approved = Math.random() > 0.1;
        return {
          status: (approved ? 'APPROVED' : 'REJECTED') as PaymentStatus,
          pixKey: undefined,
          boletoCode: undefined,
          cardLastFour: this.lastFour(cardNumber),
          rejectionReason: approved ? undefined : 'Saldo insuficiente',
        };
      }

      case 'CASH':
        return {
          status: 'PENDING' as PaymentStatus,
          pixKey: undefined,
          boletoCode: undefined,
          cardLastFour: undefined,
          rejectionReason: undefined,
        };

      case 'BOLETO': {
        const code = this.generateBoleto();
        return {
          status: 'PENDING' as PaymentStatus,
          pixKey: undefined,
          boletoCode: code,
          cardLastFour: undefined,
          rejectionReason: undefined,
        };
      }
    }
  }

  private lastFour(cardNumber?: string): string {
    if (!cardNumber) return '0000';
    const digits = cardNumber.replace(/\D/g, '');
    return digits.slice(-4).padStart(4, '0');
  }

  private generateBoleto(): string {
    const rand = () => Math.floor(Math.random() * 10);
    return `23793.38128 ${rand()}${rand()}${rand()}${rand()}${rand()}.677153 ${rand()}${rand()}${rand()}${rand()}${rand()}.000000 1 ${Date.now()}`;
  }
}

import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import nodemailer, { type Transporter } from "nodemailer";

@Injectable()
export class MailService implements OnModuleInit {
  private readonly logger = new Logger(MailService.name);
  private transporter?: Transporter;
  private from = "noreply@mypet.com";

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    const host = this.config.get<string>("MAIL_HOST");
    const port = Number(this.config.get<string>("MAIL_PORT") ?? "587");
    const user = this.config.get<string>("MAIL_USER");
    const pass = this.config.get<string>("MAIL_PASS");
    this.from = this.config.get<string>("MAIL_FROM") ?? "noreply@mypet.com";

    if (!host || !user || !pass) {
      this.logger.warn(
        "Mail not configured (MAIL_HOST/MAIL_USER/MAIL_PASS missing); e-mail disabled.",
      );
      return;
    }

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });

    this.logger.log(`MailService ready (${host}:${port})`);
  }

  async sendWelcome(to: string, name: string): Promise<void> {
    await this.send(
      to,
      "Bem-vindo ao MyPet! 🐾",
      `<h2>Olá, ${name}!</h2>
       <p>Seja bem-vindo ao <strong>MyPet</strong>! Sua conta foi criada com sucesso.</p>
       <p>Agora você pode agendar serviços e cuidar do seu pet favorito.</p>
       <br><p>Equipe MyPet</p>`,
    );
  }

  async sendBookingReceived(
    to: string,
    serviceName: string,
    establishmentName: string,
    scheduledAt: string,
  ): Promise<void> {
    await this.send(
      to,
      "Solicitação de agendamento recebida ⏳",
      `<h2>Recebemos sua solicitação!</h2>
       <p><strong>Serviço:</strong> ${serviceName}</p>
       <p><strong>Estabelecimento:</strong> ${establishmentName}</p>
       <p><strong>Data/Hora:</strong> ${scheduledAt}</p>
       <p>Aguardando confirmação do estabelecimento. Você será notificado em breve.</p>
       <br><p>Equipe MyPet</p>`,
    );
  }

  async sendBookingConfirmed(
    to: string,
    serviceName: string,
    establishmentName: string,
    scheduledAt: string,
  ): Promise<void> {
    await this.send(
      to,
      "Agendamento confirmado ✅",
      `<h2>Seu agendamento foi confirmado!</h2>
       <p><strong>Serviço:</strong> ${serviceName}</p>
       <p><strong>Estabelecimento:</strong> ${establishmentName}</p>
       <p><strong>Data/Hora:</strong> ${scheduledAt}</p>
       <br><p>Equipe MyPet</p>`,
    );
  }

  async sendBookingCancelled(
    to: string,
    serviceName: string,
    establishmentName: string,
  ): Promise<void> {
    await this.send(
      to,
      "Agendamento cancelado ❌",
      `<h2>Seu agendamento foi cancelado</h2>
       <p><strong>Serviço:</strong> ${serviceName}</p>
       <p><strong>Estabelecimento:</strong> ${establishmentName}</p>
       <p>Entre em contato se tiver dúvidas.</p>
       <br><p>Equipe MyPet</p>`,
    );
  }

  async sendOrderPlaced(
    to: string,
    orderId: string,
    total: number,
    itemCount: number,
  ): Promise<void> {
    await this.send(
      to,
      "Pedido realizado com sucesso! 🛍️",
      `<h2>Seu pedido foi registrado!</h2>
       <p><strong>Pedido:</strong> ${orderId}</p>
       <p><strong>Itens:</strong> ${itemCount}</p>
       <p><strong>Total:</strong> R$ ${total.toFixed(2)}</p>
       <br><p>Equipe MyPet</p>`,
    );
  }

  private async send(to: string, subject: string, html: string): Promise<void> {
    if (!this.transporter) {
      this.logger.debug(`[mail skipped – not configured] → ${to}: ${subject}`);
      return;
    }
    try {
      await this.transporter.sendMail({ from: this.from, to, subject, html });
      this.logger.log(`E-mail sent → ${to}: ${subject}`);
    } catch (err) {
      this.logger.error(`E-mail failed → ${to}: ${err}`);
    }
  }
}

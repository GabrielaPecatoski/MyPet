import { Injectable, Logger } from "@nestjs/common";
import { createTransport, type Transporter } from "nodemailer";

export interface SendEmailOptions {
  to: string;
  subject: string;
  text: string;
  html?: string;
}

/**
 * Envio de e-mail por SMTP (nodemailer).
 *
 * Em produção/staging basta configurar as variáveis SMTP_* no ambiente.
 * Se SMTP_HOST não estiver definido (ex.: dev local), o serviço entra em modo
 * fallback e apenas registra o conteúdo do e-mail no log — assim o fluxo de
 * recuperação de senha continua funcionando sem credenciais reais.
 */
@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter: Transporter | null;
  private readonly from: string;

  constructor() {
    this.from = process.env.MAIL_FROM ?? "MyPet <no-reply@mypet.com>";

    const host = process.env.SMTP_HOST;
    if (!host) {
      this.transporter = null;
      this.logger.warn(
        "SMTP_HOST não configurado — e-mails serão apenas registrados no log (modo dev).",
      );
      return;
    }

    this.transporter = createTransport({
      host,
      port: Number(process.env.SMTP_PORT ?? 587),
      secure: process.env.SMTP_SECURE === "true",
      auth:
        process.env.SMTP_USER && process.env.SMTP_PASS
          ? {
              user: process.env.SMTP_USER,
              pass: process.env.SMTP_PASS,
            }
          : undefined,
    });
  }

  async send(options: SendEmailOptions): Promise<void> {
    if (!this.transporter) {
      this.logger.log(
        `[DEV][e-mail simulado] para=${options.to} | assunto="${options.subject}"\n${options.text}`,
      );
      return;
    }

    try {
      await this.transporter.sendMail({
        from: this.from,
        to: options.to,
        subject: options.subject,
        text: options.text,
        html: options.html,
      });
      this.logger.log(
        `E-mail enviado para ${options.to}: "${options.subject}"`,
      );
    } catch (err) {
      this.logger.error(`Falha ao enviar e-mail para ${options.to}`, err);
      throw err;
    }
  }
}

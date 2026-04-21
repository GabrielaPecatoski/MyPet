import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import * as http from 'http';

export interface ConsulConfig {
  serviceName: string;
  servicePort: number;
}

@Injectable()
export class ConsulService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ConsulService.name);
  private readonly consulHost = process.env.CONSUL_HOST ?? 'localhost';
  private readonly consulPort = parseInt(process.env.CONSUL_PORT ?? '8500');
  private serviceId: string;

  constructor(private readonly config: ConsulConfig) {
    this.serviceId = `${config.serviceName}-${Date.now()}`;
  }

  async onModuleInit() {
    await this.register();
  }
  async onModuleDestroy() {
    await this.deregister();
  }

  private register(): Promise<void> {
    const body = JSON.stringify({
      ID: this.serviceId,
      Name: this.config.serviceName,
      Port: this.config.servicePort,
      Check: {
        HTTP: `http://${this.config.serviceName}:${this.config.servicePort}/health`,
        Interval: '10s',
        Timeout: '5s',
        DeregisterCriticalServiceAfter: '30s',
      },
    });
    return this.request('PUT', '/v1/agent/service/register', body)
      .then(() =>
        this.logger.log(
          `Registrado no Consul como "${this.config.serviceName}"`,
        ),
      )
      .catch((err: Error) =>
        this.logger.warn(`Consul indisponível: ${err.message}`),
      );
  }

  private deregister(): Promise<void> {
    return this.request(
      'PUT',
      `/v1/agent/service/deregister/${this.serviceId}`,
      '',
    )
      .then(() => this.logger.log(`Deregistrado do Consul`))
      .catch((err: Error) =>
        this.logger.warn(`Erro ao deregistrar: ${err.message}`),
      );
  }

  private request(method: string, path: string, body: string): Promise<void> {
    return new Promise((resolve, reject) => {
      const req = http.request(
        {
          hostname: this.consulHost,
          port: this.consulPort,
          path,
          method,
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(body),
          },
        },
        (res) =>
          res.statusCode && res.statusCode < 300
            ? resolve()
            : reject(new Error(`${res.statusCode}`)),
      );
      req.on('error', reject);
      if (body) req.write(body);
      req.end();
    });
  }
}

import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private ready = false;

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const serviceAccountJson = this.config.get<string>("FCM_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      this.logger.warn(
        "FCM_SERVICE_ACCOUNT not configured; push notifications disabled.",
      );
      return;
    }
    try {
      const admin = await import("firebase-admin");
      const serviceAccount = JSON.parse(serviceAccountJson) as object;
      if (!admin.default.apps.length) {
        admin.default.initializeApp({
          credential: admin.default.credential.cert(serviceAccount),
        });
      }
      this.ready = true;
      this.logger.log("FCM initialized successfully.");
    } catch (err) {
      this.logger.error(
        "FCM initialization failed (check FCM_SERVICE_ACCOUNT).",
        err,
      );
    }
  }

  async sendPush(token: string, title: string, body: string): Promise<void> {
    if (!this.ready) {
      this.logger.debug(`[push skipped – FCM not configured] title="${title}"`);
      return;
    }
    try {
      const admin = await import("firebase-admin");
      await admin.default
        .messaging()
        .send({ token, notification: { title, body } });
      this.logger.log(`Push sent → title="${title}"`);
    } catch (err) {
      this.logger.error(`Push failed: ${err}`);
    }
  }
}

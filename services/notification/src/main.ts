import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

bootstrapHttpApp(AppModule, {
  title: "Notification Service",
  description: "Gerenciamento de notificações dos usuários",
  port: 3006,
});

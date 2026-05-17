import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

void bootstrapHttpApp(AppModule, {
  title: "MyPet Establishment API",
  description: "Microsserviço de gerenciamento de estabelecimentos e serviços.",
  port: process.env.PORT ?? 3003,
});

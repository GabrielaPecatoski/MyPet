import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

void bootstrapHttpApp(AppModule, {
  title: "MyPet User Auth API",
  description: "Microsserviço de autenticação e gerenciamento de usuários.",
  port: process.env.PORT ?? 3001,
});

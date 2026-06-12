import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

void bootstrapHttpApp(AppModule, {
  title: "MyPet User Pet API",
  description: "Microsserviço de gerenciamento de pets.",
  port: process.env.PORT ?? 3002,
});

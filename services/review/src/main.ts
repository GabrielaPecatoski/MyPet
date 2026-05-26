import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

void bootstrapHttpApp(AppModule, {
  title: "MyPet Review API",
  description: "Microsserviço de avaliações e reclamações.",
  port: process.env.PORT ?? 3007,
});

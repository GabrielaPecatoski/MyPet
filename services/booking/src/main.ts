import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

void bootstrapHttpApp(AppModule, {
  title: "MyPet Booking API",
  description: "Microsserviço de agendamentos e disponibilidade.",
  port: process.env.PORT ?? 3005,
});

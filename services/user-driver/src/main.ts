import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

bootstrapHttpApp(AppModule, {
  title: "Driver Service",
  description: "Registro e gerenciamento de motoristas para transporte de pets",
  port: 3009,
});

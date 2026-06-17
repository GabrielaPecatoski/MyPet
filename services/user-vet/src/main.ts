import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

bootstrapHttpApp(AppModule, {
  title: "Vet Service",
  description: "Registro e gerenciamento de veterinários",
  port: 3010,
});

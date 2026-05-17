import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

void bootstrapHttpApp(AppModule, {
  title: "MyPet Marketplace API",
  description: "Microsserviço de produtos, carrinho e pedidos.",
  port: process.env.PORT ?? 3004,
});

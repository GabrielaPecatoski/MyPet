import { bootstrapHttpApp } from "@shared/infra/http/bootstrap-http-app";
import { AppModule } from "./app.module";

bootstrapHttpApp(AppModule, {
  title: "FAQ Service",
  description: "Gerenciamento de FAQs e perguntas dos usuários",
  port: 3008,
});

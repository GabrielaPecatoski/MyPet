# Pendências — Feature de aprovação do vet/motorista + reconciliação dos testes

> ✅ **CONCLUÍDO em 2026-06-10.** Item (A) (wiring de "Agendar consulta" com `vetId`) já estava
> implementado. Item (B) reconciliado: todos os 13 specs (02, 19, 20, 24, 27, 28, 30, 31, 33, 34,
> 35, 36, 38) passam — suíte completa 85/85.
>
> Estado em 2026-06-08. A **feature está pronta e validada** (backend smoke test verde de
> ponta a ponta; specs de vet **26 (12/12)** e **32 (6/6)** verdes). O que resta é
> (A) uma parte de UI da feature e (B) reconciliar os specs Playwright restantes com o app
> que evoluiu. Os padrões de correção já estão descobertos — é aplicar, um spec por vez.

---

## ✅ Já feito (não precisa refazer)

- **Backend** (`services/establishment`, `services/driver`, `services/booking`):
  - Vet: cadastro entra `PENDENTE`; admin aprova/rejeita; campos `disponivel`/`atendeDomicilio`/`atende24h`;
    `disponivel=true` só após aprovação (senão 403). Endpoints `GET /veterinarians/admin/pending`,
    `GET /veterinarians/available`, `PATCH /veterinarians/:id/approve|reject|availability`.
  - Driver: cadastro `PENDENTE`; `GET /drivers/admin/pending`, `PATCH /drivers/:id/approve|reject`.
  - Booking: `vetId`/`vetName`; **bloqueio de conflito** (mesmo vet + mesmo horário → 409);
    `GET /bookings/vet/:vetId`; booking vinculado aparece na agenda do vet E do estab.
- **Flutter**: gating online vet/motorista, toggles online + emergência 24h + domicílio,
  emergência filtra 24h, agendamento envia `vetId`, agenda do vet (`/bookings/vet/:id`),
  vets vinculados listados no `establishment_detail`.
- **Testabilidade** (beneficia a suíte toda): `AppBottomNav` com `Semantics(excludeSemantics+onTap)`,
  login com re-tap robusto, `_ToggleCard` clicável no card inteiro, helper `SeededUser.cpf` + auto-approve.

---

## (A) Completar a UI da feature — agendar consulta COM um vet específico

Hoje o `establishment_detail_screen` **lista** os vets vinculados (display), mas não há botão
para o cliente **agendar com aquele vet** enviando `vetId`. O backend já suporta.

**O que fazer:**
1. Em `mypet_app/lib/screens/establishment_detail_screen.dart`, no `_vetsSection`, adicionar
   um botão "Agendar consulta" por vet que navega para `/schedule` passando o vet no argumento.
2. Em `mypet_app/lib/screens/schedule_screen.dart`: aceitar `vetId`/`vetName` opcionais no
   argumento da rota e repassá-los em `BookingService.createBooking(... vetId, vetName)`
   (o método já tem os parâmetros).
3. (Opcional) Vet independente (sem estab): permitir agendar direto da lista de emergência
   ou de uma listagem de vets disponíveis (`/veterinarians/available`), com `establishmentId`
   nulo (backend já aceita).

**Validar:** cliente agenda com um vet → booking criado com `vetId` → aparece na agenda do
vet (`/bookings/vet/:id`) E na do estab → 2º agendamento no mesmo horário do vet é bloqueado (409).

---

## (B) Reconciliar os specs Playwright restantes

Vários specs foram escritos para a UI **antiga** e quebraram quando o app evoluiu. **Não é bug
de feature** — é manutenção de teste. Já reconciliei 26 e 32; o **mesmo padrão** resolve os demais.

### Specs a revisar (prioridade)
- `24-register-motorista-vet` — cadastro via welcome → painel
- `30-emergencia-vets` — aba de veterinários na emergência
- `31-home-vet-filter` — filtro de vets na home do cliente
- `34-admin-verificacoes` — admin aprova/rejeita (timeout em retry; **a tela admin está sendo editada**)
- Revisar também os que falhavam no batch original: `02-pets`, `19-preco-variavel`,
  `20-motorista-cadastro`, `27-product-detail`, `28-pedidos-acompanhamento`, `33-estab-vinculos-vet`,
  `35-register-fluxos`, `36-agendamento-vet`, `38-splash-e-auth-flow`.

### Playbook de correção (descoberto nesta sessão)
1. **Olhar o screenshot da falha** em `services/tests/test-results/<spec>/test-failed-1.png`
   ANTES de mexer — diz se é login, texto divergente, ou navegação.
2. **Card/toggle tappável → texto vai pro `aria-label`** (textContent vazio):
   - usar **string exata** em `expectText`/`waitForText` (NÃO regex — regex olha só textContent);
   - clicar via `byText(page, 'texto exato').first().click({ force: true })` (o `tapText`/`leafByText` falha).
3. **Navegação no bottom nav**: usar `pollTap(page, /^Agenda$/, 'probe')` (regex exato evita
   colidir com botões tipo "Ver agenda"). Já corrigido no app via `excludeSemantics`.
4. **Login flaky** já tratado no helper `login` (`_helpers.ts`) — re-tap bounded.
5. **Textos novos do vet home**: "Disponível para atendimento"/"Indisponível"
   ("Aguardando aprovação do admin" se não aprovado); "Atender emergências 24h"/"Emergências 24h
   desativado"; "Atendimento domiciliar ativo/inativo". Vet aprovado começa **offline**.
6. **Helpers** (`_api.ts`): `registerVet`/`registerDriver` já auto-aprovam via admin e usam
   `user.cpf` real (sem isso o painel do vet não carrega → timeout de 2h).

### Como rodar (IMPORTANTE — eficiência)
- **Um spec por vez**, com `--retries=0` para iterar rápido; só rode com retry no fim.
  Runs headed com muitas falhas são lentíssimos (cada falha = timeout cheio; 3 specs ruins = ~55 min).
  ```
  cd services/tests/playwright-front
  npx playwright test 24-register-motorista-vet --retries=0 -g "nome do teste"
  ```
- Filtrar 1 teste com `-g "trecho do nome"` enquanto afina.

---

## Subir a stack (armadilhas de infra desta sessão)

Se o backend não responder (`http://localhost`):
1. **Docker Engine pode estar parado** mesmo com a GUI aberta → iniciar o serviço
   `com.docker.service` (precisa **admin**: `Start-Service com.docker.service`) ou pelo botão da GUI.
2. **`.env` da raiz precisa das creds do Postgres** (o compose usa `${POSTGRES_USER}`):
   ```
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=root
   RABBITMQ_USER=
   RABBITMQ_PASS=
   ```
3. **nginx**: o bloco `listen 80` deve fazer `proxy_pass http://api-gateway:3000` (NÃO `return 301`
   para https — quebra o app/testes que usam http). Certs self-signed em `docker/nginx/certs/`.
4. Subir: `docker compose up -d` (se travar no healthcheck do postgres, use
   `docker compose up -d --no-deps --force-recreate <serviços>`). Serviços: api-gateway, user-auth,
   user-pet, establishment, marketplace, booking, notification, review, faq, user-driver, user-vet.
5. **Admin** (login `admin@mypet.com` / `admin123`): se sumir, recriar via
   `DELETE FROM users WHERE email='admin@mypet.com'` (docker exec psql -U postgres -d mypet_auth)
   + `POST /auth/register` role ADMIN.
6. **Rebuild do Flutter web** após mudar o app: `cd mypet_app && flutter build web --base-href "/"`
   (servido por `python -m http.server 8080` via webServer do Playwright).

Schema: os containers rodam `drizzle-kit push --force` no startup → colunas novas aplicam ao recriar.

---

## Resumo de prioridade
1. **(A)** Wiring de agendamento com `vetId` na UI (completa a feature, é pequeno). ✅
2. **(B)** Reconciliar specs um a um pelo playbook acima, começando pelos de vet (24, 30, 31, 34, 36). ✅
3. Rodar a suíte completa só no fim, para medir. ✅ (85/85)

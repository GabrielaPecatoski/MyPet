# Testes de front (E2E) — UI real do Flutter Web + backend real

Estes testes dirigem a **UI de verdade** do app (Flutter Web, renderizado em
canvas/CanvasKit) num navegador **headed** (não headless), fazendo **chamadas
reais ao backend** (via Nginx em `http://localhost`). Nada é mockado.

## Como funciona

- O app é servido estaticamente a partir de `mypet_app/build/web` (Python http.server
  na porta 8080) — iniciado automaticamente pelo Playwright (`webServer` na config).
- Como o Flutter desenha tudo num `<canvas>`, habilitamos a **árvore de semantics**
  do Flutter (acessibilidade) para que o Playwright enxergue/clique nos widgets.
  Isso é feito por `bootFlutter()`/`enableSemantics()` em `_helpers.ts`.
- Seletores: botões por nome acessível (`getByRole('button', {name})`), textos por
  `textContent` **ou** `aria-label`, inputs por atributo (`data-semantics-role`,
  `autocomplete`, `type`). Ver `_helpers.ts`.
- Dados são semeados pelo backend real em `beforeAll` (`_api.ts`): usuários,
  estabelecimento, serviço, agenda, produto, pet.

## Pré-requisitos

1. Stack no ar: `./start.ps1` (Docker) — `http://localhost/health` deve responder 200.
2. Build web atualizado: `cd mypet_app && flutter build web --base-href /`
   (refazer sempre que mudar o app Flutter).
3. Browser do Playwright: `npx playwright install chromium`.

## Rodar

```powershell
# todos os fluxos
npx playwright test --config playwright.front.config.ts

# um fluxo específico
npx playwright test --config playwright.front.config.ts 04-agend

# relatório HTML
npx playwright show-report playwright-report-front
```

## Fluxos cobertos

| Spec | Fluxo |
|---|---|
| `01-auth` | login válido, login com senha errada, cadastro de cliente pela UI |
| `02-pets` | cadastrar, editar e remover pet |
| `03-loja` | buscar produto → carrinho → pagamento (PIX) |
| `04-agendamento` | abrir estabelecimento → agendar serviço → pagar (dinheiro) |
| `05-perfil` | editar perfil, excluir conta, logout |
| `06-estabelecimento` | login de vendedor → painel → aba Produtos |
| `07-estab-agenda` | estabelecimento vê e confirma um agendamento pago |
| `08-pedidos` | cliente acompanha pedido; estabelecimento avança até finalizado |
| `09-loja-pagamentos` | pagamento de pedido via diferentes métodos |
| `10-carrinho` | adicionar ao carrinho, esvaziar |
| `11-agendamento-cancelar` | cliente cancela agendamento |
| `12-estab-recusa` | estabelecimento recusa agendamento |
| `13-avaliacao` | cliente avalia agendamento concluído |
| `14-faq` | FAQ: listar perguntas e respostas |
| `15-notificacoes` | notificações do usuário |
| `16-estab-produto` | vendedor cadastra produto pela UI |
| `17-cadastro-vendedor` | registro de usuário VENDEDOR pela UI |
| `18-busca-estabelecimento` | busca de estabelecimento na home |
| `19-preco-variavel` | serviço com preço variável: "Sob consulta", sem pagamento, PENDENTE direto |
| `20-motorista-cadastro` | registro de motorista, regra 1 ativo/estab, desativar e cadastrar novo |
| `21-motorista-transporte` | transporte só aparece ao motorista após o estabelecimento aceitar (CONFIRMADO) |
| `22-onboarding` | tela de onboarding e pular |
| `23-welcome-perfil` | tela de boas-vindas e navegação para login/cadastro |
| `24-register-motorista-vet` | registro de usuário MOTORISTA e VETERINÁRIO pela UI |
| `25-motorista-nav` | navegação do motorista: 5 abas, toggle online/offline, ganhos, histórico, perfil |
| `26-veterinario-nav` | navegação do vet: home stats, agenda, chamados, pacientes, perfil |
| `27-product-detail` | tela de detalhe do produto: info, seletor de qty, snackbar, badge carrinho |
| `28-pedidos-acompanhamento` | barra de progresso e filtros (Todos / Em andamento / Finalizados) |

Localização: `services/tests/playwright-front`. As configs (`playwright.front.config.ts`)
ficam na raiz do projeto.

## Mudanças de acessibilidade no app

Para tornar controles só-ícone testáveis (e mais acessíveis), foram adicionados
rótulos: botão "+" de pets (`Semantics`), tooltips "Voltar" (app bar), "Carrinho"
(loja) e "Editar pet"/"Remover pet" (cards de pet).

Adicionados em `product_detail_screen.dart`: `Semantics(button: true, label: ...)` nos
botões `_QtyBtn` ("Diminuir quantidade" / "Aumentar quantidade"), para que o seletor de
quantidade da tela de detalhe seja acionável pelo Playwright.

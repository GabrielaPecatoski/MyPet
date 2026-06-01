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
| `19-preco-variavel` | serviço vet com preço variável: "Sob consulta", sem tela de pagamento, PENDENTE direto |
| `20-motorista-cadastro` | registro de motorista (via gateway), regra 1 ativo/estab, desativar e cadastrar novo |
| `21-motorista-transporte` | transporte só aparece ao motorista depois que o estabelecimento aceita (CONFIRMADO) |

Localização: `services/tests/playwright-front`. As configs (`playwright.front.config.ts`)
ficam na raiz do projeto.

## Mudanças de acessibilidade no app

Para tornar controles só-ícone testáveis (e mais acessíveis), foram adicionados
rótulos: botão "+" de pets (`Semantics`), tooltips "Voltar" (app bar), "Carrinho"
(loja) e "Editar pet"/"Remover pet" (cards de pet).

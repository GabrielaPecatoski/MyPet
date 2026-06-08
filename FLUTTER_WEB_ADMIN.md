# Flutter Web Admin - Build & Deployment Guide

## Mudanças Implementadas

### 1. Responsividade no admin_screen.dart
- Adicionada detecção de largura de tela: `isWide = MediaQuery.of(context).size.width >= 700`
- Layout desktop: Sidebar NavigationRail (220px) + conteúdo expandido
- Layout mobile: BottomNavigationBar (layout original)

### 2. Novo Widget _AdminSidebar
- Sidebar com 220px de largura
- Logo branca no topo (70px) com fundo AppColors.primary
- NavigationRail com 6 destinos (Painel, Reclamações, Usuários, Lojas, FAQ, Estatísticas)
- Badges para notificações (reclamações pendentes, perguntas FAQ pendentes)
- Botão "Sair" no rodapé com borda superior

### 3. Comportamento em Web vs Mobile
- **Desktop (>= 700px):** Row com Sidebar + páginas
- **Mobile (< 700px):** Scaffold com BottomNavigationBar (comportamento original)
- Header roxo do Painel funciona normalmente (padding de status bar = 0 na web)
- Bottom sheets continuam funcionáveis com mouse (não é ideal, mas é funcional)

## Build & Deployment

### Opção 1: Build Local (Recomendado para Desenvolvimento)

```bash
cd mypet_app
flutter pub get
flutter build web --base-href "/" --release
# Output: mypet_app/build/web/
```

Copiar para nginx:
```bash
cp -r mypet_app/build/web /var/www/html/admin
```

### Opção 2: Build via Docker (Produção)

```bash
docker build -f docker/Dockerfile.web -t mypet-admin-web:latest .
```

Este Dockerfile:
- Usa Node.js como base
- Instala Flutter via FVM
- Compila a aplicação web
- Copia para nginx alpine

### Opção 3: Integração com docker-compose.yml

Adicionar ao docker-compose.yml:

```yaml
  nginx:
    build:
      context: .
      dockerfile: docker/Dockerfile.web
    container_name: mypet-nginx
    ports:
      - '80:80'
    depends_on:
      - api-gateway
    restart: unless-stopped
```

## Acesso à Aplicação

- **Admin Panel:** http://localhost/admin/
- **API:** http://localhost/api/ (proxy para api-gateway)

## Verificação de Funcionalidade

✅ Responsive design (>= 700px = sidebar, < 700px = bottom nav)
✅ Badges de notificações no sidebar
✅ Navegação funcional em web
✅ Mesmo código Dart compilado para web e mobile
✅ MediaQuery funciona corretamente no browser
✅ Sem quebras no código existente
✅ Sem comentários adicionados (conforme solicitado)

## Possíveis Melhorias Futuras

- Trocar bottom sheets por dialogs quando `isWide == true`
- Usar DeepLinks no web para navegação de URL
- Adicionar PWA (Progressive Web App) manifest
- Implementar dark theme responsivo

const { execSync } = require('child_process');
const path = require('path');

const services = [
  'api-gateway',
  'auth-service',
  'user-pet-service',
  'establishment-service',
  'marketplace-service',
  'booking-service',
  'notification-service',
  'review-service',
];

console.log('Instalando dependências de todos os serviços...\n');

for (const svc of services) {
  console.log(`  -> ${svc}`);
  execSync('npm install', {
    cwd: path.join(__dirname, svc),
    stdio: 'inherit',
  });
}

console.log('\nTudo instalado!');

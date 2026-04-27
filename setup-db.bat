@echo off
echo ========================================
echo  MyPet - Setup do Banco de Dados
echo ========================================
echo.
echo Cada servico usa seu proprio banco para evitar conflitos.
echo.

echo [1/7] auth-service (mypet_auth)...
cd /d C:\dev\MyPet\auth-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo [2/7] user-pet-service (mypet_users)...
cd /d C:\dev\MyPet\user-pet-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo [3/7] establishment-service (mypet_estab)...
cd /d C:\dev\MyPet\establishment-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo [4/7] marketplace-service (mypet_market)...
cd /d C:\dev\MyPet\marketplace-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo [5/7] booking-service (mypet_booking)...
cd /d C:\dev\MyPet\booking-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo [6/7] notification-service (mypet_notif)...
cd /d C:\dev\MyPet\notification-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo [7/7] review-service (mypet_review)...
cd /d C:\dev\MyPet\review-service
call node_modules\.bin\prisma db push --skip-generate
call node_modules\.bin\prisma generate

echo.
echo ========================================
echo  PRONTO! Banco configurado com sucesso.
echo  Agora rode: npm start
echo ========================================
pause

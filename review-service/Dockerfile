FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 3007

CMD ["sh", "-c", "npx prisma migrate deploy && npx prisma generate && node dist/main"]
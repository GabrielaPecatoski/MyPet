FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npx prisma generate
RUN npm run build

EXPOSE 3006

CMD ["sh", "-c", "npx prisma db push --accept-data-loss && node dist/main"]
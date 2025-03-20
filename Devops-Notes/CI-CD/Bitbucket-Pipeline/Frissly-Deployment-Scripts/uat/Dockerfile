# Stage 1: Build stage
FROM node:20 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Remove this line if no build step is required
# RUN npm run build

# Stage 2: Production stage
FROM node:20-slim

WORKDIR /app

COPY --from=builder /app .

EXPOSE 4001

CMD ["npm", "start"]

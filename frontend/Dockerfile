# Phase 1: Build stage
FROM node:18-alpine as build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
ARG VITE_APP_COLOR_THEME=blue
ARG VITE_APP_VERSION=v1.0.0

ENV VITE_APP_COLOR_THEME=$VITE_APP_COLOR_THEME
ENV VITE_APP_VERSION=$VITE_APP_VERSION

RUN npm run build

# Phase 2: Production environment using unprivileged Nginx
FROM nginxinc/nginx-unprivileged:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

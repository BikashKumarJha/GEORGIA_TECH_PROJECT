# build stage
FROM node:lts-alpine as build-stage
# Install OpenSSL dependencies
RUN apk update && apk add --update --no-cache openssl
# Upgrade OpenSSL to the latest version
RUN apk upgrade --update --no-cache openssl
WORKDIR /app
COPY package*.json ./
COPY mivta.key /root/.aspnet/https/vueapp.key 
COPY mivta.pem /root/.aspnet/https/vueapp.pem
#Run npm install -g npm@10.2.4
#RUN npm audit fix --force 
RUN npm install  --legacy-peer-deps
ENV NODE_OPTIONS=--openssl-legacy-provider
COPY . .
RUN npm run build 
# production stage
FROM nginx:stable-alpine as production-stage
COPY --from=build-stage /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

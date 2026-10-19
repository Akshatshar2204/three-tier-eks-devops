FROM node:14 AS build

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

ENV REACT_APP_BACKEND_URL=/api/tasks
RUN npm run build

FROM nginx:alpine

COPY --from=build /usr/src/app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

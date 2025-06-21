FROM node:20-alpine

WORKDIR /usr/app

# Copy package manifests and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy app source code
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]


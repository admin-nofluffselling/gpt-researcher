# Use Node.js base image
FROM node:18-slim

WORKDIR /usr/src/app

# Copy package files
COPY frontend/nextjs/package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy frontend files
COPY frontend/nextjs/ ./

# Build the application
RUN npm run build

EXPOSE 3000
CMD ["npm", "run", "start"]
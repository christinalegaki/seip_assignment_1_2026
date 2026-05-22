# Base Image
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Caching Optimization: Copy package files first
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy the rest of the application source code
COPY . .

# Port Documentation
EXPOSE 3000

# Command to run the application
CMD [ "npm", "start" ]

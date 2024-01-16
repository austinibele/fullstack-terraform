# Use the official Node.js 16 image as a parent image
FROM node:16-alpine

# Set the working directory
WORKDIR /usr/src/app

# Copy the package.json and package-lock.json (if available)
COPY package*.json ./

# Install the project dependencies
RUN npm install

# Bundle the app source
COPY . .

# Add a simple ExpressJS app
RUN echo "const express = require('express');" > index.js
RUN echo "const app = express();" >> index.js
RUN echo "app.get('/message', (req, res) => res.json({ message: 'Hello from Backend!' }));" >> index.js
RUN echo "app.listen(5252, () => console.log('Backend listening on port 5252'));" >> index.js

# Expose the port the app runs on
EXPOSE 5252

# Define the command to run the app
CMD [ "node", "index.js" ]
# Use a lightweight base image
FROM nginx:alpine

# Define the ARG for the build stage
ARG BACKEND_URL

# Define the ENV for the runtime stage
ENV BACKEND_URL=${BACKEND_URL}

# Copy the static HTML file
COPY index.html /usr/share/nginx/html/index.html

# Copy the custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port 3000
EXPOSE 3000

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# Start Nginx and keep the process in the foreground
CMD ["nginx", "-g", "daemon off;"]
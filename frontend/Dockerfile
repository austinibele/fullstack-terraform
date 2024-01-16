# Use a lightweight base image
FROM nginx:alpine

# Copy the static HTML file
COPY index.html /usr/share/nginx/html/index.html

# Copy the custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 3000
EXPOSE 3000

# Start Nginx and keep the process in the foreground
CMD ["nginx", "-g", "daemon off;"]
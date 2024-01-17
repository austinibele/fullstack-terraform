#!/bin/sh

# Replace the placeholder with the environment variable value
sed -i "s|__BACKEND_URL__|${BACKEND_URL}|g" /usr/share/nginx/html/index.html

# Execute the CMD from the Dockerfile with arguments passed to the entrypoint
exec "$@"
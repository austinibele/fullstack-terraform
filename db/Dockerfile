# Dockerfile
FROM postgres:16.1

# Copy the init.sql script to the docker-entrypoint-initdb.d directory
# so it will be executed during the container startup
COPY init.sql /docker-entrypoint-initdb.d/
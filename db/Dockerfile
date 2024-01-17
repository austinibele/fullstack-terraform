# Dockerfile
FROM postgres:16.1

# Set environment variables
ENV POSTGRES_DB=mydb
ENV POSTGRES_USER=dbuser
ENV POSTGRES_PASSWORD=postgres

# Copy the init.sql script to the docker-entrypoint-initdb.d directory
# so it will be executed during the container startup
COPY init.sql /docker-entrypoint-initdb.d/

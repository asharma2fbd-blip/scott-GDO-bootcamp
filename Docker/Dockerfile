# Use the lightweight Alpine Linux version of Nginx to reduce image size
FROM nginx:alpine

# Remove the default Nginx landing page
RUN rm /usr/share/nginx/html/index.html

# Copy our custom color-changing HTML file into the container
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 to tell Docker the container listens on this port
EXPOSE 80
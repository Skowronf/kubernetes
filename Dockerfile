FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/*.jar app.jar

# Create a non-root application user and group.
# Assign ownership of application files to allow the app
# to run securely without root privileges.
RUN groupadd -g 30001 appgroup && \
    useradd -u 10001 -g 30001 -m appuser && \
    chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
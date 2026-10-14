# service-api-marketplace built from source on public Temurin (the repo's image needs an ACR login)
FROM eclipse-temurin:25-jdk AS build
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.gradle ./gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:25-jre
WORKDIR /opt/app
COPY --from=build /src/build/libs/apim-marketplace.jar app.jar
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/opt/app/app.jar"]

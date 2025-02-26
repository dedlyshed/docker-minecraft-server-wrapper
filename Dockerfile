FROM eclipse-temurin:21-jdk-alpine

WORKDIR /server

RUN apk add --no-cache screen

COPY ./server /server
RUN chmod +x /server/entrypoint.sh

RUN wget -O fabric-server.jar https://meta.fabricmc.net/v2/versions/loader/1.20.1/0.16.10/1.0.1/server/jar \
    && echo "eula=true" > eula.txt

EXPOSE 25565

CMD ["/server/entrypoint.sh"]

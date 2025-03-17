FROM eclipse-temurin:21-jdk-alpine

WORKDIR /server/data

RUN wget -O /tmp/rcon.tar.gz https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz
RUN tar -xzf /tmp/rcon.tar.gz -C /tmp

RUN mv /tmp/rcon-0.10.3-amd64_linux/rcon /usr/local/bin/rcon-cli \
    && chmod +x /usr/local/bin/rcon-cli \
    && rm -rf /tmp/rcon-0.10.3-amd64_linux /tmp/rcon.tar.gz

COPY ./build-files /server
RUN chmod +x /server/entrypoint.sh

EXPOSE 25565

ENTRYPOINT [ "/server/entrypoint.sh" ]
CMD ["-Xmx1024M", "-Xms1024M", "-jar", "mc-server.jar", "nogui"]

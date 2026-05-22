FROM eclipse-temurin:21-jdk-alpine

WORKDIR /server/data

RUN wget -O /tmp/rcon.tar.gz https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz \
    && tar -xzf /tmp/rcon.tar.gz -C /tmp \
    && mv /tmp/rcon-0.10.3-amd64_linux/rcon /usr/local/bin/rcon-cli \
    && chmod +x /usr/local/bin/rcon-cli \
    && rm -rf /tmp/rcon-0.10.3-amd64_linux /tmp/rcon.tar.gz

RUN wget -O /tmp/s5cmd.tar.gz \
      https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_Linux-64bit.tar.gz \
    && tar -xzf /tmp/s5cmd.tar.gz -C /tmp \
    && mv /tmp/s5cmd /usr/local/bin/s5cmd \
    && chmod +x /usr/local/bin/s5cmd \
    && rm -rf /tmp/s5cmd.tar.gz

COPY ./build-files /server
RUN chmod +x /server/entrypoint.sh /server/backup.sh /server/s3-upload.sh

EXPOSE 25565

ENTRYPOINT [ "/server/entrypoint.sh" ]
CMD ["-Xmx1024M", "-Xms1024M", "-jar", "mc-server.jar", "nogui"]

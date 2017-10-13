FROM alpine:3.6

RUN apk update && apk upgrade && apk add --no-cache curl gcc build-base make mariadb-dev perl perl-dev expat-dev wget

RUN curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
 && chmod +x cpanm \
 && ./cpanm App::cpanminus \
 && rm -rf ./cpanm /root/.cpanm

RUN cpanm -n Carton && mkdir -p /usr/src/cap
WORKDIR /usr/src/cap

COPY cpanfile* /usr/src/cap/
RUN carton install --deployment; exit 0

RUN cat /root/.cpanm/work/*/build.log; exit 1

COPY . /usr/src/cap

EXPOSE 3000
ENTRYPOINT ["carton", "exec", "starman", "cap.psgi", "-Ilib"]
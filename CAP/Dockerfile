FROM perl:5.24.2

RUN cpanm -n Carton && mkdir -p /opt/cap
WORKDIR /opt/cap

COPY cpanfile* /opt/cap/

RUN carton install --deployment || (cat /root/.cpanm/work/*/build.log && exit 1)

COPY *.conf cap.psgi /opt/cap/
COPY conf /opt/cap/conf/
COPY lib /opt/cap/lib/
COPY root /opt/cap/root/

EXPOSE 3000
ENTRYPOINT ["carton", "exec"]
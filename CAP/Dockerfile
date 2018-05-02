FROM perl:5.24.2

RUN groupadd -g 1115 cihm && useradd -u 1015 -g cihm -m cihm && \
    cpanm -n Carton && mkdir -p /opt/cap && ln -s cap/log4perl.conf /opt/log4perl.conf

WORKDIR /opt/cap

COPY cpanfile* /opt/cap/

RUN carton install --deployment || (cat /root/.cpanm/work/*/build.log && exit 1)

COPY *.conf cap.psgi /opt/cap/
COPY conf /opt/cap/conf/
COPY lib /opt/cap/lib/
COPY root /opt/cap/root/
copy util /opt/cap/util/

# Useful for determining what revision is running. Should we filter any keys?
# See: http://www.canadiana.ca/static/capsvninfo.txt
copy .svn/ /opt/cap/.svn/
RUN svn info /opt/cap/ > /opt/cap/root/static/capsvninfo.txt

USER cihm

EXPOSE 3000
ENTRYPOINT ["carton", "exec"]

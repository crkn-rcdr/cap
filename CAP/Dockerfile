FROM perl:5.28.1

RUN groupadd -g 1115 cihm && useradd -u 1015 -g cihm -m cihm && \
  cpanm -n Carton && mkdir -p /opt/cap && \
  ln -s cap/log4perl.conf /opt/log4perl.conf && \
  mkdir -p /var/log/cap ; chown cihm.cihm /var/log/cap

WORKDIR /opt/cap

COPY cpanfile* /opt/cap/

RUN carton install --deployment || (cat /root/.cpanm/work/*/build.log && exit 1)

COPY *.conf cap.psgi /opt/cap/
COPY conf /opt/cap/conf/
COPY lib /opt/cap/lib/
COPY root/static /opt/cap/root/static
COPY root/templates /opt/cap/root/templates
COPY util /opt/cap/util/

USER cihm

# See cap.env.example for required config which is not stored in the repository
ENV CATALYST_DEBUG=0 \
  CAP_Model::Access::Derivative_endpoint=http://image.romano.canadiana.ca/iiif/2 \
  CAP_Model::Access::Derivative_cookie_domain=image.romano.canadiana.ca \
  CAP_Model::Access::Download::ZFS_endpoint=http://file.paneer.canadiana.ca \
  CAP_Model::Access::Presentation_server=http://iris.tor.c7a.ca:5984/copresentation \
  CAP_Model::Access::Presentation_prezi_demo_endpoint=http://presentation.demo.canadiana.ca/iiif \
  CAP_Model::Access::Search_server=http://iris.tor.c7a.ca:8983/solr/cosearch \
  CAP_Model::Collections_server=http://iris.tor.c7a.ca:5984/collection \
  CAP_Model::Parl_server=http://iris.tor.c7a.ca:5984/copresentation \
  CAP_Model::ParlSession_server=http://iris.tor.c7a.ca:5984/parl_session \
  CAP_Model::UsageStats_statsdb=http://iris.tor.c7a.ca:5984/cap_usage_stats \
  CAP_Model::UsageStats_logfiledb=http://iris.tor.c7a.ca:5984/cap_logfile_registry \
  LOGLEVELSCREEN=WARN \
  LOGFILENAME=/var/log/cap/request.log \
  TZ=America/Toronto

EXPOSE 3011
ENTRYPOINT ["carton", "exec"]
CMD ["starman", "cap.psgi", "-Ilib", "--port", "3011", "--workers", "8"]

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

USER cihm

ENV CATALYST_DEBUG=0 \
  CAP_Model::Access::Derivative_key=CAP \
  CAP_Model::Access::Derivative_endpoint=http://image-tor.canadiana.ca/iiif/2 \
  CAP_Model::Access::Download::ZFS_key=CAP \
  CAP_Model::Access::Download::ZFS_endpoint=http://file-tor.canadiana.ca \
  CAP_Model::Access::Download::Swift_container=https://swift.canadiana.ca/v1/AUTH_crkn/repository \
  CAP_Model::Access::Presentation_download_mode=swift \
  CAP_Model::Access::Presentation_server=http://iris.tor.c7a.ca:5984/copresentation \
  CAP_Model::Access::Search_server=http://iris.tor.c7a.ca:8983/solr/cosearch \
  CAP_Model::Collections_server=http://iris.tor.c7a.ca:5984/cap_collections \
  CAP_Model::Parl_server=http://iris.tor.c7a.ca:5984/copresentation \
  CAP_Model::ParlSession_server=http://iris.tor.c7a.ca:5984/parl_session

EXPOSE 3011
ENTRYPOINT ["carton", "exec"]
CMD ["starman", "cap.psgi", "-Ilib", "--port", "3011", "--workers", "8"]

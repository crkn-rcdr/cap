FROM perl:5.32

WORKDIR /opt/cap
COPY cpanfile /opt/cap/

RUN cpanm --installdeps --local-lib local/ --notest --quiet .

COPY . /opt/cap/

RUN groupadd -g 1115 cihm && useradd -u 1015 -g cihm -m cihm
USER cihm

ENV WORKERS=8 \
  CATALYST_DEBUG=0 \
  CAP_Model::Access::Derivative_endpoint=https://image-tor.canadiana.ca/iiif/2 \
  CAP_Model::Access::Download_container=https://swift.canadiana.ca/v1/AUTH_crkn/repository \
  CAP_Model::Access::Presentation_server=http://iris.tor.c7a.ca:5984/copresentation \
  CAP_Model::Access::Search_server=http://iris.tor.c7a.ca:8983/solr/cosearch \
  CAP_Model::Collections_server=http://iris.tor.c7a.ca:5984/cap_collections \
  CAP_Model::Parl_server=http://iris.tor.c7a.ca:5984/copresentation \
  CAP_Model::ParlSession_server=http://iris.tor.c7a.ca:5984/parl_session

EXPOSE 3011

CMD [ \
  "perl", \
  "-Ilocal/lib/perl5", \
  "-Ilib", \
  "local/bin/starman", \
  "cap.psgi", \
  "--listen", \
  ":3011", \
  "--workers", \
  "$WORKERS" ]

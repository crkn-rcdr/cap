FROM perl:5.32

WORKDIR /opt/cap
COPY cpanfile /opt/cap/

RUN cpanm --installdeps --local-lib local/ --notest --quiet .

COPY . /opt/cap/

RUN groupadd -g 1115 cihm && useradd -u 1015 -g cihm -m cihm
USER cihm

ENV WORKERS=8 \
  CATALYST_DEBUG=0 \
  CAP_Model::Presentation_image_endpoint=https://image-tor.canadiana.ca/iiif/2 \
  CAP_Model::Presentation_swift_container_preservation=https://swift.canadiana.ca/v1/AUTH_crkn/preservation-cihm-aip \
  CAP_Model::Presentation_swift_container_access=https://swift.canadiana.ca/v1/AUTH_crkn/access-files \
  # CAP_Model::Presentation_swift_temp_url_key=${cappassword} (set this one elsewhere)
  CAP_Model::Presentation_server=http://traminac.tor.c7a.ca:5984/copresentation2 \
  CAP_Model::Search_server=http://traminac.tor.c7a.ca:8983/solr/cosearch2 \
  CAP_Model::Parl_server=http://traminac.tor.c7a.ca:5984/copresentation2 

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

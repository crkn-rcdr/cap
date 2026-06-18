FROM perl:5.32

WORKDIR /opt/cap
COPY cpanfile /opt/cap/

RUN cpanm --installdeps --local-lib local/ --notest --quiet .

COPY . /opt/cap/

RUN groupadd -g 1115 cihm && useradd -u 1015 -g cihm -m cihm
USER cihm

ENV WORKERS=8 \
  CATALYST_DEBUG=0

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

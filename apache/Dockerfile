FROM httpd:2.4.41

RUN sed -i \
    -e 's/^#\(Include .*vhosts.conf\)/\1/' \
    -e 's/^#\(Include .*httpd-mpm.conf\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy_http.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy_html.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_xml2enc.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_allowmethods.so\)/\1/' \
    conf/httpd.conf ; \
    sed -i \
    -e 's/logs\/httpd.pid/httpd.pid/' \
    conf/extra/httpd-mpm.conf

RUN apt-get update ; apt-get install -yq subversion && apt-get clean && \
    svn co --trust-server-cert https://github.com/crkn-rcdr/Digital-Preservation.git/trunk/xml/published/ /usr/local/apache2/htdocs/xml-published/

# This should be changed when running container to the correct host and post for the relevant instance.  This is only Dev.
ENV CDNHOSTPORT gouda.tor.c7a.ca:5984

# In production the docker-compose will launch a Cantaloupe along with CAP
# Set this to a running Cantaloupe if you wish to test this aspect.
ENV CIHM_CANTALOUPE vbc.canadiana.ca

COPY cihm-error /usr/local/apache2/htdocs/cihm-error/
COPY httpd-vhosts.conf /usr/local/apache2/conf/extra/

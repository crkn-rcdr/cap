# CAP's Apache configuration

Apache is used as a front-end in front of CAP, and is the service that binds to a public port. It handles a number of different groups of URLs.

## first (and thus default) configuration

Offers a proxy to the CAP container, with only a few exceptions.

* files under /cihm-error/ which offer the error documents for 500 and 503 errors.
  * http://heritage.canadiana.ca/cihm-error/500.html

* files under /schema and /standards/ which offer static XML documentation.
  * http://www.canadiana.ca/schema/2012/txt/aip.txt
  * http://www.canadiana.ca/standards/schema/2012/txt/aip.txt
  
## cdn.canadiana.ca

Offers special GET-only proxy to a cdn Couch Database

  * http://cdn.canadiana.ca/online/monog-block.jpg
  
##  dfait-aeci.canadiana.ca redirect

  * http://dfait-aeci.canadiana.ca redirecting to current http://gac.canadiana.ca/ name
  
## canadianaonline.ca redirect

  * http://canadianaonline.ca http://www.canadianaonline.ca http://canadianaenligne.ca http://www.canadianaenligne.ca redirecting

##   www.canadiana.org

We previously hosted an ECO platform (mod_perl scripts) prior to creating the CAP platform which handled multiple portals and multiple depositors.

This configuration redirects the old URLs to the new format.

  * http://www.canadiana.org/ECO/mtq?doc=00001
  * http://www.canadiana.org/record/8_06638_23
  * http://www.canadiana.org/ECO/PageView/09514/0186?id=4197335cc9aaee1a (Example taken from references on a research paper on google books)

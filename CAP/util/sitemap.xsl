<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:param name="sitemaptype"></xsl:param>

  <xsl:template match="response">
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <xsl:apply-templates select="*/doc"/>
    </urlset>
  </xsl:template>

  <xsl:template match="doc">
    <url xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <xsl:choose>
        <xsl:when test="$sitemaptype = 'local'">
          <loc xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <xsl:value-of select="concat('http://search.canadiana.ca/view/', str[@name='key'])"/>
          </loc>
        </xsl:when>
        <xsl:otherwise>
          <loc xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><xsl:apply-templates select="str[@name='canonicalUri']"/></loc>
        </xsl:otherwise>
      </xsl:choose>
      <changefreq xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">monthly</changefreq>
    </url>
  </xsl:template>

</xsl:stylesheet>

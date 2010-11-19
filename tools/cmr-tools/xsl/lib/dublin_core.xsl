<?xml version="1.0" encoding="UTF-8"?>

<!--

  2010-11-19

  cmr_dc:record - parse a Dublin Core record.

  Parameters:
  contributor - required
  key - defaults to the value of dc:identifier[position()=1]
  canonicalUri - defaults to dc:identifier[position()=last()]

-->

<xsl:stylesheet version="1.0"
  xmlns:cmr="http://www.canadiana.ca/XML/cmr-util"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:cmr_dc="http://www.canadiana.ca/XML/cmr-dc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="cmr dc cmr_dc"
>

  <xsl:import href="cmr.xsl"/>

  <xsl:template name="cmr_dc:record">
    <xsl:param name="contributor"/>
    <xsl:param name="key"/>
    <xsl:param name="canonicalUri"/>

    <record>
      <type>monograph</type>
      <contributor><xsl:value-of select="normalize-space($contributor)"/></contributor>
      <key>
        <xsl:choose>
          <xsl:when test="normalize-space($key)">
            <xsl:value-of select="normalize-space($key)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space(dc:identifier[position()=1])"/>
          </xsl:otherwise>
        </xsl:choose>
      </key>
      <label><xsl:value-of select="normalize-space(dc:title[position()=1])"/></label>

      <xsl:if test="dc:date">
        <pubdate min="{descendant::dc:date[position()= 1]}" max="{descendant::dc:date[position()=1]}"/>
      </xsl:if>
    
      <xsl:for-each select="dc:language">
        <xsl:call-template name="cmr:lang"/>
      </xsl:for-each>

      <xsl:for-each select="dc:type">
        <xsl:call-template name="cmr:media"/>
      </xsl:for-each>

      <description>
        <!-- Not included (at this time): language, identifier -->

        <xsl:for-each select="descendant::dc:contributor">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="type">source</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:coverage">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="type">coverage</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:creator">
          <xsl:call-template name="cmr:author"/>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:date">
          <xsl:call-template name="cmr:publication"/>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:description">
          <xsl:call-template name="cmr:text">
            <xsl:with-param name="type">description</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:format">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="type">extent</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:publisher">
          <xsl:call-template name="cmr:publication"/>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:relation">
          <xsl:call-template name="cmr:note"/>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:rights">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="type">rights</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:source">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="type">source</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:subject">
          <xsl:call-template name="cmr:subject"/>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:title">
          <xsl:call-template name="cmr:title"/>
        </xsl:for-each>

        <xsl:for-each select="descendant::dc:type">
          <xsl:call-template name="cmr:note"/>
        </xsl:for-each>

      </description>

      <resource>
        <canonicalUri>
          <xsl:choose>
            <xsl:when test="$canonicalUri">
              <xsl:value-of select="normalize-space($canonicalUri)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="normalize-space(dc:identifier[position()=last()])"/>
            </xsl:otherwise>
          </xsl:choose>
        </canonicalUri>
      </resource>

    </record>

  </xsl:template>

</xsl:stylesheet>


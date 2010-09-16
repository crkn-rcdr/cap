<?xml version="1.0" encoding="UTF-8"?>

<!--
  University of British Columbia
  CONTENTdm OAI metadata
  http://angel.library.ubc.ca/cgi-bin/oai.exe
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:cmr_dc="http://www.canadiana.ca/XML/cmr-dc"
  exclude-result-prefixes="oai dc oai_dc cmr_dc"
>

<xsl:import href="lib/dc.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <recordset version="1.0">
      <xsl:apply-templates select="descendant::oai:record"/>
      <filters>
        <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
        <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
        <filter xpath="//record/pubdate[@min = '']" type="delete"/>
        <filter xpath="//record/pubdate[@max = '']" type="delete"/>
      </filters>
    </recordset>
  </xsl:template>

  <xsl:template match="oai:record">
    <record>
      <type>monograph</type>
      <contributor>bvau</contributor>
      <key><xsl:value-of select="translate(oai:header/oai:identifier, '/:', '..')"/></key>
      <label>
        <xsl:choose>
          <xsl:when test="descendant::dc:title"><xsl:value-of select="descendant::dc:title[position()=1]"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="descendant::dc:identifier[position()=1]"/></xsl:otherwise>
        </xsl:choose>
      </label>
      <xsl:if test="descendant::dc:date">
        <pubdate min="{descendant::dc:date[position()= 1]}" max="{descendant::dc:date[position()=1]}"/>
      </xsl:if>
      <xsl:for-each select="descendant::dc:language">
        <xsl:call-template name="cmr_dc:lang">
          <xsl:with-param name="string" select="."/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:for-each select="descendant::dc:type">
        <xsl:call-template name="cmr_dc:media">
          <xsl:with-param name="string" select="."/>
        </xsl:call-template>
      </xsl:for-each>

      <description>
        <xsl:call-template name="cmr_dc:description">
          <xsl:with-param name="metadata" select="oai:metadata"/>
        </xsl:call-template>
      </description>

      <resource>
        <canonicalUri><xsl:value-of select="descendant::dc:identifier[position() = last()]"/></canonicalUri>
      </resource>
    </record>
  </xsl:template>

</xsl:stylesheet>


<?xml version="1.0" encoding="UTF-8"?>

<!--

  2010-11-19

  MUN - Memorial University

  OAI Dublin Core records

-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:cmr="http://www.canadiana.ca/XML/cmr-util"
  xmlns:cmr_dc="http://www.canadiana.ca/XML/cmr-dc"
  exclude-result-prefixes="oai oai_dc dc cmr cmr_dc"
>

  <xsl:import href="lib/dublin_core.xsl"/>
  <xsl:import href="lib/cmr.xsl"/>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:param name="contributor">mun</xsl:param>

  <xsl:template match="/">
    <recordset version="1.0">
      <xsl:apply-templates select="descendant::oai_dc:dc"/>
    </recordset>
  </xsl:template>

  <xsl:template match="oai_dc:dc">
    <xsl:call-template name="cmr_dc:record">
      <xsl:with-param name="contributor" select="$contributor"/>
      <xsl:with-param name="key" select="substring-after(dc:identifier[position()=last()]/text(), '/u?/')"/>
      <xsl:with-param name="canonicalUri" select="dc:identifier[position()=last()]"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>

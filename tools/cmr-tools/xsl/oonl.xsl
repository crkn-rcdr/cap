<?xml version="1.0" encoding="UTF-8"?>

<!--

  2010-12-09

  Library and Archives Canada (oonl)

-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:cmr_marc="http://www.canadiana.ca/XML/cmr-marc"
  exclude-result-prefixes="marc cmr_marc"
>

  <xsl:import href="lib/marcxml.xsl"/>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:param name="contributor">oonl</xsl:param>

  <xsl:template match="/">
    <recordset version="1.1">
      <xsl:apply-templates select="*/marc:record"/>
    </recordset>
  </xsl:template>

  <xsl:template match="marc:record">
    <xsl:call-template name="cmr_marc:record">
      <xsl:with-param name="contributor" select="$contributor"/>
      <xsl:with-param name="key" select="marc:controlfield[@tag='001']"/>
    </xsl:call-template>
  </xsl:template>


</xsl:stylesheet>

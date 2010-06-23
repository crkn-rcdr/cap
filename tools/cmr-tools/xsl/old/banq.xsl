<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="record">
  <xsl:copy>

    <xsl:if test="metadata/dc/type/text() = 'titre'">
      <CMR_clabel><xsl:value-of select="metadata/dc/title"/></CMR_clabel>
      <CMR_key><xsl:value-of select="header/setSpec"/></CMR_key>
      <CMR_pubdate min="{metadata/dc/date[position()=1]}" max="{metadata/dc/date[position()=2]}"/>
    </xsl:if>
    <xsl:if test="metadata/dc/type/text() = 'fascicule'">
      <CMR_clabel><xsl:value-of select="metadata/dc/specificcontent"/></CMR_clabel>
      <CMR_key><xsl:value-of select="substring(header/identifier, 28)"/></CMR_key>
      <CMR_pkey><xsl:value-of select="header/setSpec"/></CMR_pkey>
      <CMR_seq><xsl:value-of select="substring(header/identifier, 34)"/></CMR_seq>
      <CMR_pubdate min="{metadata/dc/date[position()=3]}" max="{metadata/dc/date[position()=3]}"/>
    </xsl:if>

    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="*|@*">
  <xsl:copy>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>
            
</xsl:stylesheet>



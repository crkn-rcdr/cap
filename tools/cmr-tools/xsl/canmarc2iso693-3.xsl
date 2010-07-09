<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--
  Convert CanMARC language codes into their ISO 693-3 equivalents.
  
  This stylesheet is a work in progress. There is a great deal of overlap
  between the two schema; only codes which differ between the two need to
  be added here.
-->

<xsl:template name="canmarc2iso693-3">
  <xsl:param name="lang"/>
  <xsl:choose>
    <xsl:when test="$lang = 'fre'">fra</xsl:when><!-- French -->
    <xsl:when test="$lang = 'ger'">deu</xsl:when><!-- German -->
    <xsl:otherwise><xsl:value-of select="$lang"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

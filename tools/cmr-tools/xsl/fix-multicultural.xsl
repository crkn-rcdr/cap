<?xml version="1.0" encoding="UTF-8"?>

<!--
  Use this stylesheet to modify existing CMR records. By default, we
  simply copy through the entire source record; import or add templates to
  modify the source.
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- E.g. change canmarc language codes to ISO-693-3 -->
<!--
<xsl:import href="canmarc2iso693-3.xsl"/>
-->

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="/|@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- E.g. delete all clabel elements -->
<!--
<xsl:template match="clabel"/>
-->

<!-- Fix the key and pkey -->
<xsl:template match="pkey">
  <pkey>
    <xsl:call-template name="chomp">
      <xsl:with-param name="string" select="."/>
    </xsl:call-template>
  </pkey>
</xsl:template>

<xsl:template match="key[contains(text(), '.Array')]">
  <key><xsl:value-of select="../pkey"/></key>
</xsl:template>

<!-- Add the Chinese title if it is missing -->
<xsl:template match="title[@lang='zho'][substring(text(), 1, 1) = ',']">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:value-of select="concat('大漢公報', .)"/>
  </xsl:copy>
</xsl:template>

<xsl:template name="chomp">
  <xsl:param name="string"/>
  <xsl:choose>
    <xsl:when test="contains(substring-after($string, '.'), '.')">
      <xsl:call-template name="chomp">
        <xsl:with-param name="string">
          <xsl:value-of select="substring($string, 1, string-length($string) - 1)"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$string"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

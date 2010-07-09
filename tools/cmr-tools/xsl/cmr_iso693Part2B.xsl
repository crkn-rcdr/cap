<?xml version="1.0" encoding="UTF-8"?>

<!--
  This stylesheet will copy through a CMR record, changing ISO 693-2
  Part2B language codes to their ISO 693-3 equivalents. If you generated
  CMR records containing Part2B codes, use this stylesheet to change them
  into their Part3 counterparts.

  Stylesheet version: 1.0 (2010-07-07)
  Compatible with: CMR version 1.x
  Send bug reports to: william.wueppelmann@canadiana.ca
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="/|@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="@lang">
  <xsl:attribute name="lang">
    <xsl:call-template name="iso693-2">
      <xsl:with-param name="lang"><xsl:value-of select="."/></xsl:with-param>
    </xsl:call-template>
  </xsl:attribute>
</xsl:template>

<xsl:template match="lang">
  <lang>
    <xsl:call-template name="iso693-2">
      <xsl:with-param name="lang"><xsl:value-of select="."/></xsl:with-param>
    </xsl:call-template>
  </lang>
</xsl:template>

<xsl:template name="iso693-2">
  <xsl:param name="lang"/>
  <xsl:choose>
    <xsl:when test="$lang = 'arm'">hye</xsl:when><!-- Armenian -->
    <xsl:when test="$lang = 'alb'">sqi</xsl:when><!-- Albanian -->
    <xsl:when test="$lang = 'baq'">eus</xsl:when><!-- Basque -->
    <xsl:when test="$lang = 'bur'">mya</xsl:when><!-- Burmese -->
    <xsl:when test="$lang = 'chi'">zho</xsl:when><!-- Chinese -->
    <xsl:when test="$lang = 'cze'">ces</xsl:when><!-- Czech -->
    <xsl:when test="$lang = 'dut'">nld</xsl:when><!-- Dutch -->
    <xsl:when test="$lang = 'fre'">fra</xsl:when><!-- French -->
    <xsl:when test="$lang = 'ger'">deu</xsl:when><!-- German -->
    <xsl:when test="$lang = 'geo'">kat</xsl:when><!-- Georgian -->
    <xsl:when test="$lang = 'gre'">ell</xsl:when><!-- Greek (modern) -->
    <xsl:when test="$lang = 'ice'">isl</xsl:when><!-- Icelandic -->
    <xsl:when test="$lang = 'mac'">mkd</xsl:when><!-- Macedonian -->
    <xsl:when test="$lang = 'mao'">mri</xsl:when><!-- Maori -->
    <xsl:when test="$lang = 'may'">msa</xsl:when><!-- Maylay -->
    <xsl:when test="$lang = 'per'">fas</xsl:when><!-- Persian -->
    <xsl:when test="$lang = 'rum'">ron</xsl:when><!-- Romanian -->
    <xsl:when test="$lang = 'slo'">slk</xsl:when><!-- Slovak -->
    <xsl:when test="$lang = 'tib'">bod</xsl:when><!-- Tibetan -->
    <xsl:when test="$lang = 'wel'">cym</xsl:when><!-- Welsh -->
    <xsl:otherwise><xsl:value-of select="$lang"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

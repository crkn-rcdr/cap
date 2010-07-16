<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--
  Convert CAN/MARC Appendix C.1 language codes into their ISO 693-3
  equivalents.

  Most codes are identical between the two standards and are therefore
  ommitted.

  This list is (almost certainly) not comprehensive; it is intended to be
  added to on an ongoing basis.

  There are several codes for language families that do not map to a
  specific ISO 693-3 code, but which also don't conflict with the 693-3,
  and so can be used as-is if the actual language isn't known. Some of
  these include:

  alg
  ath
  cpe
  iro
  nai
  sal
-->

<xsl:template name="canmarc2iso693-3">
  <xsl:param name="lang"/>
  <xsl:choose>
    <xsl:when test="$lang = 'alb'">sqi</xsl:when><!-- Albanian -->
    <xsl:when test="$lang = 'arm'">hye</xsl:when><!-- Armenian -->
    <xsl:when test="$lang = 'baq'">eus</xsl:when><!-- Basque -->
    <xsl:when test="$lang = 'bur'">mya</xsl:when><!-- Burmese -->
    <xsl:when test="$lang = 'chi'">zho</xsl:when><!-- Chinese -->
    <xsl:when test="$lang = 'cze'">ces</xsl:when><!-- Czech -->
    <xsl:when test="$lang = 'dut'">nld</xsl:when><!-- Dutch -->
    <xsl:when test="$lang = 'fre'">fra</xsl:when><!-- French -->
    <xsl:when test="$lang = 'gae'">gla</xsl:when><!-- Gaelic (Scottish) -->
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

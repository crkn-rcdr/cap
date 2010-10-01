<?xml version="1.0" encoding="UTF-8"?>

<!--
  marcxml.xsl

  This stylesheet provides templates for generating CMR 1.0 fields from a
  MARCXML source record. Import into a primary stylesheet and use the
  templates to generate fields such as the descriptive fields and language
  codes.

  The descriptive field mappings (title, author, etc.) are probably not
  exhaustive. This is a work in progress.
  
  Author: William Wueppelmann <william.wueppelmann@canadiana.ca>
  Revision: 2010-08-17
-->

<xsl:stylesheet version="1.0"
  xmlns:marcxml="http://www.canadiana.ca/XML/cmr-marcxml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
>


<!-- Split a string into 3-letter language codes and generate <lang>
values for each. -->
<xsl:template name="marcxml:languages">
  <xsl:param name="langstr"/>
  <xsl:if test="string-length($langstr) &gt;= 3">
    <lang>
      <xsl:call-template name="marcxml:iso693">
        <xsl:with-param name="lang" select="substring($langstr, 1, 3)"/>
      </xsl:call-template>
    </lang>
  </xsl:if>
  <xsl:if test="string-length($langstr) &gt;= 6">
    <xsl:call-template name="marcxml:languages">
      <xsl:with-param name="langstr" select="substring($langstr, 4)"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<!-- Map MARC and ISO 693 part2B codes to their ISO 693-3 equivalents -->
<xsl:template name="marcxml:iso693">
  <xsl:param name="lang"/>
  <xsl:param name="nlang"
    select="translate($lang, 'ABCDEFGHIJKLMNOPQRSTUVWXY', 'abcdefghijklmnopqrstuvwxyz')"/>
  <xsl:choose>
    <xsl:when test="$nlang = 'alb'">sqi</xsl:when><!-- Albanian -->
    <xsl:when test="$nlang = 'arm'">hye</xsl:when><!-- Armenian -->
    <xsl:when test="$nlang = 'baq'">eus</xsl:when><!-- Basque -->
    <xsl:when test="$nlang = 'bur'">mya</xsl:when><!-- Burmese -->
    <xsl:when test="$nlang = 'chi'">zho</xsl:when><!-- Chinese -->
    <xsl:when test="$nlang = 'cze'">ces</xsl:when><!-- Czech -->
    <xsl:when test="$nlang = 'dut'">nld</xsl:when><!-- Dutch -->
    <xsl:when test="$nlang = 'fre'">fra</xsl:when><!-- French -->
    <xsl:when test="$nlang = 'gae'">gla</xsl:when><!-- Gaelic (Scottish) -->
    <xsl:when test="$nlang = 'ger'">deu</xsl:when><!-- German -->
    <xsl:when test="$nlang = 'geo'">kat</xsl:when><!-- Georgian -->
    <xsl:when test="$nlang = 'gre'">ell</xsl:when><!-- Greek (modern) -->
    <xsl:when test="$nlang = 'ice'">isl</xsl:when><!-- Icelandic -->
    <xsl:when test="$nlang = 'mac'">mkd</xsl:when><!-- Macedonian -->
    <xsl:when test="$nlang = 'mao'">mri</xsl:when><!-- Maori -->
    <xsl:when test="$nlang = 'may'">msa</xsl:when><!-- Maylay -->
    <xsl:when test="$nlang = 'per'">fas</xsl:when><!-- Persian -->
    <xsl:when test="$nlang = 'rum'">ron</xsl:when><!-- Romanian -->
    <xsl:when test="$nlang = 'slo'">slk</xsl:when><!-- Slovak -->
    <xsl:when test="$nlang = 'tib'">bod</xsl:when><!-- Tibetan -->
    <xsl:when test="$nlang = 'wel'">cym</xsl:when><!-- Welsh -->

    <!--
      Let's also try to catch a few 2-letter codes where they appear.
      This only works if it's the only code, but it's better than nothing.
    -->
    <xsl:when test="$nlang = 'en'">eng</xsl:when><!-- English -->
    <xsl:when test="$nlang = 'en '">eng</xsl:when><!-- English -->
    <xsl:when test="$nlang = 'fr'">fra</xsl:when><!-- French -->
    <xsl:when test="$nlang = 'fr '">fra</xsl:when><!-- French -->

    <!--
      Otherwise, use the code as supplied. We assume it is one of the
      6,000-odd valid 693-3 codes.
    -->
    <xsl:otherwise><xsl:value-of select="$nlang"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
  Determine the record language from the 040$b field, if present, and
  falling back to the language code in the leader if it is not.
-->
<xsl:template name="marcxml:record_language">
  <!--
  <xsl:choose>
    <xsl:when test="marc:datafield[@tag='040']/marc:subfield[@code='b']">
      <xsl:call-template name="marcxml:iso693">
      -->
        <!--
          The language is in the 040 field. It should only contain 3
          characters, but in case it has more, only take the first three
        -->
        <!--
        <xsl:with-param name="lang" select="substring(marc:datafield[@tag='040']/marc:subfield[@code='b'], 1, 3)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
    -->
      <xsl:call-template name="marcxml:iso693">
        <xsl:with-param name="lang" select="substring(marc:controlfield[@tag='008'], 36, 3)"/>
      </xsl:call-template>
      <!--
    </xsl:otherwise>
  </xsl:choose>
  -->
</xsl:template>


<!-- Create a series of <lang> elements from the 041 field -->
<xsl:template name="marcxml:lang">
  <xsl:for-each select="marc:datafield[@tag='041']/marc:subfield">
    <xsl:call-template name="marcxml:extract_lang_codes">
      <xsl:with-param name="langstr" select="translate(., ' ', '')"/>
    </xsl:call-template>
  </xsl:for-each>
</xsl:template>
<xsl:template name="marcxml:extract_lang_codes">
  <xsl:param name="langstr"/>
  <xsl:if test="string-length($langstr) &gt;= 3">
    <lang>
      <xsl:call-template name="marcxml:iso693">
        <xsl:with-param name="lang" select="substring($langstr, 1, 3)"/>
      </xsl:call-template>
    </lang>
  </xsl:if>
  <xsl:if test="string-length($langstr) &gt;= 6">
    <xsl:call-template name="marcxml:extract_lang_codes">
      <xsl:with-param name="langstr" select="substring($langstr, 4)"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


<!-- Title fields -->
<xsl:template name="marcxml:title">

  <xsl:variable name="lang"><xsl:call-template name="marcxml:record_language"/></xsl:variable>

  <xsl:for-each select="marc:datafield[@tag='245']">
    <title lang="{$lang}" type="main"><xsl:value-of select="normalize-space(.)"/></title>
  </xsl:for-each>

  <xsl:for-each select="marc:datafield[
    @tag='246' or
    @tag='440' or
    @tag='740'
  ]">
    <title lang="{$lang}"><xsl:value-of select="normalize-space(.)"/></title>
  </xsl:for-each>

  <xsl:for-each select="marc:datafield[
    @tag='130' or
    @tag='730' or
    @tag='830' or
    @tag='840'
  ]">
    <title lang="{$lang}" type="uniform"><xsl:value-of select="normalize-space(.)"/></title>
  </xsl:for-each>

</xsl:template>


<!-- Author/creator fields -->
<xsl:template name="marcxml:author">

  <xsl:variable name="lang"><xsl:call-template name="marcxml:record_language"/></xsl:variable>

  <xsl:for-each select="marc:datafield[
    @tag='100' or
    @tag='110' or
    @tag='111' or
    @tag='700' or
    @tag='710' or
    @tag='711'
  ]">
    <author><xsl:value-of select="normalize-space(.)"/></author>
  </xsl:for-each>

</xsl:template>


<!-- Publication fields -->
<xsl:template name="marcxml:publication">

  <xsl:variable name="lang"><xsl:call-template name="marcxml:record_language"/></xsl:variable>

  <xsl:for-each select="marc:datafield[@tag='260']">
    <xsl:if test="string-length(normalize-space(.)) != 0">
      <publication><xsl:value-of select="normalize-space(.)"/></publication>
    </xsl:if>
  </xsl:for-each>

</xsl:template>


<!-- Subject fields -->
<xsl:template name="marcxml:subject">

  <xsl:variable name="lang"><xsl:call-template name="marcxml:record_language"/></xsl:variable>

  <xsl:for-each select="marc:datafield[
    @tag='600' or
    @tag='610' or
    @tag='630' or
    @tag='650' or
    @tag='651'
  ]">
    <subject lang="{$lang}">
      <xsl:for-each select="marc:subfield">
        <xsl:if test="@code='v' or @code='x' or @code='y' or @code='z'"> -- </xsl:if>
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:for-each>
    </subject>
  </xsl:for-each>

</xsl:template>

<!-- Notes fields -->
<!-- TODO: this area especially needs work -->
<xsl:template name="marcxml:note">

  <xsl:variable name="lang"><xsl:call-template name="marcxml:record_language"/></xsl:variable>

  <xsl:for-each select="marc:datafield[
    @tag='250' or
	  @tag='362' or
	  @tag='300' or
	  @tag='500' or
	  @tag='504' or
    @tag='505' or
	  @tag='510' or
	  @tag='515' or
	  @tag='520' or
	  @tag='534' or
	  @tag='540' or
	  @tag='546' or
	  @tag='580' or
    @tag='787' or
	  @tag='800' or
	  @tag='810' or
	  @tag='811' or
	  @tag='830'
  ]">
    <xsl:if test="normalize-space(.)">
      <xsl:choose>
        <xsl:when test="@tag = '300'">
          <note lang="{$lang}" type="extent"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:when>
        <xsl:when test="@tag = '540'">
          <note lang="{$lang}" type="rights"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:when>
        <xsl:otherwise>
          <note lang="{$lang}"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:for-each>

</xsl:template>

</xsl:stylesheet>


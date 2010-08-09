<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:marcxml="http://www.canadiana.org/NS/cmr-marcxml"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
>

<xsl:import href="canmarc2iso693-3.xsl"/>

<!--
  Determine the record language from the 040$b field, if present, and
  falling back to the language code in the leader if it is not.
-->
<xsl:template name="marcxml:record_language">
  <xsl:choose>
    <xsl:when test="marc:datafield[@tag='040']/marc:subfield[@code='b']">
      <xsl:value-of select="marc:datafield[@tag='040']/marc:subfield[@code='b']"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="canmarc2iso693-3">
        <xsl:with-param name="lang" select="substring(marc:controlfield[@tag='008'], 36, 3)"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
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

  <publication><xsl:value-of select="normalize-space(marc:datafield[@tag='260'])"/></publication>

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
  </xsl:for-each>

</xsl:template>

</xsl:stylesheet>


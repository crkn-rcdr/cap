<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:marcxml="http://www.canadiana.ca/XML/cmr-marcxml"
>

<xsl:import href="marcxml.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template name="filters">
  <filters>
    <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
    <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
    <filter xpath="//record/pubdate[@min = '']" type="delete"/>
    <filter xpath="//record/pubdate[@max = '']" type="delete"/>
  </filters>
</xsl:template>

<xsl:template match="marc:collection">
  <recordset version="1.0">
    <xsl:apply-templates/>
    <xsl:call-template name="filters"/>
  </recordset>
</xsl:template>

<xsl:template match="marc:record">
  <xsl:param name="lang">
    <xsl:call-template name="marcxml:record_language"/>
  </xsl:param>
  <record>

    <type>monograph</type>
    <contributor>otu</contributor>

    <key>
      <xsl:call-template name="last_after">
        <xsl:with-param name="string" select="marc:datafield[@tag='856']/marc:subfield[@code='u']"/>
        <xsl:with-param name="fragment">/</xsl:with-param>
      </xsl:call-template>
    </key>

      <label><xsl:value-of select="normalize-space(marc:datafield[@tag='245'])"/></label>
    <xsl:if test="marc:datafield[@tag='260']/marc:subfield[@code='c']">
      <pubdate min="{marc:datafield[@tag='260']/marc:subfield[@code='c']}" max="{marc:datafield[@tag='260']/marc:subfield[@code='c']}"/>
    </xsl:if>

    <xsl:if test="$lang">
      <lang><xsl:value-of select="$lang"/></lang>
    </xsl:if>
    <xsl:call-template name="marcxml:lang"/>

    <media>text</media>

    <description>
      <xsl:call-template name="marcxml:title"/>
      <xsl:call-template name="marcxml:author"/>
      <xsl:call-template name="marcxml:publication"/>
      <xsl:call-template name="marcxml:subject"/>
      <xsl:call-template name="marcxml:note"/>
    </description>

    <resource>
      <canonicalUri><xsl:value-of select="marc:datafield[@tag='856']/marc:subfield[@code='u']"/></canonicalUri>
    </resource>
  </record>
</xsl:template>

<!-- Return portion of $string found after the last occurrence of $fragment -->
<xsl:template name="last_after">
  <xsl:param name="string"/>
  <xsl:param name="fragment"/>
  <xsl:choose>
    <xsl:when test="substring-after($string, $fragment)">
      <xsl:call-template name="last_after">
        <xsl:with-param name="string" select="substring-after($string, $fragment)"/>
        <xsl:with-param name="fragment" select="$fragment"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$string"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

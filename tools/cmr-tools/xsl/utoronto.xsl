<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:marcxml="http://www.canadiana.org/NS/cmr-marcxml"
>

<xsl:import href="marcxml.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template name="filters">
  <filters>
    <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
    <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
    <filter xpath="//record/pubdate[@min = '']" type="delete"/>
    <filter xpath="//record/pubdate[@max = '']" type="delete"/>

    <!--
      Split multiple languages codes into distinct fields. We then
      need to map any incorrect codes to ISO 693-3. 
    -->
    <filter xpath="//record/lang" type="match" regex="..."/>
    <filter xpath="//record/lang" type="map">
      <map from="chi" to="zho"/>
      <map from="fre" to="fra"/>
      <map from="ger" to="deu"/>
      <map from="dut" to="nld"/>
      <map from="wel" to="cym"/>
    </filter>

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
    <key><xsl:value-of select="marc:datafield[@tag='035'][position()=last()]/marc:subfield[@code='a']"/></key>
      <label><xsl:value-of select="normalize-space(marc:datafield[@tag='245'])"/></label>
    <xsl:if test="marc:datafield[@tag='260']/marc:subfield[@code='c']">
      <pubdate min="{marc:datafield[@tag='260']/marc:subfield[@code='c']}" max="{marc:datafield[@tag='260']/marc:subfield[@code='c']}"/>
    </xsl:if>

    <xsl:if test="$lang">
      <lang><xsl:value-of select="$lang"/></lang>
    </xsl:if>
    <xsl:for-each select="marc:datafield[@tag='041']/marc:subfield">
      <lang>
        <xsl:call-template name="canmarc2iso693-3">
          <xsl:with-param name="lang" select="."/>
        </xsl:call-template>
      </lang>
    </xsl:for-each>

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

</xsl:stylesheet>


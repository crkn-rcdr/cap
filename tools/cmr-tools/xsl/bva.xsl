<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="xml">
    <recordset version="1.0">
      <xsl:apply-templates match="doc"/>
      <filters>
        <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
        <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
        <filter xpath="//record/pubdate[@min = '']" type="delete"/>
        <filter xpath="//record/pubdate[@max = '']" type="delete"/>
      </filters>
    </recordset>
  </xsl:template>

  <xsl:template match="doc">
    <record>
      <type>monograph</type>
      <contributor>bva</contributor>
      <key><xsl:value-of select="field[@name='id']"/></key>
      <label>
        <xsl:choose>
          <xsl:when test="field[@name='title']">
            <xsl:value-of select="normalize-space(field[@name='title'])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space(field[@name='id'])"/>
          </xsl:otherwise>
        </xsl:choose>
      </label>
      <xsl:if test="field[@name='temporal']">
        <pubdate min="{field[@name='temporal']}" max="{field[@name='temporal']}"/>
      </xsl:if>
      <lang>eng</lang>
      <media>image</media>
      <description>
        <xsl:for-each select="field[@name='title']">
          <title><xsl:value-of select="normalize-space(.)"/></title>
        </xsl:for-each>
        <xsl:for-each select="field[@name='creator']">
          <author><xsl:value-of select="normalize-space(.)"/></author>
        </xsl:for-each>
        <xsl:for-each select="field[@name='temporal']">
          <publication><xsl:value-of select="normalize-space(.)"/></publication>
        </xsl:for-each>
        <xsl:for-each select="field[@name='subject']">
          <subject><xsl:value-of select="normalize-space(.)"/></subject>
        </xsl:for-each>
        <xsl:for-each select="field[@name='subject--geoLocation']">
          <subject><xsl:value-of select="normalize-space(.)"/></subject>
        </xsl:for-each>
        <xsl:if test="field[@name='description']">
          <text type="description"><xsl:value-of select="field[@name='description'][position() = 1]"/></text>
        </xsl:if>
        <xsl:for-each select="field[@name='description'][position() != 1]">
          <note><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:for-each>
      </description>
      <resource>
        <canonicalUri><xsl:value-of select="field[@name='URL']"/></canonicalUri>
        <xsl:if test="thumbnail">
          <canonicalThumbnailUri><xsl:value-of select="field[@name='thumbnail']"/></canonicalThumbnailUri>
        </xsl:if>
      </resource>
    </record>
  </xsl:template>

</xsl:stylesheet>

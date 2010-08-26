<?xml version="1.0" encoding="UTF-8"?>

<!--
  cmr stylesheet + filters for converting Memorial University OAI Dublin
  Core records into CMR 1.0.
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:marcxml="http://www.canadiana.ca/XML/cmr-marcxml"
  exclude-result-prefixes="oai dc oai_dc marcxml"
>

<xsl:import href="marcxml.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="/">
  <recordset version="1.0">

    <xsl:apply-templates select="descendant::oai:record"/>

    <filters>
      <filter xpath="//record/key" type="code">$_[0] =~ s!.*/!!; $_[0] =~ s/,/./; return $_[0];</filter>
      <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
      <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
      <filter xpath="//record/pubdate[substring(@min, 1, 4) = '0000']" type="delete"/>
      <filter xpath="//record/pubdate[@min = '']" type="delete"/>
      <filter xpath="//record/pubdate[@max = '']" type="delete"/>
      <filter xpath="//record/lang" type="code">$_[0] =~ s/en[:,]/eng/; return $_[0]</filter>
    </filters>

  </recordset>
</xsl:template>

<xsl:template match="oai:record">

  <record>
    <type>monograph</type>
    <contributor>mun</contributor>
    <key><xsl:value-of select="descendant::dc:identifier[position() = last()]"/></key>
    <label><xsl:value-of select="descendant::dc:title[position()=1]"/></label>

    <xsl:if test="descendant::dc:date">
      <pubdate min="{descendant::dc:date[position()= 1]}" max="{descendant::dc:date[position()=1]}"/>
    </xsl:if>

    <xsl:for-each select="descendant::dc:language">
      <xsl:choose>
        <xsl:when test="contains(../descendant::dc:identifier[position() = last()], '/moravian,')">
          <!-- We can't yet handle these language formats -->
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="marcxml:languages">
            <xsl:with-param name="langstr" select="translate(., '; ', '')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>

    <xsl:for-each select="descendant::dc:type">
      <xsl:choose>
        <xsl:when test="
          'Audio'
        ">
          <media>audio</media>
        </xsl:when>
        <xsl:when test="
          text() = 'Book' or
          text() = 'Periodical' or
          text() = 'Manuscript' or
          text() = 'Text'
        ">
          <media>text</media>
        </xsl:when>
        <xsl:when test="text() = 'Digital Photograph'"><media>image</media></xsl:when>
        <xsl:when test="text() = 'Manuscript; Photograph'">
          <media>text</media>
          <media>image</media>
        </xsl:when>
        <xsl:when test="text() = 'Moving Image'"><media>video</media></xsl:when>
        <xsl:when test="
          text() = 'Map' or
          text() = 'Photograph' or
          text() = 'Photograph;' or
          text() = 'Still Image' or
          text() = 'Still Image;'
        ">
          <media>image</media>
        </xsl:when>
        <xsl:when test="
          text() = 'Map; Manuscript' or
          text() = 'Text; Still image'
        ">
          <media>text</media>
          <media>image</media>
        </xsl:when>
        <xsl:when test="text() = 'Video Interview'"><media>video</media></xsl:when>
        <xsl:otherwise><media><xsl:value-of select="."/></media></xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>

    <description>

      <xsl:for-each select="descendant::dc:title">
        <title><xsl:value-of select="normalize-space(.)"/></title>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:creator">
        <author><xsl:value-of select="normalize-space(.)"/></author>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:publisher">
        <publication><xsl:value-of select="normalize-space(.)"/></publication>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:contributor">
        <publication><xsl:value-of select="normalize-space(.)"/></publication>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:date">
        <publication><xsl:value-of select="normalize-space(.)"/></publication>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:coverage">
        <subject><xsl:value-of select="normalize-space(.)"/></subject>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:subject">
        <subject><xsl:value-of select="normalize-space(.)"/></subject>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:description">
        <text type="description"><xsl:value-of select="normalize-space(.)"/></text>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:source">
        <note type="source"><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:format">
        <note type="extent"><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:relation">
        <note><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

    </description>

    <resource>
      <canonicalUri><xsl:value-of select="descendant::dc:identifier[position() = last()]"/></canonicalUri>
    </resource>

  </record>
</xsl:template>
            
</xsl:stylesheet>





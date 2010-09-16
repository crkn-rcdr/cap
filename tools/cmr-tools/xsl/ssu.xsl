<?xml version="1.0" encoding="UTF-8"?>

<!--
  CMR stylesheet for
  University of Saskatchewan
  CONTENTdm Dublin Core OAI metadata
  http://cdm15126.contentdm.oclc.org/cgi-bin/oai.exe
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  exclude-result-prefixes="oai dc oai_dc"
>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="/">
  <recordset version="1.0">

    <xsl:apply-templates select="descendant::oai:record"/>

    <filters>
      <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
      <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
      <filter xpath="//record/pubdate[@min = '']" type="delete"/>
      <filter xpath="//record/pubdate[@max = '']" type="delete"/>
    </filters>

  </recordset>
</xsl:template>

<xsl:template match="oai:record">
  <record>
    <type>monograph</type>
    <contributor>ssu</contributor>
    <key><xsl:value-of select="substring(translate(oai:header/oai:identifier, '/', '.'), 33)"/></key>
    <label><xsl:value-of select="descendant::dc:title[position()=1]"/></label>

    <xsl:if test="descendant::dc:date">
      <pubdate min="{descendant::dc:date[position()= 1]}" max="{descendant::dc:date[position()=1]}"/>
    </xsl:if>

    <xsl:for-each select="descendant::dc:language">
      <xsl:variable name="lang" select="translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
      <xsl:if test="contains($lang, 'chinese')"><lang>zho</lang></xsl:if>
      <xsl:if test="contains($lang, 'english')"><lang>eng</lang></xsl:if>
      <xsl:if test="contains($lang, 'french')"><lang>fra</lang></xsl:if>
      <xsl:if test="contains($lang, 'german')"><lang>deu</lang></xsl:if>
      <xsl:if test="contains($lang, 'russian')"><lang>rus</lang></xsl:if>
      <xsl:if test="contains($lang, 'spanish')"><lang>spa</lang></xsl:if>
    </xsl:for-each>

    <xsl:for-each select="descendant::dc:type">
      <xsl:variable name="type" select="translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
      <xsl:choose>
        <xsl:when test="substring($type, 1, 7) = 'audio ('">
          <media>audio</media>
        </xsl:when>
        <xsl:when test="
          $type = 'archival' or
          $type = 'black and white image' or
          $type = 'colour image' or
          $type = 'holograph' or
          $type = 'still image'
        ">
          <media>image</media>
        </xsl:when>
        <xsl:when test="
          $type = 'photojournal' or
          $type = 'text; holograph' or
          $type = 'text; image' or
          $type = 'typescript; holograph'
        ">
          <media>text</media>
          <media>image</media>
        </xsl:when>
        <xsl:when test="
          $type = 'collection permissions' or
          $type = 'print' or
          $type = 'text' or
          substring($type, 1, 6) =  'text (' or
          $type = 'literary manuscript' or
          $type = 'handwritten text' or
          $type = 'handwritten and typed text' or
          $type = 'periodical' or
          $type = 'typed text' or
          $type = 'typescript'
        ">
          <media>text</media>
        </xsl:when>

        <!-- Ignore known errors and typos -->
        <xsl:when test="$type = 'test'"></xsl:when>

        <xsl:otherwise>
          <media><xsl:value-of select="$type"/></media>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>

    <description>

      <xsl:for-each select="descendant::dc:title">
        <title><xsl:value-of select="normalize-space(.)"/></title>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:date">
        <publication><xsl:value-of select="normalize-space(.)"/></publication>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:publisher">
        <publication><xsl:value-of select="normalize-space(.)"/></publication>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:creator">
        <author><xsl:value-of select="normalize-space(.)"/></author>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:subject">
        <subject><xsl:value-of select="normalize-space(.)"/></subject>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:description">
        <text type="description"><xsl:value-of select="normalize-space(.)"/></text>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:type">
        <note><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:relation">
        <note><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:format">
        <note type="extent"><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:contributor">
        <note type="source"><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:source">
        <note type="source"><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:rights">
        <note type="rights"><xsl:value-of select="normalize-space(.)"/></note>
      </xsl:for-each>

    </description>

    <resource>
      <canonicalUri><xsl:value-of select="descendant::dc:identifier[position() = last()]"/></canonicalUri>
    </resource>

  </record>
</xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:marcxml="http://www.canadiana.org/NS/cmr-marcxml"
  xmlns=""
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

<xsl:template match="marc:record">
  <recordset version="1.0">
    <xsl:call-template name="record"/>
    <xsl:call-template name="filters"/>
  </recordset>
</xsl:template>

<xsl:template name="record">
  <record>
    <type>monograph</type>
    <contributor>oonl</contributor>
    <key><xsl:value-of select="marc:controlfield[@tag='001']"/></key>
    <xsl:choose>
      <xsl:when test="normalize-space(marc:datafield[@tag='245'])">
        <label><xsl:value-of select="normalize-space(marc:datafield[@tag='245'])"/></label>
      </xsl:when>
      <xsl:otherwise>
        <label>Untitled/Sans titre</label>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="marc:datafield[@tag='260']/marc:subfield[@code='c']">
      <pubdate min="{marc:datafield[@tag='260']/marc:subfield[@code='c']}" max="{marc:datafield[@tag='260']/marc:subfield[@code='c']}"/>
    </xsl:if>
    <media>image</media>

    <description>

      <!-- Title -->
      <xsl:call-template name="marcxml:title"/>
      <xsl:for-each select="marc:datafield[@tag='791']/marc:subfield[@code='t']">
        <title lang="fra"><xsl:value-of select="."/></title>
      </xsl:for-each>
      <xsl:for-each select="marc:datafield[@tag='792']/marc:subfield[@code='t']">
        <title lang="eng"><xsl:value-of select="."/></title>
      </xsl:for-each>

      <!-- Author -->
      <xsl:call-template name="marcxml:author"/>

      <!-- Publication -->
      <xsl:call-template name="marcxml:publication"/>

      <!-- Subject -->
      <xsl:call-template name="marcxml:subject"/>

      <!-- Note -->
      <xsl:call-template name="marcxml:note"/>

      <!-- Text -->
      <!-- None so far -->

    </description>

    <resource>
      <xsl:variable name="file" select="marc:datafield[@tag='095']/marc:subfield[@code='u']"/>
      <canonicalUri>
        <xsl:choose>
          <xsl:when test="substring($file, 1, 1) = 'e'">
            <xsl:variable name="group" select="floor(substring($file, 2, 9) div 25000) + 1"/>
            <xsl:variable name="groupno">
              <xsl:choose>
                <xsl:when test="string-length($group) = '1'"><xsl:value-of select="concat('00', $group)"/></xsl:when>
                <xsl:when test="string-length($group) = '2'"><xsl:value-of select="concat('0', $group)"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$group"/></xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat('http://data2.archives.ca/e/e', $groupno, '/', translate($file, ' ', ''), '.jpg')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('http://data2.archives.ca/ap/', substring($file, 1, 1), '/', translate($file, ' ', ''), '.jpg')"/>
          </xsl:otherwise>
        </xsl:choose>
      </canonicalUri>
    </resource>
  </record>
</xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  xmlns:marcxml="http://www.canadiana.org/NS/cmr-marcxml"
>

<xsl:import href="marcxml.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="marc:record">
  <recordset version="1.0">
    <xsl:call-template name="record"/>
  </recordset>
</xsl:template>

<xsl:template name="record">
  <record>
    <type>monograph</type>
    <contributor>oonl</contributor>
    <key><xsl:value-of select="marc:controlfield[@tag='001']"/></key>
    <label><xsl:value-of select="normalize-space(marc:datafield[@tag='245'])"/></label>
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
            <xsl:value-of select="concat('http://data2.archives.ca/e/e', $groupno, '/', $file, '.jpg')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('http://data2.archives.ca/ap/', substring($file, 1, 1), '/', $file, '.jpg')"/>
          </xsl:otherwise>
        </xsl:choose>
      </canonicalUri>
    </resource>
  </record>
</xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:iso693="http://www.canadiana.ca/XML/cmr-iso693"
>

  <xsl:import href="lib/iso693.xsl"/>

  <xsl:param name="contributor">aeu</xsl:param>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <recordset version="1.0">
      <xsl:apply-templates select="mods:mods"/>
    </recordset>
  </xsl:template>

  <xsl:template match="mods:mods">
    <record>

      <type>monograph</type>

      <contributor><xsl:value-of select="$contributor"/></contributor>

      <key><xsl:value-of select="mods:recordInfo/mods:recordIdentifier"/></key>

      <label><xsl:value-of select="mods:titleInfo/mods:title"/></label>


      <!-- Pubdate -->
      <xsl:choose>
        <xsl:when test="
          mods:originInfo/mods:dateCreated[@point='start'] and
          mods:originInfo/mods:dateCreated[@point='end']
        ">
          <pubdate min="{mods:originInfo/mods:dateCreated[@point='start']}" max="{mods:originInfo/mods:dateCreated[@point='end']}"/>
        </xsl:when>
        <xsl:when test="mods:originInfo/mods:dateCreated">
          <pubdate min="{mods:originInfo/mods:dateCreated}" max="{mods:originInfo/mods:dateCreated}"/>
        </xsl:when>
        <xsl:when test="mods:originInfo/mods:dateCreated">
          <pubdate min="{mods:originInfo/mods:dateCreate}" max="{mods:originInfo/mods:dateCreated}"/>
        </xsl:when>
        <xsl:when test="mods:originInfo/mods:dateIssued">
          <pubdate min="{mods:originInfo/mods:dateIssued}" max="{mods:originInfo/mods:dateIssued}"/>
        </xsl:when>
      </xsl:choose>


      <!-- Language -->
      <xsl:for-each select="mods:language/mods:languageTerm">
        <xsl:if test=".">
          <xsl:call-template name="iso693:lang">
            <xsl:with-param name="arg" select="normalize-space(.)"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:for-each>

      <!-- Media Type -->
      <xsl:for-each select="mods:typeOfResource">
        <xsl:call-template name="media">
          <xsl:with-param name="arg" select="normalize-space(.)"/>
        </xsl:call-template>
      </xsl:for-each>

      <description>

        <xsl:for-each select="mods:titleInfo/mods:title">
          <title><xsl:value-of select="normalize-space(.)"/></title>
        </xsl:for-each>

        <xsl:for-each select="mods:name">
          <!-- TODO: check role codes and only use names that are actual creators -->
          <author><xsl:value-of select="mods:namePart"/></author>
        </xsl:for-each>

        <xsl:for-each select="mods:subject/*">
          <subject><xsl:value-of select="normalize-space(.)"/></subject>
        </xsl:for-each>

        <xsl:for-each select="mods:note[@type='public']">
          <text type="description"><xsl:value-of select="normalize-space(.)"/></text>
        </xsl:for-each>

        <xsl:for-each select="mods:note[@type='public_description']">
          <text type="description"><xsl:value-of select="normalize-space(.)"/></text>
        </xsl:for-each>

        <xsl:for-each select="mods:physicalDescription">
          <note type="extent"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:for-each>

      </description>

      <resource>

        <canonicalUri>
          <xsl:choose>
            <xsl:when test="mods:location/mods:url[@access='object in context']">
              <xsl:value-of select="mods:location/mods:url[@access='object in context']"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="peel_id">
                <xsl:call-template name="get_peel_id">
                  <xsl:with-param name="string" select="mods:recordInfo/mods:recordIdentifier"/>
                </xsl:call-template>
              </xsl:variable>
              <xsl:value-of select="concat('http://peel.library.ualberta.ca/bibliography/', normalize-space($peel_id), '.html')"/>
            </xsl:otherwise>
          </xsl:choose>
        </canonicalUri>

        <xsl:if test="mods:location/mods:url[@access='raw object']">
          <canonicalPreviewUri>
            <xsl:value-of select="mods:location/mods:url[@access='raw object']"/>
          </canonicalPreviewUri>
        </xsl:if>

      </resource>

    </record>
  </xsl:template>

  <xsl:template name="get_peel_id">
    <xsl:param name="string"/>
    <xsl:choose>
      <xsl:when test="starts-with($string, 'P')">
        <xsl:call-template name="get_peel_id">
          <xsl:with-param name="string" select="substring-after($string, 'P')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="starts-with($string, '0')">
        <xsl:call-template name="get_peel_id">
          <xsl:with-param name="string" select="substring-after($string, '0')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="media">
    <xsl:param name="arg" select="."/>
    <xsl:variable name="media" select="translate($arg, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
    <media>
      <xsl:choose>
        <xsl:when test="
          $media = 'cartographic' or
          $media = 'still image'
        ">image</xsl:when>
        <xsl:when test="
          $media = 'notated music' or
          $media = 'text'"
        >text</xsl:when>
        <xsl:otherwise>!!<xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </media>
  </xsl:template>

</xsl:stylesheet>

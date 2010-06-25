<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template name="filters">
  <filters>
    <filter xpath="//record/pubdate" attribute="min" type="code">
      iso8601($_[0], 0)
    </filter>
    <filter xpath="//record/pubdate" attribute="max" type="code">
      iso8601($_[0], 1)
    </filter>
    <filter xpath="//record/media" type="map">
      <map from="Sound" to="sound"/>
      <map from="Text" to="text"/>
    </filter>
    <filter xpath="//record/description/subject" type="split" regex=";\s+"/>
    <filter xpath="//record/description/*" type="default" attribute="lang" value="eng"/>
    <filter xpath="//record/description/*" type="map" attribute="type" ignore-empty="true">
      <map from="physical" to="descriptive"/>
      <map from="summary" to="descriptive"/>
    </filter>
  </filters>
</xsl:template>

<xsl:template match="record">
  <recordset version="1.0">
    <record>

      <!-- Required control fields -->
      <type>monograph</type>
      <contributor>bvas</contributor>
      <key><xsl:value-of select="identifier[@type='sfu']"/></key>
      <label><xsl:value-of select="title[position()=1]"/></label>
      <clabel><xsl:value-of select="title[position()=1]"/></clabel>

      <!-- Optional control fields -->
      <pkey>MulticulturalCanada</pkey>
      <gkey>MulticulturalCanada</gkey>
      <xsl:if test="date">
        <pubdate min="{date}" max="{date}"/>
      </xsl:if>
      <xsl:for-each select="language">
        <lang><xsl:apply-templates/></lang>
      </xsl:for-each>
      <xsl:for-each select="media">
        <media><xsl:apply-templates/></media>
      </xsl:for-each>

      <!-- Bibliographic description -->
      <description>
        <xsl:for-each select="title">
          <title lang="{@lang}"><xsl:apply-templates/></title>
        </xsl:for-each>
        <xsl:for-each select="creator">
          <author lang="{@lang}"><xsl:apply-templates/></author>
        </xsl:for-each>
        <xsl:for-each select="publisher">
          <author lang="{@lang}"><xsl:apply-templates/></author>
        </xsl:for-each>
        <xsl:for-each select="subject">
          <subject lang="{@lang}"><xsl:apply-templates/></subject>
        </xsl:for-each>
        <xsl:for-each select="description[not(@type)]">
          <note lang="{@lang}" type="general"><xsl:apply-templates/></note>
        </xsl:for-each>
        <xsl:for-each select="rights">
          <note lang="{@lang}" type="rights"><xsl:apply-templates/></note>
        </xsl:for-each>
        <xsl:for-each select="description[@type]">
          <text lang="{@lang}" type="{@type}"><xsl:apply-templates/></text>
        </xsl:for-each>
      </description>

      <!-- Resources -->
      <resource>
        <canonicalUri><xsl:value-of select="relation[@type='fullrecord']"/></canonicalUri>
        <canonicalPreviewUri><xsl:value-of select="relation[@type='thumbnail']"/></canonicalPreviewUri>
      </resource>
      
    </record>

    <xsl:call-template name="filters"/>
  </recordset>
</xsl:template>

</xsl:stylesheet>

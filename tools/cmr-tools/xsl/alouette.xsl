<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:mods="http://www.loc.gov/mods/v3"
>

<xsl:import href="canmarc2iso693-3.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template name="filters">
  <filters>
    <filter xpath="//record/key" type="code">
      if ($_[0] =~ m!http://amicus\.collectionscanada\.ca!) { $_[0] =~ s!.*itm=(\d+)\&amp;coll=(\d+)!$2.$1! }
      $_[0] =~ s![:/@\\, ();]!.!g;
      return $_[0];
    </filter>
    <filter xpath="//record/label" type="code">$_[0] =~ s!^$![Untitled]!; return $_[0]</filter>
    <filter xpath="//record/gkey" attribute="min" type="code">$_[0] =~ s/[^A-Za-z0-9_.-]//g; return $_[0]</filter>
    <filter xpath="//record/pubdate" attribute="min" type="code">$_[0] =~ s!-(x)+!!g; iso8601($_[0], 0)</filter>
    <filter xpath="//record/pubdate" attribute="max" type="code">$_[0] =~ s!-(x)+!!g; iso8601($_[0], 1)</filter>
    <filter xpath="//record/pubdate[@min = '']" type="delete"/>
    <filter xpath="//record/pubdate[@max = '']" type="delete"/>
    <filter xpath="//record/lang" type="split" regex="\s*;\s*"/>
    <filter xpath="//record/lang" type="split" regex="/"/>
    <filter xpath="//record/lang" type="code">return lc($_[0])</filter>
    <filter xpath="//record/lang" type="map">
      <map from="anglais" to="eng"/>
      <map from="allemand" to="deu"/>
      <map from="english" to="eng"/>
      <map from="french" to="fra"/>
      <map from="swedish" to="swe"/>
      <map from="en" to="eng"/>
      <map from="fr" to="fra"/>
      <map from="gd" to="gla"/>
      <map from="inu" to="iku"/>
    </filter>
    <filter xpath="//record/media" type="code">return lc($_[0])</filter>
    <filter xpath="//record/media[text() = 'object']" type="delete"/>
    <filter xpath="//record/media[text() = 'unknown']" type="delete"/>
    <filter xpath="//record/description/text[text() = '']" type="delete"/>
    <filter xpath="//record/resource/canonicalPreviewUri" type="code">
      $_[0] =~ s/'/%27/g; $_[0] =~ s! !%20!g; return $_[0];
    </filter>
    <filter xpath="//record/resource/canonicalUri" type="code">
      $_[0] =~ s/'/%27/g; $_[0] =~ s! !%20!g; $_[0]; $_[0] =~ s!\\!%5c!g; return $_[0];
    </filter>
  </filters>
</xsl:template>

<xsl:template match="add">
  <recordset version="1.0">
    <xsl:apply-templates select="doc"/>
    <xsl:call-template name="filters"/>
  </recordset>
</xsl:template>

<xsl:template match="doc">
  <record>
    
    <!-- Required control fields -->
    <type>monograph</type>
    <contributor>alouette</contributor>
    <key><xsl:value-of select="concat(field[@name='recordOwner'], '.', field[@name='id'])"/></key>
    <label><xsl:value-of select="normalize-space(field[@name='title'][position()=1])"/></label>

    <!-- Optional control fields -->
    <xsl:for-each select="groupName">
      <gkey><xsl:value-of select="normalize-space(.)"/></gkey>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="field[@name='dateOldest']/text() != '' and field[@name='dateNewest']/text() != ''">
        <pubdate min="{field[@name='dateOldest']}" max="{field[@name='dateNewest']}"/>
      </xsl:when>
      <xsl:when test="field[@name='temporal'][position() = 1]/text() != ''"> <!-- Guesing this will be right more often than wrong -->
        <pubdate min="{field[@name='temporal'][position() = 1]}" max="{field[@name='temporal'][position() = 1]}"/>
      </xsl:when>
    </xsl:choose>
    <xsl:for-each select="field[@name='language']">
      <xsl:if test="text()">
        <lang>
          <xsl:call-template name="canmarc2iso693-3">
            <xsl:with-param name="lang" select="."/>
          </xsl:call-template>
        </lang>
      </xsl:if>
    </xsl:for-each>
    <xsl:for-each select="field[@name='type']">
      <media><xsl:apply-templates/></media>
    </xsl:for-each>
    <!--
    <xsl:for-each select="field[@name='itemType']">
      <content><xsl:apply-templates/></content>
    </xsl:for-each>
    -->

    <!-- Description -->
    <description>
      <xsl:for-each select="field[@name='title']">
        <xsl:if test="text()"><title><xsl:value-of select="normalize-space(.)"/></title></xsl:if>
      </xsl:for-each>

      <xsl:for-each select="field[@name='creator']">
        <xsl:if test="text()"><author><xsl:value-of select="normalize-space(.)"/></author></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='contributor']">
        <xsl:if test="text()"><author><xsl:value-of select="normalize-space(.)"/></author></xsl:if>
      </xsl:for-each>

      <xsl:for-each select="field[@name='publisher']">
        <xsl:if test="text()"><publication><xsl:value-of select="normalize-space(.)"/></publication></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='bibliographicCitation']">
        <xsl:if test="text()"><publication><xsl:value-of select="normalize-space(.)"/></publication></xsl:if>
      </xsl:for-each>

      <xsl:for-each select="field[@name='subject']">
        <xsl:if test="text()"><subject><xsl:value-of select="normalize-space(.)"/></subject></xsl:if>
      </xsl:for-each>

      <xsl:for-each select="field[@name='comment']">
        <xsl:if test="text()"><note><xsl:value-of select="normalize-space(.)"/></note></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='mystery']">
        <xsl:if test="text()"><note><xsl:value-of select="normalize-space(.)"/></note></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='rights']">
        <xsl:if test="text()"><note type="rights"><xsl:value-of select="normalize-space(.)"/></note></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='source']">
        <xsl:if test="text()"><note type="source"><xsl:value-of select="normalize-space(.)"/></note></xsl:if>
      </xsl:for-each>

      <xsl:for-each select="field[@name='spatial']">
        <xsl:if test="text()"><descriptor type="location"><xsl:value-of select="normalize-space(.)"/></descriptor></xsl:if>
      </xsl:for-each>

      <xsl:for-each select="field[@name='abstract']">
        <xsl:if test="text()"><text type="description"><xsl:value-of select="normalize-space(.)"/></text></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='description']">
        <xsl:if test="text()"><text type="description"><xsl:value-of select="normalize-space(.)"/></text></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="field[@name='fulltext']">
        <xsl:if test="text()"><text type="content"><xsl:value-of select="normalize-space(.)"/></text></xsl:if>
      </xsl:for-each>
    </description>

    <!-- Resource -->
    <resource>
      <canonicalUri><xsl:value-of select="field[@name='url']"/></canonicalUri>
      <xsl:if test="field[@name='thumbnail']">
        <canonicalPreviewUri><xsl:value-of select="field[@name='thumbnail']"/></canonicalPreviewUri>
      </xsl:if>
    </resource>

  </record>
</xsl:template>

</xsl:stylesheet>


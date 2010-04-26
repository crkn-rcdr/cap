<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" indent="yes" encoding="utf-8"/>

<xsl:template match="/eco2">
<add>
  <xsl:apply-templates select="//page"/>

  <xsl:if test="//digital and not(/eco2/@parent)">
    <xsl:call-template name="monograph"/>
  </xsl:if>

  <xsl:if test="//digital and /eco2/@parent">
    <xsl:call-template name="issue"/>
  </xsl:if>

  <xsl:if test="//series">
    <xsl:call-template name="serial"/>
  </xsl:if>

</add>
</xsl:template>

<xsl:template name="monograph">
<doc>
  <field name="type">monograph</field>
  <field name="key">oocihm:<xsl:value-of select="/eco2/@id"/></field>
  <xsl:call-template name="global"/>
  <xsl:call-template name="bibfields"/>
</doc>
</xsl:template>

<xsl:template name="issue">
<doc>
  <field name="type">issue</field>
  <field name="key">oocihm:<xsl:value-of select="/eco2/@id"/></field>
  <field name="seq"><xsl:value-of select="substring(/eco2/@id, string-length(/eco2/@parent) + 2)"/></field>
  <field name="pkey">oocihm:<xsl:value-of select="/eco2/@parent"/></field>
  <xsl:call-template name="global"/>
  <xsl:call-template name="bibfields"/>
</doc>
</xsl:template>

<xsl:template name="serial">
<doc>
  <field name="type">serial</field>
  <field name="key">oocihm:<xsl:value-of select="/eco2/@id"/></field>
  <xsl:call-template name="global"/>
  <xsl:call-template name="bibfields"/>
</doc>
</xsl:template>

<xsl:template match="page">
<doc>
  <field name="type">page</field>
  <field name="key">oocihm:<xsl:value-of select="/eco2/@id"/>:<xsl:value-of select="number(@seq)"/></field>
  <field name="seq"><xsl:value-of select="number(@seq)"/></field>
  <field name="pkey">oocihm:<xsl:value-of select="/eco2/@id"/></field>
  <xsl:if test="/eco2/@parent">
    <field name="gkey"><xsl:value-of select="/eco2/@parent"/></field>
  </xsl:if>
  <xsl:if test="@n != ''">
    <field name="pageno"><xsl:value-of select="@n"/></field>
  </xsl:if>
  <xsl:if test="@type != ''">
    <field name="feature"><xsl:value-of select="@type"/></field>
  </xsl:if>
  <xsl:if test="pagetext[position()=1]/@quality != 0">
    <field name="ocrconf"><xsl:value-of select="pagetext[position()=1]/@quality"/></field>
  </xsl:if>

  <xsl:call-template name="global"/>

  <!-- Copy the pagetext fields that are tagged with a particular language -->
  <xsl:if test="pagetext[@lang='en']">
    <field name="tx_en"><xsl:apply-templates select="pagetext[@lang='en']"/></field>
  </xsl:if>
  <xsl:if test="pagetext[@lang='fr']">
    <field name="tx_fr"><xsl:apply-templates select="pagetext[@lang='fr']"/></field>
  </xsl:if>

  <!-- If there are any unknown language pagetext elements, tag them with the document language. -->
  <xsl:if test="substring(//marc/field[@type='008'], 36, 3) = 'eng' and pagetext[@lang='unknown']">
    <field name="tx_en"><xsl:apply-templates select="pagetext[@lang='unknown']"/></field>
  </xsl:if>
  <xsl:if test="substring(//marc/field[@type='008'], 36, 3) = 'fre' and pagetext[@lang='unknown']">
    <field name="tx_fr"><xsl:apply-templates select="pagetext[@lang='unknown']"/></field>
  </xsl:if>
</doc>
</xsl:template>

<xsl:template name="global">
  <field name="contributor">oocihm</field>
  <xsl:for-each select="//collections/collection[@lang='en']">
    <field name="gkey"><xsl:value-of select="normalize-space(translate(text(), ' &quot;', '_'))"/></field>
  </xsl:for-each>
  <field name="label"><xsl:value-of select="//marc/field[@type='245']/subfield[@type='a']"/></field>
  <field name="pubmin"><xsl:value-of select="//pubdate/@first"/>-01-01T00:00:00Z</field>
  <field name="pubmax"><xsl:value-of select="//pubdate/@last"/>-12-31T23:59:59Z</field>
</xsl:template>

<xsl:template name="bibfields">
  <!-- The language of the record: we'll index our fields using this
  language. This happens to work for English and French because the first
  two letters of the MARC encoding correspond to the ISO 639-1 code -->
  <xsl:variable name="lang"><xsl:value-of select="substring(//marc/field[@type='008'], 36, 2)"/></xsl:variable>

  <!-- Authors: these go in without any explicit language declaration -->
  <xsl:for-each select="//marc/field[@type='100' or @type='110' or @type='111' or @type='700' or @type='710' or @type='711']">
    <field name="au"><xsl:value-of select="normalize-space(.)"/></field>
  </xsl:for-each>
  
  <!-- The main title: this should go in first so that it appears first -->
  <xsl:if test="//marc/field[@type='245']">
    <field name="ti_{$lang}">
      <xsl:value-of select="normalize-space(//marc/field[@type='245']/subfield[@type='a'])"/>
      <xsl:if test="//marc/field[@type='245']/subfield[@type='b']">
        <xsl:value-of select="string(' ')"/>
        <xsl:value-of select="normalize-space(//marc/field[@type='245']/subfield[@type='b'])"/>
      </xsl:if>
    </field>
  </xsl:if>

  <!-- Alternate title -->
  <xsl:if test="//marc/field[@type='246']">
    <field name="ti_{$lang}"><xsl:value-of select="normalize-space(//marc/field[@type='245']/subfield[@type='a'])"/></field>
  </xsl:if>

  <!-- Added titles -->
  <xsl:for-each select="//marc/field[@type='130' or @type='170']">
    <field name="ti_{$lang}"><xsl:value-of select="normalize-space(.)"/></field>
  </xsl:for-each>

  <!-- Subject headings: English version -->
  <xsl:for-each select="//marc/field[@type='600' or @type='610' or @type='630' or @type='650' or @type='651' or @type='699'][@i2 != '6']">
    <field name="su_en"><xsl:value-of select="normalize-space(.)"/></field>
  </xsl:for-each>

  <!-- Subject headings: French version -->
  <xsl:for-each select="//marc/field[@type='600' or @type='610' or @type='630' or @type='650' or @type='651' or @type='699'][@i2 = '6']">
    <field name="su_fr"><xsl:value-of select="normalize-space(.)"/></field>
  </xsl:for-each>

  <!-- Pub statement -->
  <field name="pubstmt"><xsl:value-of select="normalize-space(//marc/field[@type='260'])"/></field>

</xsl:template>

</xsl:stylesheet>


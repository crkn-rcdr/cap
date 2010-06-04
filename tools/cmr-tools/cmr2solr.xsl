<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="recordset">
  <add>
    <xsl:apply-templates match="record"/>
  </add>
</xsl:template>

<xsl:template match="record">
  <doc>

    <!-- Required control fields -->
    <field name="key"><xsl:value-of select="concat(contributor, '.', key)"/></field>
    <field name="type"><xsl:value-of select="type"/></field>
    <field name="contributor"><xsl:value-of select="contributor"/></field>
    <field name="label"><xsl:value-of select="label"/></field>
    <field name="clabel"><xsl:value-of select="clabel"/></field>

    <!-- Optional control fields -->
    <xsl:apply-templates select="pkey"/>
    <xsl:apply-templates select="gkey"/>
    <xsl:apply-templates select="seq"/>
    <xsl:apply-templates select="pubdate"/>
    <xsl:apply-templates select="lang"/>
    <xsl:apply-templates select="media"/>

    <!-- Description and content -->
    <xsl:apply-templates select="description"/>

    <!-- Resources and links -->
    <xsl:apply-templates select="resource"/>
  </doc>
</xsl:template>

<xsl:template match="description">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="pkey|gkey">
  <field name="{name()}"><xsl:value-of select="concat(ancestor::record/descendant::contributor, '.', text())"/></field>
</xsl:template>

<xsl:template match="pubdate">
  <field name="pubmin"><xsl:value-of select="@min"/></field>
  <field name="pubmax"><xsl:value-of select="@max"/></field>
</xsl:template>

<xsl:template match="seq|lang|media">
  <field name="{name()}"><xsl:apply-templates/></field>
</xsl:template>

<xsl:template match="title|author|publication|subject|note|descriptor|text">
  <xsl:variable name="prefix">
    <xsl:choose>
      <xsl:when test="name() = 'title'">ti</xsl:when>
      <xsl:when test="name() = 'author'">au</xsl:when>
      <xsl:when test="name() = 'publication'">pu</xsl:when>
      <xsl:when test="name() = 'subject'">su</xsl:when>
      <xsl:when test="name() = 'note'">no</xsl:when>
      <xsl:when test="name() = 'descriptor'">de</xsl:when>
      <xsl:when test="name() = 'text'">tx</xsl:when>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="suffix">
    <xsl:if test="@lang='eng' or @lang='fre'">
      <xsl:value-of select="concat('_', substring(@lang, 1, 2))"/>
    </xsl:if>
  </xsl:variable>
  <field name="{$prefix}{$suffix}"><xsl:value-of select="."/></field>
  <field name="kw{$suffix}"><xsl:value-of select="."/></field>
</xsl:template>


<xsl:template match="resource">
  <field name="canonicalUri"><xsl:value-of select="canonicalUri"/></field>
  <xsl:apply-templates select="canonicalMaster"/>
  <xsl:apply-templates select="canonicalDownload"/>
</xsl:template>

<xsl:template match="canonicalMaster">
  <field name="canonicalMaster"><xsl:value-of select="."/></field>
  <xsl:if test="@size"><field name="canonicalMasterSize"><xsl:value-of select="@size"/></field></xsl:if>
  <xsl:if test="@mime"><field name="canonicalMasterMime"><xsl:value-of select="@mime"/></field></xsl:if>
</xsl:template>

</xsl:stylesheet>


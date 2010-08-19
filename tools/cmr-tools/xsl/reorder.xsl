<?xml version="1.0" encoding="UTF-8"?>

<!--

This stylesheet will put the fields of an otherwise valid CMR record in
the correct order to allow for validation under the 1.0 specification.

-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="/recordset">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates select="record"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="record">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates select="type"/>
    <xsl:apply-templates select="contributor"/>
    <xsl:apply-templates select="key"/>
    <xsl:apply-templates select="label"/>
    <xsl:apply-templates select="pkey"/>
    <xsl:apply-templates select="gkey"/>
    <xsl:apply-templates select="seq"/>
    <xsl:apply-templates select="pubdate"/>
    <xsl:apply-templates select="lang"/>
    <xsl:apply-templates select="media"/>
    <xsl:apply-templates select="description"/>
    <xsl:apply-templates select="resource"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="description">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates select="title"/>
    <xsl:apply-templates select="author"/>
    <xsl:apply-templates select="publication"/>
    <xsl:apply-templates select="subject"/>
    <xsl:apply-templates select="descriptor"/>
    <xsl:apply-templates select="text"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="resource">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates select="canonicalUri"/>
    <xsl:apply-templates select="canonicalPreviewUri"/>
    <xsl:apply-templates select="canonicalMaster"/>
    <xsl:apply-templates select="canonicalDownload"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="*">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:value-of select="."/>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>

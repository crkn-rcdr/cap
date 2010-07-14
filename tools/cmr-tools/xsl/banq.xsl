<?xml version="1.0" encoding="UTF-8"?>

<!-- 
  Conversion from BAnQ oai_dc metadata records to CMR.
  This stylesheet should work for all of the journal's collection.
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oai="http://www.openarchives.org/OAI/2.0/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  exclude-result-prefixes="oai"
>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="oai:OAI-PMH">
  <recordset version="1.0">
    <xsl:apply-templates select="//oai:record"/>
    <filters>
      <filter xpath="//record/type" type="map">
        <map from="fascicule" to="issue"/>
        <map from="titre" to="serial"/>
      </filter>
      <filter xpath="//record/gkey" type="map">
        <map from="Journaux - fascicules" to="Journaux"/>
      </filter>
      <filter xpath="//record/seq" type="code">
        $_[0] =~ s!.*/!!; return $_[0]
      </filter>
      <filter xpath="//record/pubdate" attribute="min" type="code">
        iso8601($_[0], 0)
      </filter>
      <filter xpath="//record/pubdate" attribute="max" type="code">
        iso8601($_[0], 1)
      </filter>
    </filters>
  </recordset>
</xsl:template>

<xsl:template match="oai:record">
  <record>

    <!-- Required Control Fields -->
    <type><xsl:value-of select="descendant::dc:type"/></type>
    <contributor>qmbn</contributor>
    <key>
      <xsl:choose>
        <xsl:when test="descendant::dc:type = 'titre'">
          <xsl:value-of select="oai:header/oai:setSpec"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="translate(substring(oai:header/oai:identifier, 28), '/', '-')"/>
        </xsl:otherwise>
      </xsl:choose>
    </key>
    <label><xsl:value-of select="descendant::dc:title"/></label>

    <!-- Optional control fields -->
    <xsl:if test="descendant::dc:type = 'fascicule'">
      <pkey><xsl:value-of select="oai:header/oai:setSpec"/></pkey>
    </xsl:if>
    <gkey><xsl:value-of select="descendant::dc:collection"/></gkey>
    <xsl:if test="descendant::dc:type = 'fascicule'">
      <seq><xsl:value-of select="oai:header/oai:identifier"/></seq>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="descendant::dc:type = 'titre'">
        <pubdate min="{descendant::dc:date[position()=1]}" max="{descendant::dc:date[position()=2]}"/>
      </xsl:when>
      <xsl:otherwise>
        <pubdate min="{descendant::dc:date[position()=3]}" max="{descendant::dc:date[position()=3]}"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="descendant::dc:language"/>
    <media>text</media>
    <description>
      <xsl:apply-templates select="descendant::dc:title"/>
      <xsl:apply-templates select="descendant::dc:creator"/>
      <xsl:apply-templates select="descendant::dc:publisher"/>
      <xsl:apply-templates select="descendant::dc:subject"/>
      <xsl:apply-templates select="descendant::dc:description"/>
      <xsl:apply-templates select="descendant::dc:beginenddatepublication"/>
      <xsl:apply-templates select="descendant::dc:matdescription"/>
      <xsl:apply-templates select="descendant::dc:descriptionlong"/>
      <xsl:apply-templates select="descendant::dc:descriptionshort"/>
    </description>
    <resource>
      <canonicalUri><xsl:value-of select="descendant::dc:sumpageurl"/></canonicalUri>
    </resource>
  </record>
</xsl:template>

<xsl:template match="dc:language"><lang><xsl:apply-templates/></lang></xsl:template>

<xsl:template match="dc:title">
  <title>
    <xsl:choose>
      <xsl:when test="../dc:specificcontent">
        <xsl:value-of select="normalize-space(concat(., ' : ', ../dc:specificcontent))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </title>
</xsl:template>

<xsl:template match="dc:creator"><author><xsl:apply-templates/></author></xsl:template>
<xsl:template match="dc:publisher"><publication><xsl:apply-templates/></publication></xsl:template>
<xsl:template match="dc:subject"><subject lang="fra"><xsl:apply-templates/></subject></xsl:template>
<xsl:template match="dc:description"><note lang="fra"><xsl:apply-templates/></note></xsl:template>
<xsl:template match="dc:beginenddatepublication"><note lang="fra"><xsl:apply-templates/></note></xsl:template>
<xsl:template match="dc:matdescription"><note lang="fra" type="extent"><xsl:apply-templates/></note></xsl:template>
<xsl:template match="dc:descriptionlong"><text lang="fra" type="description"><xsl:apply-templates/></text></xsl:template>
<xsl:template match="dc:descriptionshort"><text lang="fra" type="description"><xsl:apply-templates/></text></xsl:template>
            
</xsl:stylesheet>




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

<xsl:import href="canmarc2iso693-3.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="oai:OAI-PMH">
  <recordset version="1.0">
    <xsl:apply-templates select="//oai:record"/>

    <filters>
      <filter xpath="//record/pubdate" attribute="min" type="code">iso8601($_[0], 0)</filter>
      <filter xpath="//record/pubdate" attribute="max" type="code">iso8601($_[0], 1)</filter>
      <filter xpath="//record/pubdate[@min = '']" type="delete"/>
      <filter xpath="//record/pubdate[@max = '']" type="delete"/>
      <filter xpath="//record/description/text" type="code">$_[0] =~ s/&lt;(.*?)&gt;//sg; return $_[0];</filter>
    </filters>

  </recordset>
</xsl:template>

<xsl:template match="oai:record">
  <record>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="descendant::dc:type = 'titre'">serial</xsl:when>
        <xsl:when test="descendant::dc:type = 'fascicule'">issue</xsl:when>
        <xsl:when test="descendant::dc:type = 'image'">monograph</xsl:when>
        <xsl:when test="descendant::dc:type = 'enregistrements'">monograph</xsl:when>
        <xsl:otherwise>UNKNOWN: <xsl:value-of select="descendant::dc:type"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Universal control fields -->

    <type><xsl:value-of select="$type"/></type>

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

    <label>
      <xsl:choose>
        <xsl:when test="$type = 'issue'">
          <xsl:value-of select="descendant::dc:specificcontent"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="descendant::dc:title"/>
        </xsl:otherwise>
      </xsl:choose>
    </label>

    <!-- Additional control fields -->

    <xsl:if test="$type = 'issue'">
      <pkey><xsl:value-of select="oai:header/oai:setSpec"/></pkey>
    </xsl:if>

    <!-- No meaningful gkey supplied -->

    <xsl:if test="$type = 'issue'">
      <!--
        We are assuming that there are never more than 99,999 issues
        (approx. 300 years' worth of a daily publication). Add 1 to whatever
        value we get in case the last 5 digits are "00000"
      -->
      <seq><xsl:value-of select="number(substring(oai:header/oai:identifier, string-length(oai:header/oai:identifier) - 4))+1"/></seq>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="count(descendant::dc:date) = 1">
        <pubdate min="{descendant::dc:date[position()=1]}" max="{descendant::dc:date[position()=1]}"/>
      </xsl:when>
      <xsl:when test="count(descendant::dc:date) = 2">
        <pubdate min="{descendant::dc:date[position()=1]}" max="{descendant::dc:date[position()=2]}"/>
      </xsl:when>
      <xsl:when test="count(descendant::dc:date) = 3">
        <pubdate min="{descendant::dc:date[position()=3]}" max="{descendant::dc:date[position()=3]}"/>
      </xsl:when>
      <xsl:when test="count(descendant::dc:date) = 4">
        <pubdate min="{descendant::dc:date[position()=3]}" max="{descendant::dc:date[position()=4]}"/>
      </xsl:when>
    </xsl:choose>

    <xsl:for-each select="descendant::dc:language">
      <lang>
        <xsl:call-template name="canmarc2iso693-3">
          <xsl:with-param name="lang" select="."/>
        </xsl:call-template>
      </lang>
    </xsl:for-each>

    <media>
      <xsl:choose>
        <xsl:when test="descendant::dc:type = 'titre'">text</xsl:when>
        <xsl:when test="descendant::dc:type = 'fascicule'">text</xsl:when>
        <xsl:when test="descendant::dc:type = 'image'">image</xsl:when>
        <xsl:when test="descendant::dc:type = 'enregistrements'">text</xsl:when>
        <xsl:otherwise>UNKNOWN: <xsl:value-of select="descendant::dc:type"/></xsl:otherwise>
      </xsl:choose>
    </media>

    <!-- Bibliographic description -->

    <description>


      <xsl:choose>
        <xsl:when test="$type = 'issue'">
          <title>
            <xsl:value-of select="concat(descendant::dc:title[position() = 1], ' : ', descendant::dc:specificcontent)"/>
          </title>
          <xsl:for-each select="descendant::dc:title">
            <title type="uniform"><xsl:value-of select="."/></title>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="descendant::dc:title">
            <title><xsl:value-of select="."/></title>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:for-each select="descendant::dc:creator">
        <author><xsl:value-of select="."/></author>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:publisher">
        <author type="editor"><xsl:value-of select="."/></author>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:subject">
        <subject><xsl:value-of select="."/></subject>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:beginenddatepublication">
        <note><xsl:value-of select="."/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:matdescription">
        <note type="extent"><xsl:value-of select="."/></note>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:descriptionshort">
        <text type="description"><xsl:value-of select="."/></text>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:descriptionlong">
        <text type="description"><xsl:value-of select="."/></text>
      </xsl:for-each>

      <!-- Redundant?
      <xsl:for-each select="descendant::dc:descriptionshort">
        <text type="description"><xsl:value-of select="."/></text>
      </xsl:for-each>
      -->

    </description>

    <resource>
      <canonicalUri><xsl:value-of select="descendant::dc:sumpageurl"/></canonicalUri>
    </resource>
  </record>
</xsl:template>
            
</xsl:stylesheet>




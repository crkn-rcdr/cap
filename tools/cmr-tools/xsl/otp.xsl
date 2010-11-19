<?xml version="1.0" encoding="UTF-8"?>

<!--

  2010-11-19

  OTP - Toronto Public Library

  Dublin Core records and/or a delimited fields file converted to XML.

-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:cmr="http://www.canadiana.ca/XML/cmr-util"
  xmlns:cmr_dc="http://www.canadiana.ca/XML/cmr-dc"
  exclude-result-prefixes="dc cmr cmr_dc"
>

  <xsl:import href="lib/dublin_core.xsl"/>
  <xsl:import href="lib/cmr.xsl"/>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:param name="contributor">otp</xsl:param>

  <xsl:template match="/">
    <recordset version="1.0">
      <xsl:apply-templates select="records"/>
      <xsl:apply-templates select="set"/>
    </recordset>
  </xsl:template>

  <xsl:template match="records">
    <xsl:for-each select="record">
      <xsl:call-template name="cmr_dc:record">
        <xsl:with-param name="contributor" select="$contributor"/>
        <xsl:with-param name="key" select="dc:identifier[position()=last()]"/>
        <xsl:with-param name="canonicalUri" select="dc:identifier-URL[position()=1]"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- These are delimited files with Images Canada metadata converted using the csv2xml utility. -->
  <xsl:template match="set">
    <xsl:for-each select="record">
      <xsl:call-template name="images_canada"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="images_canada">
    <record>
      <type>monograph</type>
      <contributor><xsl:value-of select="$contributor"/></contributor>
      <key><xsl:value-of select="normalize-space(field[@i='7'])"/></key>
      <label>
        <xsl:choose>
          <xsl:when test="field[@i='0']">
            <xsl:value-of select="normalize-space(field[@i='0'])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space(field[@i='1'])"/>
          </xsl:otherwise>
        </xsl:choose>
      </label>

      <xsl:for-each select="field[@i='21']">
        <xsl:call-template name="cmr:lang"/>
      </xsl:for-each>

      <xsl:for-each select="field[@i='19']">
        <xsl:call-template name="cmr:media"/>
      </xsl:for-each>

      <description>

        <xsl:for-each select="field[@i='0']">
          <xsl:call-template name="cmr:title">
            <xsl:with-param name="lang">eng</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='1']">
          <xsl:call-template name="cmr:title">
            <xsl:with-param name="lang">fra</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='8']">
          <xsl:call-template name="cmr:author">
            <xsl:with-param name="lang">eng</xsl:with-param>
            <xsl:with-param name="content" select="substring-after(substring-before(., '-'), '+')"/>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='9']">
          <xsl:call-template name="cmr:author">
            <xsl:with-param name="lang">fra</xsl:with-param>
            <xsl:with-param name="content" select="substring-after(substring-before(., '-'), '+')"/>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='14']">
          <xsl:call-template name="cmr:publication">
            <xsl:with-param name="lang">eng</xsl:with-param>
            <xsl:with-param name="content" select="substring-before(substring-after(., '+'), '+')"/>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='15']">
          <xsl:call-template name="cmr:publication">
            <xsl:with-param name="lang">fra</xsl:with-param>
            <xsl:with-param name="content" select="substring-before(substring-after(., '+'), '+')"/>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='10']">
          <xsl:call-template name="cmr:subject">
            <xsl:with-param name="lang">eng</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='11']">
          <xsl:call-template name="cmr:subject">
            <xsl:with-param name="lang">fra</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='5']">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="lang">eng</xsl:with-param>
            <xsl:with-param name="type">source</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='6']">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="lang">fra</xsl:with-param>
            <xsl:with-param name="type">source</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='24']">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="lang">eng</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='25']">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="lang">fra</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='26']">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="lang">eng</xsl:with-param>
            <xsl:with-param name="type">rights</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='27']">
          <xsl:call-template name="cmr:note">
            <xsl:with-param name="lang">eng</xsl:with-param>
            <xsl:with-param name="type">rights</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='12']">
          <xsl:call-template name="cmr:text">
            <xsl:with-param name="lang">eng</xsl:with-param>
            <xsl:with-param name="type">description</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="field[@i='13']">
          <xsl:call-template name="cmr:text">
            <xsl:with-param name="lang">fra</xsl:with-param>
            <xsl:with-param name="type">description</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>

      </description>

      <resource>
        <canonicalUri>
          <xsl:choose>
            <xsl:when test="field[@i='3']">
              <xsl:value-of select="normalize-space(field[@i='3'])"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="normalize-space(field[@i='4'])"/>
            </xsl:otherwise>
          </xsl:choose>
        </canonicalUri>
      </resource>
    </record>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<xsl:import href="canmarc2iso693-3.xsl"/>

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:variable name="default_lang">
  <xsl:call-template name="canmarc2iso693-3">
    <xsl:with-param name="lang" select="substring(//marc/field[@type='008'], 36, 3)"/>
  </xsl:call-template>
</xsl:variable>


<xsl:template match="eco2">
  <recordset version="1.0">
    <xsl:apply-templates select="series"/>
    <xsl:apply-templates select="digital"/>
    <filters>
      <!--
        Remove any trailing / from the title in the label.
        Additionally, for all labels and titles, remove the [electronic
        resource] GMD
      -->
      <filter xpath="//record/*[self::label or self::clabel]" type="code">
        $_[0] =~ s!\s*/\s*$!!; $_[0] =~ s!\s*\[(electronic resource|ressource électronique)\]\s*! !; $_[0] =~ s! $!!; return $_[0];
      </filter>
      <filter xpath="//record/description/title" type="code">
        $_[0] =~ s!\s*\[(electronic resource|ressource électronique)\]\s*! !; $_[0] =~ s! $!!; return $_[0];
      </filter>

      <!--
        Fix the seq of issues by removing everything up to and
        including the final '_', leaving only an issue number.
        WARNING: there are a few records where this won't work because
        they look like 9_12345_1_2 (2-part issue).
      -->
      <filter xpath="//record/seq" type="code">$_[0] =~ s/[0-9_]*_(\d+)$/$1/; return $_[0]</filter>

      <!-- Split multiple languages codes into distinct fields -->
      <filter xpath="//record/lang" type="match" regex="..."/>
      <filter xpath="//record/lang" type="map">
        <map from="fre" to="fra"/>
      </filter>


      <!-- Map MARC field codes to controlled descriptive types -->
      <filter xpath="//record/description/*" attribute="type" type="map">
        <map from="100" to="person"/>
        <map from="110" to="corporate"/>
        <map from="111" to="corporate"/>
        <map from="130" to="uniform"/>
        <map from="245" to="main"/>
        <map from="246" to="alternate"/>
        <map from="310" to="frequency"/>
        <map from="321" to="frequency"/>
        <map from="362" to="date"/>
        <map from="500" to="general"/>
        <map from="504" to="general"/>
        <map from="505" to="general"/>
        <map from="515" to="general"/>
        <map from="520" to="descriptive"/>
        <map from="534" to="extent"/>
        <map from="546" to="language"/>
        <map from="580" to="general"/>
        <map from="595" to="general"/>
        <map from="600" to="person"/>
        <map from="610" to="corporate"/>
        <map from="611" to="corporate"/>
        <map from="630" to="uniform"/>
        <map from="650" to="topical"/>
        <map from="651" to="geographic"/>
        <map from="700" to="person"/>
        <map from="710" to="corporate"/>
        <map from="711" to="corporate"/>
        <map from="730" to="uniform"/>
        <map from="750" to="topical"/>
        <map from="751" to="geographic"/>
        <map from="780" to="relation"/>
        <map from="785" to="relation"/>
        <map from="800" to="person"/>
        <map from="810" to="corporate"/>
        <map from="830" to="uniform"/>
      </filter>

      <!-- Set the subject language field based on the @i2 indicator -->
      <filter xpath="//record/description/subject" attribute="lang" type="map">
        <map from="0" to="eng"/>
        <map from="4" to="eng"/>
        <map from="5" to="eng"/>
        <map from="6" to="fra"/>
      </filter>
    </filters>
  </recordset>
</xsl:template>


<xsl:template match="digital">
  <record>

    <!-- Required control fields -->
    <type>
      <xsl:choose>
        <xsl:when test="/eco2/@parent">issue</xsl:when>
        <xsl:otherwise>monograph</xsl:otherwise>
      </xsl:choose>
    </type>
    <contributor>oocihm</contributor>
    <key><xsl:value-of select="/eco2/@id"/></key>
    <label>
      <xsl:value-of select="normalize-space(concat(
          /eco2/digital/marc/field[@type='245']/subfield[@type='a'], ' ',
          /eco2/digital/marc/field[@type='245']/subfield[@type='h'], ' ',
          /eco2/digital/marc/field[@type='245']/subfield[@type='b']
      ))"/>
    </label>
    <!--
    <clabel>
      <xsl:value-of select="normalize-space(concat(
          /eco2/digital/marc/field[@type='245']/subfield[@type='a'], ' ',
          /eco2/digital/marc/field[@type='245']/subfield[@type='h'], ' ',
          /eco2/digital/marc/field[@type='245']/subfield[@type='b']
      ))"/>
    </clabel>
    -->

    <!-- Optional control fields -->
    <xsl:if test="/eco2/@parent">
      <pkey><xsl:value-of select="/eco2/@parent"/></pkey>
    </xsl:if>
    <gkey><xsl:call-template name="collection_code"/></gkey>
    <xsl:if test="/eco2/@parent">
      <seq><xsl:value-of select="/eco2/@id"/></seq>
    </xsl:if>
    <pubdate min="{/eco2/*/pubdate/@first}-01-01T00:00:00.000Z" max="{/eco2/*/pubdate/@last}-12-31T23:59:59.000Z"/>
    <xsl:call-template name="lang"/>
    <media>text</media>

    <description>
      <xsl:call-template name="main_description"/>
    </description>

    <resource>
      <canonicalUri><xsl:value-of select="concat('http://www.canadiana.org/record/', /eco2/@id)"/></canonicalUri>
      <canonicalDownload mime="application/pdf"><xsl:value-of select="concat('oocihm.', /eco2/@id, '.pdf')"/></canonicalDownload>
    </resource>
  </record>
  <xsl:apply-templates select="pages/page"/>
</xsl:template>

<xsl:template match="series">
  <record>

    <!-- Required control fields -->
    <type>serial</type>
    <contributor>oocihm</contributor>
    <key><xsl:value-of select="/eco2/@id"/></key>
    <label>
      <xsl:value-of select="normalize-space(concat(
          /eco2/series/marc/field[@type='245']/subfield[@type='a'], ' ',
          /eco2/series/marc/field[@type='245']/subfield[@type='h'], ' ',
          /eco2/series/marc/field[@type='245']/subfield[@type='b']
      ))"/>
    </label>
    <!--
    <clabel>
      <xsl:value-of select="normalize-space(concat(
          /eco2/series/marc/field[@type='245']/subfield[@type='a'], ' ',
          /eco2/series/marc/field[@type='245']/subfield[@type='h'], ' ',
          /eco2/series/marc/field[@type='245']/subfield[@type='b']
      ))"/>
    </clabel>
    -->

    <!-- Optional control fields -->
    <pkey><xsl:call-template name="collection_code"/></pkey>
    <gkey><xsl:call-template name="collection_code"/></gkey>
    <pubdate min="{/eco2/*/pubdate/@first}-01-01T00:00:00.000Z" max="{/eco2/*/pubdate/@last}-12-31T23:59:59.000Z"/>
    <xsl:call-template name="lang"/>
    <media>text</media>

    <description>
      <xsl:call-template name="main_description"/>
    </description>

    <resource>
      <canonicalUri><xsl:value-of select="concat('http://www.canadiana.org/record/', /eco2/@id)"/></canonicalUri>
      <canonicalDownload mime="application/pdf"><xsl:value-of select="concat('oocihm.', /eco2/@id, '.pdf')"/></canonicalDownload>
    </resource>
  </record>
</xsl:template>


<xsl:template match="page">

  <!-- Map page feature codes to their natural language equivalent -->
  <xsl:variable name="page_feature">
    <xsl:choose>
      <xsl:when test="$default_lang = 'fre'">
        <xsl:choose>
          <xsl:when test="@type='Advertisement'">annonce publicitaire</xsl:when>
          <xsl:when test="@type='Bib'">bibliographie</xsl:when>
          <xsl:when test="@type='Blank'">page blanche</xsl:when>
          <xsl:when test="@type='Cover'">couverture</xsl:when>
          <xsl:when test="@type='Index'">index</xsl:when>
          <xsl:when test="@type='ILL'">illustration</xsl:when>
          <xsl:when test="@type='LOI'">liste des illustrations</xsl:when>
          <xsl:when test="@type='Map'">cart</xsl:when>
          <xsl:when test="@type='Non-Blank'">page non-numérotée</xsl:when>
          <xsl:when test="@type='Table'">table</xsl:when>
          <xsl:when test="@type='Target'">page de données techniques</xsl:when>
          <xsl:when test="@type='Title Page'">page de titre</xsl:when>
          <xsl:when test="@type='TOC'">table des matières</xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="@type='Advertisement'">advertisement</xsl:when>
          <xsl:when test="@type='Bib'">bibliography</xsl:when>
          <xsl:when test="@type='Blank'">blank page</xsl:when>
          <xsl:when test="@type='Cover'">cover</xsl:when>
          <xsl:when test="@type='Index'">index</xsl:when>
          <xsl:when test="@type='ILL'">illustration</xsl:when>
          <xsl:when test="@type='LOI'">list of illustrations</xsl:when>
          <xsl:when test="@type='Map'">map</xsl:when>
          <xsl:when test="@type='Non-Blank'">unnumbered</xsl:when>
          <xsl:when test="@type='Table'">table</xsl:when>
          <xsl:when test="@type='Target'">technical data sheet</xsl:when>
          <xsl:when test="@type='Title Page'">title page</xsl:when>
          <xsl:when test="@type='TOC'">table of contents</xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <record>

    <!-- Required control fields -->
    <type>page</type>
    <contributor>oocihm</contributor>
    <key><xsl:value-of select="concat(/eco2/@id, '.', @seq)"/></key>
    <!--
    <label>
      <xsl:value-of select="normalize-space(concat(
          /eco2/digital/marc/field[@type='245']/subfield[@type='a'], ' ',
          /eco2/digital/marc/field[@type='245']/subfield[@type='h'], ' ',
          /eco2/digital/marc/field[@type='245']/subfield[@type='b']
      ))"/>
    </label>
    -->
    <label>
      <xsl:choose>
        <xsl:when test="$page_feature != '' and number(@n) != 0"><xsl:value-of select="concat($page_feature, ' (p. ', @n, ')')"/></xsl:when>
        <xsl:when test="$page_feature != ''"><xsl:value-of select="$page_feature"/></xsl:when>
        <xsl:when test="number(@n) != 0"><xsl:value-of select="concat('p. ', @n)"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat('image ', @seq)"/></xsl:otherwise>
      </xsl:choose>
    </label>

    <!-- Optional control fields -->
    <pkey><xsl:value-of select="/eco2/@id"/></pkey>
    <gkey><xsl:call-template name="collection_code"/></gkey>
    <xsl:if test="/eco2/@parent">
      <gkey><xsl:value-of select="/eco2/@parent"/></gkey>
    </xsl:if>
    <seq><xsl:value-of select="number(@seq)"/></seq>
    <pubdate min="{/eco2/*/pubdate/@first}-01-01T00:00:00.000Z" max="{/eco2/*/pubdate/@last}-12-31T23:59:59.000Z"/>
    <xsl:call-template name="lang"/>
    <media>text</media>

    <description>
      <xsl:choose>
        <xsl:when test="normalize-space(Words)">
          <text lang="{$default_lang}" type="content"><xsl:value-of select="normalize-space(Words)"/></text>
        </xsl:when>
        <xsl:when test="normalize-space(pagetext)">
          <text lang="{$default_lang}" type="content"><xsl:value-of select="normalize-space(pagetext)"/></text>
        </xsl:when>
      </xsl:choose>
    </description>

    <resource>
      <canonicalUri><xsl:value-of select="concat('http://www.canadiana.org/view/', /eco2/@id, '/', number(@seq))"/></canonicalUri>
      <canonicalMaster mime="image/tiff" md5="{/eco2/digital/images/image[@seq=./@seq]/@md5}">
        <xsl:value-of select="concat('oocihm.', /eco2/@id, '.', @seq, '.tif')"/>
      </canonicalMaster>
    </resource>
  </record>
</xsl:template>

<xsl:template name="main_description">
  <xsl:for-each select="//marc/field[@type='130' or @type='245' or @type='246' or @type='730']">
    <title lang="{$default_lang}" type="{@type}"><xsl:value-of select="normalize-space(.)"/></title>
  </xsl:for-each>
  <xsl:for-each select="//marc/field[@type='100' or @type='110' or @type='111' or @type='700' or @type='710' or @type='711']">
    <author type="{@type}"><xsl:value-of select="normalize-space(.)"/></author>
  </xsl:for-each>
  <publication type="main"><xsl:value-of select="normalize-space(//marc/field[@type='260'])"/></publication>
  <xsl:for-each select="//marc/field[@type='600' or @type='610' or @type='630' or @type='650' or @type='651']">
    <subject lang="{@i2}" type="{@type}">
      <xsl:for-each select="subfield">
        <xsl:if test="@type='v' or @type='x' or @type='y' or @type='z'"> -- </xsl:if>
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:for-each>
    </subject>
  </xsl:for-each>
  <xsl:for-each select="//marc/field[@type='250' or @type='310' or @type='321' or @type='362' or @type='500' or @type='504' or
    @type='505' or @type='510' or @type='515' or @type='520' or @type='534' or @type='546' or @type='580' or @type='595' or
    @type='780' or @type='787' or @type='800' or @type='810' or @type='811' or @type='830']"
  >
    <note lang="{$default_lang}" type="{@type}"><xsl:value-of select="normalize-space(.)"/></note>
  </xsl:for-each>
  <xsl:for-each select="//marc/field[@type='533']/subfield[@type='a']">
    <note lang="{$default_lang}" type="source"><xsl:value-of select="normalize-space(.)"/></note>
  </xsl:for-each>
</xsl:template>

<xsl:template name="collection_code">
  <xsl:variable name="collection" select="/eco2/*/collections/collection[@lang='en'][position()=1]"/>
  <xsl:choose>
    <xsl:when test="$collection = 'Colonial Government Journals'">cgj</xsl:when>
    <xsl:when test="$collection = 'English Canadian Literature'">ecl</xsl:when>
    <xsl:when test="$collection = 'Government Publications'">gvp</xsl:when>
    <xsl:when test="$collection = 'Governor General'">gvg</xsl:when>
    <xsl:when test="$collection = 'Health and Medicine'">hmd</xsl:when>
    <xsl:when test="$collection = 'History of French Canada'">hfc</xsl:when>
    <xsl:when test="$collection = 'Jesuit Relations'">jsr</xsl:when>
    <xsl:when test="$collection = 'Native Studies'">nas</xsl:when>
    <xsl:when test="$collection = 'Periodicals'">per</xsl:when>
    <xsl:when test="$collection = 'Reconstituted Debates'">rds</xsl:when>
    <xsl:when test="$collection = &quot;The Fur Trade and the Hudson's Bay Company&quot;">hbc</xsl:when>
    <xsl:when test="$collection = &quot;Women's History&quot;">wmh</xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template name="lang">
  <lang><xsl:value-of select="$default_lang"/></lang>
  <xsl:for-each select="//marc/field[@type='041']/subfield">
    <lang>
      <xsl:call-template name="canmarc2iso693-3">
        <xsl:with-param name="lang" select="."/>
      </xsl:call-template>
    </lang>
  </xsl:for-each>
</xsl:template>
          
</xsl:stylesheet>


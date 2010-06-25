<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:variable name="default_lang" select="substring(//marc/field[@type='008'], 36, 3)"/>

<xsl:template match="eco2">
  <recordset version="1.0">
    <xsl:apply-templates select="digital"/>
    <filters>
      <filter xpath="//record[type = 'page']/clabel" type="map">
        <map from="engAdvertisement" to="advertisement"/>
        <map from="engBib" to="bibliography"/>
        <map from="engBlank" to="blank page"/>
        <map from="engCover" to="cover"/>
        <map from="engIndex" to="index"/>
        <map from="engILL" to="illustration"/>
        <map from="engLOI" to="list of illustrations"/>
        <map from="engMap" to="map"/>
        <map from="engNon-Blank" to="unnumbered"/>
        <map from="engTable" to="table"/>
        <map from="engTarget" to="technical data sheet"/>
        <map from="engTitle Page" to="title page"/>
        <map from="engTOC" to="table of contents"/>
        <map from="freAdvertisement" to="annonce publicitiare"/>
        <map from="freBib" to="bibliographie"/>
        <map from="freBlank" to="page blanche"/>
        <map from="freCover" to="couverture"/>
        <map from="freIndex" to="index"/>
        <map from="freILL" to="illustration"/>
        <map from="freLOI" to="liste des illustrations"/>
        <map from="freMap" to="carte"/>
        <map from="freNon-Blank" to="page non-numérotée"/>
        <map from="freTable" to="table"/>
        <map from="freTarget" to="page de données techniques"/>
        <map from="freTitle Page" to="page de titre"/>
        <map from="freTOC" to="table des matières"/>
      </filter>
      <filter xpath="//record/gkey" type="map">
        <map from="Colonial Government Journals" to="cgj"/>
        <map from="English Canadian Literature" to="ecl"/>
        <map from="Government Publications" to="gvp"/>
        <map from="Governor General" to="gvg"/>
        <map from="Health and Medicine" to="hmd"/>
        <map from="History of French Canada" to="hfc"/>
        <map from="Jesuit Relations" to="jsr"/>
        <map from="Native Studies" to="nas"/>
        <map from="Periodicals" to="per"/>
        <map from="Reconstituted Debates" to="rds"/>
        <map from="The Fur Trade and the Hudson's Bay Company" to="hbc"/>
        <map from="Women's History" to="wmh"/>
      </filter>
      <filter xpath="//record/lang" type="match" regex="..."/>
      <filter xpath="//record/description/*" attribute="type" type="map">
        <map from="100" to="person"/>
        <map from="110" to="corporate"/>
        <map from="111" to="corporate"/>
        <map from="130" to="uniform"/>
        <map from="150" to="topical"/>
        <map from="151" to="geographic"/>
        <map from="245" to="main"/>
        <map from="246" to="alternate"/>
        <map from="250" to="publication"/>
        <map from="310" to="frequency"/>
        <map from="362" to="date"/>
        <map from="500" to="general"/>
        <map from="504" to="general"/>
        <map from="505" to="general"/>
        <map from="515" to="general"/>
        <map from="520" to="descriptive"/>
        <map from="534" to="extent"/>
        <map from="546" to="language"/>
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
        <map from="800" to="person"/>
        <map from="810" to="corporate"/>
        <map from="830" to="uniform"/>
      </filter>
      <filter xpath="//record/description/subject" attribute="lang" type="map">
        <map from="0" to="eng"/>
        <map from="5" to="eng"/>
        <map from="6" to="fre"/>
      </filter>
    </filters>
  </recordset>
</xsl:template>

<!-- TODO: add series support...
<xsl:template match="series">
</xsl:template>
-->

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
    <label><xsl:value-of select="/eco2/digital/marc/field[@type='245']/subfield[@type='a']"/></label>
    <clabel><xsl:value-of select="/eco2/digital/marc/field[@type='245']/subfield[@type='a']"/></clabel>

    <!-- Optional control fields -->
    <xsl:if test="/eco2/@parent">
      <pkey><xsl:value-of select="/eco2/@parent"/></pkey>
    </xsl:if>
    <gkey><xsl:value-of select="/eco2/*/collections/collection[@lang='en'][position()=1]"/></gkey>
    <pubdate min="{/eco2/*/pubdate/@first}-01-01T00:00:00.000Z" max="{/eco2/*/pubdate/@last}-12-31T23:59:59.000Z"/>
    <lang><xsl:value-of select="$default_lang"/></lang>
    <xsl:if test="//marc/field[@type='041']/subfield">
      <lang><xsl:value-of select="//marc/field[@type='041']/subfield"/></lang>
    </xsl:if>
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


<xsl:template match="page">
  <record>

    <!-- Required control fields -->
    <type>page</type>
    <contributor>oocihm</contributor>
    <key><xsl:value-of select="concat(/eco2/@id, '.', @seq)"/></key>
    <label><xsl:value-of select="/eco2/digital/marc/field[@type='245']/subfield[@type='a']"/></label>
    <clabel>
      <xsl:choose>
        <xsl:when test="@type != '' and number(@n) != 0"><xsl:value-of select="concat($default_lang, @type, '(', @n, ')')"/></xsl:when>
        <xsl:when test="@type != ''"><xsl:value-of select="concat($default_lang, @type)"/></xsl:when>
        <xsl:when test="number(@n) != 0"><xsl:value-of select="concat('p. ', @n)"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat('image ', @seq)"/></xsl:otherwise>
      </xsl:choose>
    </clabel>

    <!-- Optional control fields -->
    <pkey><xsl:value-of select="/eco2/@id"/></pkey>
    <gkey><xsl:value-of select="/eco2/*/collections/collection[@lang='en'][position()=1]"/></gkey>
    <seq><xsl:value-of select="number(@seq)"/></seq>
    <pubdate min="{/eco2/*/pubdate/@first}-01-01T00:00:00.000Z" max="{/eco2/*/pubdate/@last}-12-31T23:59:59.000Z"/>
    <lang><xsl:value-of select="$default_lang"/></lang>
    <xsl:if test="//marc/field[@type='041']/subfield">
      <lang><xsl:value-of select="//marc/field[@type='041']/subfield"/></lang>
    </xsl:if>
    <media>text</media>

    <description>
      <xsl:choose>
        <xsl:when test="Words">
          <text lang="{$default_lang}" type="content"><xsl:value-of select="normalize-space(Words)"/></text>
        </xsl:when>
        <xsl:otherwise>
          <text lang="{$default_lang}" type="content"><xsl:value-of select="normalize-space(pagetext)"/></text>
        </xsl:otherwise>
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
</xsl:template>
            
</xsl:stylesheet>


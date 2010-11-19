<?xml version="1.0" encoding="UTF-8"?>

<!--

Deprecated. Use dublin_core.xsl instead.

-->

<xsl:stylesheet version="1.0"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:cmr_dc="http://www.canadiana.ca/XML/cmr-dc"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

  <!--
    Guess the media type(s) based on the presence of various substrings.
    Usually, the content of the dc:type is passed to this template, but
    dc:format may be appropriate in some cases. Generally speaking, it is
    inadvisable to use both, as duplicate media types may be output as a
    result.
  -->
  <xsl:template name="cmr_dc:media">
    <xsl:param name="string"/>
    <xsl:variable name="data" select="translate($string, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>

    <xsl:if test="
      contains($data, 'sound') or
      contains($data, 'audio')
    ">
      <media>audio</media>
    </xsl:if>

    <xsl:if test="
      contains($data, 'dataset')
    ">
      <media>data</media>
    </xsl:if>

    <xsl:if test="
      contains($data, 'atlas') or
      contains($data, 'business card') or
      contains($data, 'drawing') or
      contains($data, 'map') or
      contains($data, 'photo') or
      contains($data, 'postcard') or
      contains($data, 'poster') or
      contains($data, 'print') or
      contains($data, 'holograph') or
      contains($data, 'image')
    ">
      <media>image</media>
    </xsl:if>

    <xsl:if test="
      contains($data, 'application/pdf') or
      contains($data, 'article') or
      contains($data, 'atlas') or
      contains($data, 'book') or
      contains($data, 'correspondance') or
      contains($data, 'document') or
      contains($data, 'journal') or
      contains($data, 'letter') or
      contains($data, 'magazine') or
      contains($data, 'manuscript') or
      contains($data, 'minutes') or
      contains($data, 'newsletter') or
      contains($data, 'newspaper') or
      contains($data, 'pamphlet') or
      contains($data, 'periodical') or
      contains($data, 'report') or
      contains($data, 'thesis') or
      contains($data, 'typescript') or
      contains($data, 'yearbook') or
      contains($data, 'text')
    ">
      <media>text</media>
    </xsl:if>

    <xsl:if test="
      contains($data, 'moving image') or
      contains($data, 'video')
    ">
      <media>video</media>
    </xsl:if>

    <!-- Other types we've seen that should probably get categorized:
      announcement
      archival
      binding
      finding aid
      collection permissions
      interactive resource
    -->
  </xsl:template>

  <!--
    Map ISO 693-1 language codes to ISO 693-3 This will work for any
    number of language codes as long as they aren't smushed together
    without delimiters (e.g.: <dc:language>enfr</dc:language> is bad;
    <dc:language>en;fr</dc:language> is okay).
  -->
  <xsl:template name="cmr_dc:lang_iso693">
    <xsl:param name="string"/>
    <xsl:if test="contains($string, 'en')"><lang>eng</lang></xsl:if>
    <xsl:if test="contains($string, 'fr')"><lang>fra</lang></xsl:if>
  </xsl:template>

  <!-- 
    Map English language names to ISO 693-3 language codes. We can also
    get 3-letter abbreviations as long as they are in all caps. Multiple
    languages in a single element are detected, but variations in
    capitalization will be missed.
  -->
  <xsl:template name="cmr_dc:lang">
    <xsl:param name="string"/>
    <!-- Abbreviations in all caps -->
    <xsl:if test="contains($string, 'CHI')"><lang>zho</lang></xsl:if>
    <xsl:if test="contains($string, 'ENG')"><lang>eng</lang></xsl:if>
    <xsl:if test="contains($string, 'FRE')"><lang>fra</lang></xsl:if>
    <xsl:if test="contains($string, 'GER')"><lang>deu</lang></xsl:if>
    <xsl:if test="contains($string, 'ITA')"><lang>ita</lang></xsl:if>
    <xsl:if test="contains($string, 'LAT')"><lang>lat</lang></xsl:if>

    <!-- Long form language names (English) including some misspellings -->
    <xsl:if test="contains($string, 'Chinese')"><lang>zho</lang></xsl:if>
    <xsl:if test="contains($string, 'Czech')"><lang>ces</lang></xsl:if>
    <xsl:if test="contains($string, 'Croatian')"><lang>hrv</lang></xsl:if>
    <xsl:if test="contains($string, 'English')"><lang>eng</lang></xsl:if>
    <xsl:if test="contains($string, 'French')"><lang>fra</lang></xsl:if>
    <xsl:if test="contains($string, 'Hini')"><lang>hin</lang></xsl:if><!-- ! -->
    <xsl:if test="contains($string, 'Hindi')"><lang>hin</lang></xsl:if>
    <xsl:if test="contains($string, 'Japanese')"><lang>jpn</lang></xsl:if>
    <xsl:if test="contains($string, 'Mandarin')"><lang>cmn</lang></xsl:if>
    <xsl:if test="contains($string, 'Polish')"><lang>pol</lang></xsl:if>
    <xsl:if test="contains($string, 'Portugese')"><lang>por</lang></xsl:if>
    <xsl:if test="contains($string, 'Panjabi')"><lang>pan</lang></xsl:if>
    <xsl:if test="contains($string, 'Punjabi')"><lang>pan</lang></xsl:if><!-- ! -->
    <xsl:if test="contains($string, 'Russian')"><lang>rus</lang></xsl:if>
    <xsl:if test="contains($string, 'Spanish')"><lang>spa</lang></xsl:if>
  </xsl:template>

  <xsl:template name="cmr_dc:description">
      <!-- Not included (at this time): language, identifier -->

      <xsl:for-each select="descendant::dc:contributor">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note type="source"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:coverage">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:creator">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <author><xsl:value-of select="normalize-space(.)"/></author>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:date">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <publication><xsl:value-of select="normalize-space(.)"/></publication>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:description">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <text type="description"><xsl:value-of select="normalize-space(.)"/></text>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:format">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note type="extent"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:publisher">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <publication><xsl:value-of select="normalize-space(.)"/></publication>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:relation">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:rights">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note type="rights"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:source">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note type="source"><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:subject">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <subject><xsl:value-of select="normalize-space(.)"/></subject>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:title">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <title><xsl:value-of select="normalize-space(.)"/></title>
        </xsl:if>
      </xsl:for-each>

      <xsl:for-each select="descendant::dc:type">
        <xsl:if test="string-length(normalize-space(.)) != 0">
          <note><xsl:value-of select="normalize-space(.)"/></note>
        </xsl:if>
      </xsl:for-each>

  </xsl:template>

</xsl:stylesheet>


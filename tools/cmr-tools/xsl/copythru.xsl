<?xml version="1.0" encoding="UTF-8"?>

<!--
  Use this stylesheet to modify existing CMR records. By default, we
  simply copy through the entire source record; import or add templates to
  modify the source.
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- E.g. change canmarc language codes to ISO-693-3 -->
<!--
<xsl:import href="canmarc2iso693-3.xsl"/>
-->

<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<xsl:template match="/|@*|node()">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
</xsl:template>

<!-- E.g. delete all clabel elements -->
<!--
<xsl:template match="clabel"/>
-->

</xsl:stylesheet>

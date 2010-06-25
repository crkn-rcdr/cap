<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" encoding="UTF-8"/>

<xsl:template match="recordset">
    <xsl:apply-templates select="record"/>
</xsl:template>

<xsl:template match="record">
    <!-- Required control fields -->
    <xsl:variable name="id" select="concat(contributor, '.', key)"/>
    <xsl:variable name="type" select="type"/>
    <xsl:variable name="contributor" select="contributor"/>
    <xsl:variable name="label" select="label"/>
    <xsl:variable name="clabel" select="clabel"/>
    <xsl:variable name="canonicalMaster_file" select="resource/canonicalMaster"/>
    <xsl:variable name="canonicalMaster_md5" select="resource/canonicalMaster/@md5"/>
INSERT INTO record(id,type,contributor,label,clabel,filename,md5)
VALUES ('<xsl:value-of select="$id"/>','<xsl:value-of select="$type"/>', '<xsl:value-of select="$contributor"/>','<xsl:value-of select="$label"/>','<xsl:value-of select="$clabel"/>','<xsl:value-of select="$canonicalMaster_file" />','<xsl:value-of select="$canonicalMaster_md5"/>');
</xsl:template>

</xsl:stylesheet>

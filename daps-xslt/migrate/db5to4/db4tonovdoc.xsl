<?xml version="1.0" encoding="UTF-8"?>
<!--
   Purpose:
     Transforms DocBook document into Novdoc

   Parameters:
     * createvalid
       Should the output be valid? 1=yes, 0=no
     * menuchoice.menu.separator (default: " > ")
       String to separate menu components in titles (only for
       guimenuitem and guisubmenu)
     * menuchoice.separator (default: "+")
       String to separate menu components in titles
     * rootid
       Process only parts of the document
     * debug.level
       Level what messages are shown (1=only warnings, 2=infos)

   Input:
     DocBook4 document

   Output:
     Novdoc document (subset of DocBook) without remarks

   DocBook 5 compatible:
     No, convert your document to DocBook 4 first

   Author:    Thomas Schraitle <toms@opensuse.org>
   Copyright (C) 2012-2015 SUSE Linux GmbH

-->

<!DOCTYPE xsl:stylesheet
[
  <!ENTITY dbinline "abbrev|acronym|biblioref|citation|
 citerefentry|citetitle|citebiblioid|emphasis|firstterm|
 foreignphrase|glossterm|termdef|footnote|footnoteref|phrase|orgname|quote|
 trademark|wordasword|personname|link|olink|ulink|action|
 application|classname|methodname|interfacename|exceptionname|
 ooclass|oointerface|ooexception|package|command|computeroutput|
 database|email|envar|errorcode|errorname|errortype|errortext|
 filename|function|guibutton|guiicon|guilabel|guimenu|guimenuitem|
 guisubmenu|hardware|interface|keycap|keycode|keycombo|keysym|
 literal|code|constant|markup|medialabel|menuchoice|mousebutton|
 option|optional|parameter|prompt|property|replaceable|
 returnvalue|sgmltag|structfield|structname|symbol|systemitem|uri|
 token|type|userinput|varname|nonterminal|anchor|author|
 authorinitials|corpauthor|corpcredit|modespec|othercredit|
 productname|productnumber|revhistory|remark|subscript|
 superscript|inlinegraphic|inlinemediaobject|inlineequation|
 synopsis|cmdsynopsis|funcsynopsis|classsynopsis|fieldsynopsis|
 constructorsynopsis|destructorsynopsis|methodsynopsis|indexterm|xref">
]>

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  version="1.0"
  exclude-result-prefixes="exslt">

  <xsl:import href="../../common/copy.xsl"/>
  <!--<xsl:import href="rootid.xsl"/>-->

  <xsl:output method="xml" indent="yes"
    doctype-public="-//Novell//DTD NovDoc XML V1.0//EN"
    doctype-system="novdocx.dtd"/>

  <xsl:strip-space elements="cmdsynopsis arg group"/>
  <!--<xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="screen programlisting"/>-->

  <!-- ################################################################## -->
  <!-- Parameters                                                         -->

  <!-- Should the output be valid? 1=yes, 0=no -->
  <xsl:param name="createvalid" select="1"/>
  <xsl:param name="menuchoice.menu.separator"> > </xsl:param>
  <xsl:param name="menuchoice.separator">+</xsl:param>
  <xsl:param name="rootid"/>
  <xsl:param name="use.doctype4novdoc" select="0"/>
  <xsl:param name="debug.level" select="4"/>

  <!-- cmdsynopsis: args & groups -->
  <xsl:param name="arg.choice.opt.open.str">[</xsl:param>
  <xsl:param name="arg.choice.opt.close.str">]</xsl:param>
  <xsl:param name="arg.choice.req.open.str">{</xsl:param>
  <xsl:param name="arg.choice.req.close.str">}</xsl:param>
  <xsl:param name="arg.choice.plain.open.str"><xsl:text> </xsl:text></xsl:param>
  <xsl:param name="arg.choice.plain.close.str"><xsl:text> </xsl:text></xsl:param>
  <xsl:param name="arg.choice.def.open.str">[</xsl:param>
  <xsl:param name="arg.choice.def.close.str">]</xsl:param>
  <xsl:param name="arg.rep.repeat.str">...</xsl:param>
  <xsl:param name="arg.rep.norepeat.str"></xsl:param>
  <xsl:param name="arg.rep.def.str"></xsl:param>
  <xsl:param name="arg.or.sep"> | </xsl:param>


  <xsl:key name="id" match="*" use="@id|@xml:id"/>

  <!-- ################################################################## -->
  <!-- Suppressed PIs                                                     -->
  <xsl:template match="processing-instruction('xml-stylesheet')"/>


  <!-- ################################################################## -->
  <!-- Suppressed attributes                                              -->

  <!-- Suppressed attributes -->
  <xsl:template match="@action"/>
  <xsl:template match="@continuation"/>
  <xsl:template match="@format"/>
  <xsl:template match="@float"/>

  <!-- Novdoc supports @frame="none"/@frame="topbot" but neither of these values
  are supported by DocBook 5. The DB5 equivalents to Novdoc's attributes are
  "void" and "hsides," it seems. But the attribute is used so little ... Let's
  not bother implementing this. -->
  <xsl:template match="table/@frame|informaltable/@frame"/>

  <xsl:template match="@inheritnum"/>
  <xsl:template match="section/@lang|sect1/@lang"/>
  <xsl:template match="@moreinfo"/>
  <xsl:template match="@significance"/>
  <xsl:template match="@mark"/>
  <xsl:template match="@spacing"/>
  <xsl:template match="*/@status"/>
  <xsl:template match="book/@xml:base"/>
  <xsl:template match="productname/@class"/>
  <xsl:template match="orderedlist/@spacing[. ='normal']"/>
  <xsl:template match="step/@performance[. = 'required']"/>
  <xsl:template match="substeps/@performance[. = 'required']"/>
  <xsl:template match="@rules[. ='all']"/>
  <xsl:template match="@wordsize"/>
  <xsl:template match="productname/@class"/>
  <xsl:template match="screen/@language"/>
  <xsl:template match="filename/@class"/>
  <xsl:template match="literallayout/@class"/>
  <xsl:template match="variablelist/@role"/>
  <xsl:template match="imagedata/@depth"/>

  <xsl:template match="warning/@role|tip/@role|note/@role|important/@role|caution/@role"/>
  <xsl:template match="set/@label|article/@label|book/@label|part/@label|chapter/@label|*[contains(local-name(.), 'sect')]/@label">
    <xsl:call-template name="warn">
      <xsl:with-param name="text">
        <xsl:text>Removed "label" attribute from </xsl:text>
        <xsl:value-of select="local-name(parent::*)"/>
        <xsl:text>: Document structure is now inconsistent with non-Novdoc version.</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="node" select="parent::*"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ################################################################## -->
  <!-- Suppressed Elements for Novdoc                                     -->
  <xsl:template match="abstract/title"/>
  <xsl:template match="appendixinfo|chapterinfo|prefaceinfo|partinfo"/>
  <xsl:template match="sect1info|sect2info|sect3info|sect4info|sect5info"/>
  <xsl:template match="remark"/>


  <!-- ################################################################## -->
  <!-- Named Templates                                                    -->

  <xsl:template name="message">
    <xsl:param name="text"/>
    <xsl:param name="type"/>
    <xsl:param name="abort" select="0"/>
    <xsl:param name="node" select="."/>

    <xsl:message>
      <xsl:attribute name="terminate">
        <xsl:choose>
          <xsl:when test="$abort != 0 and 0 = 1">yes</xsl:when>
          <xsl:otherwise>no</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="$type"/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$text"/>
      <xsl:text>&#10;  (</xsl:text>
      <xsl:choose>
       <xsl:when test="$node/@id">
         <xsl:text>has ID: </xsl:text>
         <xsl:value-of select="$node/@id"/>
       </xsl:when>
       <xsl:when test="$node/ancestor::*/@id">
         <xsl:text>within ID: </xsl:text>
         <xsl:value-of select="$node/ancestor::*[@id][1]/@id"/>
       </xsl:when>
      </xsl:choose>
      <xsl:if test="$node/title|$node/*[contains(local-name(.), 'info')]/title">
        <xsl:if test="$node/ancestor-or-self::*/@id">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:variable name="title-candidate">
          <xsl:value-of select="($node/title|$node/*[contains(local-name(.), 'info')]/title)[1]"/>
        </xsl:variable>
        <xsl:variable name="title">
          <xsl:choose>
            <xsl:when test="string-length($title-candidate) &gt; 30">
              <xsl:value-of select="substring($title-candidate, 1, 27)"/>
              <xsl:text>...</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$title-candidate"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:text>title: </xsl:text>
        <xsl:value-of select="$title"/>
      </xsl:if>
      <xsl:text>)</xsl:text>
    </xsl:message>
  </xsl:template>

  <xsl:template name="fatal">
    <xsl:param name="text"/>
    <xsl:param name="node" select="."/>
    <xsl:call-template name="message">
      <xsl:with-param name="type">FATAL</xsl:with-param>
      <xsl:with-param name="text" select="$text"/>
      <xsl:with-param name="abort" select="1"/>
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="warn">
    <xsl:param name="text"/>
    <xsl:param name="node" select="."/>
    <xsl:if test="$debug.level > 1">
      <xsl:call-template name="message">
        <xsl:with-param name="type">WARNING</xsl:with-param>
        <xsl:with-param name="text" select="$text"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template name="info">
    <xsl:param name="text"/>
    <xsl:param name="node" select="."/>
    <xsl:if test="$debug.level > 2">
      <xsl:call-template name="message">
        <xsl:with-param name="type">INFO</xsl:with-param>
        <xsl:with-param name="text" select="$text"/>
        <xsl:with-param name="node" select="$node"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="getrootname">
    <xsl:choose>
      <xsl:when test="$rootid !=''">
        <xsl:if test="count(key('id',$rootid)) = 0">
          <xsl:message terminate="yes">
            <xsl:text>ID '</xsl:text>
            <xsl:value-of select="$rootid"/>
            <xsl:text>' not found in document.</xsl:text>
          </xsl:message>
        </xsl:if>
        <xsl:value-of select="local-name(key('id',$rootid)[1])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="local-name(/*[1])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="test4para">
    <xsl:choose>
      <!-- Test, if the second element is a section. In that case,
                 insert a para to make it a valid Novdoc source
                 depending on the $createvalid parameter
            -->
      <xsl:when test="*[2][self::sect1 or self::sect2 or self::sect3 or self::sect4 or self::section]">
        <xsl:apply-templates select="title"/>
        <xsl:choose>
          <xsl:when test="$createvalid != 0">
            <para><remark role="fixme">Add a short description</remark></para>
          </xsl:when>
          <xsl:otherwise>
            <xsl:comment>FIXME: Add a short description</xsl:comment>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="node()[not(self::title)]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="process.menuchoice">
    <xsl:param name="nodelist"
               select="guibutton|guiicon|guilabel|guimenu|
                       guimenuitem|guisubmenu|interface"/><!-- not(shortcut) -->
    <xsl:param name="count" select="1"/>

    <xsl:choose>
      <xsl:when test="$count>count($nodelist)"></xsl:when>
      <xsl:when test="$count=1">
        <xsl:apply-templates select="$nodelist[$count=position()]"/>
        <xsl:call-template name="process.menuchoice">
          <xsl:with-param name="nodelist" select="$nodelist"/>
          <xsl:with-param name="count" select="$count+1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="node" select="$nodelist[$count=position()]"/>
        <xsl:choose>
          <xsl:when test="local-name($node)='guimenuitem'
            or local-name($node)='guisubmenu'">
            <xsl:value-of select="$menuchoice.menu.separator"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$menuchoice.separator"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="$node"/>
        <xsl:call-template name="process.menuchoice">
          <xsl:with-param name="nodelist" select="$nodelist"/>
          <xsl:with-param name="count" select="$count+1"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ################################################################## -->
  <!-- Templates                                                          -->

  <xsl:template match="book/title|book/subtitle|book/titleabbrev"/><!-- Don't copy -->

  <xsl:template match="book[not(bookinfo)]">
   <book>
    <xsl:copy-of select="@*"/>
    <xsl:call-template name="bookinfo"/>
    <xsl:apply-templates/>
   </book>
  </xsl:template>

  <xsl:template match="bookinfo" name="bookinfo">
    <bookinfo>
      <xsl:apply-templates select="(title|../title)[1]" mode="title"/>
      <xsl:choose>
        <xsl:when test="productname">
         <xsl:apply-templates select="productname"/>
        </xsl:when>
        <xsl:otherwise>
         <xsl:apply-templates select="/set/setinfo[1]/productname[1]"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
       <xsl:when test="productnumber">
        <xsl:apply-templates select="productnumber"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:apply-templates select="/set/setinfo[1]/productnumber[1]"/>
       </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
       <xsl:when test="date">
        <xsl:apply-templates select="date"/>
       </xsl:when>
       <xsl:otherwise>
        <date><?dbtimestamp?></date>
       </xsl:otherwise>
      </xsl:choose>

      <xsl:apply-templates select="releaseinfo"/>
      <xsl:choose>
        <xsl:when test="legalnotice">
          <xsl:copy-of select="legalnotice"/>
        </xsl:when>
        <xsl:otherwise>
         <legalnotice><para/></legalnotice>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="authorgroup"/>
      <xsl:apply-templates select="abstract"/>
    </bookinfo>
  </xsl:template>

  <xsl:template match="chapter|appendix">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="(title|*/title)[1]"/>
      <xsl:if test="self::chapter">
        <xsl:apply-templates select="(subtitle|../subtitle)[1]"/>
      </xsl:if>
      <!--<xsl:copy-of select="(titleabbrev|../titleabbrev)[1]"/>-->
      <xsl:choose>
        <xsl:when test="abstract">
          <xsl:apply-templates select="abstract"/>
        </xsl:when>
        <xsl:when test="*/abstract">
          <xsl:apply-templates select="*/abstract"/>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates select="node()[not(self::title or
                                              self::subtitle or
                                              self::titleabbrev or
                                              self::abstract)]"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="part/subtitle">
   <xsl:comment> subtitle=<xsl:value-of select="normalize-space(.)"/> </xsl:comment>
   <xsl:call-template name="warn">
     <xsl:with-param name="text">Removed part/subtitle</xsl:with-param>
   </xsl:call-template>
  </xsl:template>


  <!-- ################################################################## -->
  <!-- Templates for Division Elements                                    -->
  <xsl:template match="section">
    <xsl:variable name="depth" select="count(ancestor::section)+1"/>

    <xsl:choose>
      <xsl:when test="$depth &lt; 5">
        <xsl:element name="sect{$depth}">
          <xsl:apply-templates select="@*"/>
          <xsl:call-template name="test4para"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <!--<xsl:message>***<xsl:value-of select="concat(name(), ' #' , @id)"/>: <xsl:value-of
        select="$depth"/></xsl:message>-->
        <xsl:text>&#10;</xsl:text>
        <xsl:comment>sect5</xsl:comment>
        <bridgehead><!--  id="{@id}" -->
          <xsl:copy-of select="@id"/>
          <xsl:apply-templates select="title"/>
        </bridgehead>
        <xsl:apply-templates select="node()[not(self::title)]"/>
        <xsl:comment>/sect5</xsl:comment>
        <xsl:text>&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="section/section/section/section/section/title|sect5/title">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="sect1/subtitle | sect2/subtitle | sect3/subtitle | sect4/subtitle | sect5/subtitle"/>

  <xsl:template match="sect1|sect2|sect3|sect4">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="test4para"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="sect5">
    <xsl:message>bridgehead: <xsl:value-of select="name()"/></xsl:message>
    <bridgehead>
       <xsl:copy-of select="@id"/>
       <xsl:apply-templates select="title"/>
    </bridgehead>
    <xsl:apply-templates select="node()[not(self::title)]"/>
  </xsl:template>

  <xsl:template match="qandaset/title">
   <xsl:comment> title=<xsl:value-of select="normalize-space(.)"/> </xsl:comment>
   <xsl:call-template name="warn">
     <xsl:with-param name="text">Removed qandaset/title</xsl:with-param>
   </xsl:call-template>
  </xsl:template>

 <xsl:template match="title" mode="title">
  <xsl:call-template name="create.title"/>
 </xsl:template>

  <xsl:template match="title" name="create.title">
   <xsl:variable name="title.text">
    <xsl:apply-templates/>
   </xsl:variable>
   <title><xsl:value-of select="string($title.text)"/></title>
  </xsl:template>

  <xsl:template match="title/ulink">
   <xsl:call-template name="warn">
     <xsl:with-param name="text">Removed ulink tag in title </xsl:with-param>
   </xsl:call-template>
   <xsl:value-of select="."/>
  </xsl:template>

 <xsl:template match="title/xref">
   <xsl:call-template name="warn">
     <xsl:with-param name="text">Removed xref tag in title </xsl:with-param>
   </xsl:call-template>
  </xsl:template>

  <!-- ################################################################## -->
  <!-- Templates for Inline Elements                                      -->

  <xsl:template match="application|abbrev|firstterm|para/glossterm">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="command/command">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="*[ancestor::citetitle]">
    <xsl:call-template name="info">
      <xsl:with-param name="text">Removed <xsl:value-of select="local-name()"/> within citetitle</xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="guilabel|guibutton|guimenuitem|guiicon|guisubmenu">
    <guimenu>
      <xsl:apply-templates/>
    </guimenu>
  </xsl:template>

  <xsl:template match="guilabel/replaceable|guimenu/replaceable">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="constant|errorcode|classname|code|computeroutput|function|methodname|
                       prompt[not(parent::screen)]|property|sgmltag|returnvalue|uri|userinput">
    <literal>
      <xsl:apply-templates/>
    </literal>
  </xsl:template>

  <xsl:template match="errortext">
    <emphasis>
      <xsl:apply-templates/>
    </emphasis>
  </xsl:template>

  <xsl:template match="literal[ulink]">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="literal/emphasis">
   <replaceable><xsl:apply-templates/></replaceable>
  </xsl:template>

  <xsl:template match="literal/ulink[normalize-space(.) != '']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <literal>
        <xsl:apply-templates/>
      </literal>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="package">
    <systemitem class="resource">
      <xsl:apply-templates/>
    </systemitem>
  </xsl:template>

  <xsl:template match="parameter">
    <option>
      <xsl:apply-templates/>
    </option>
  </xsl:template>

  <xsl:template match="author/personname">
   <!-- Ignore any personname inside author -->
   <xsl:call-template name="info">
      <xsl:with-param name="text">Removed personname inside author</xsl:with-param>
    </xsl:call-template>
   <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="systemitem[@class='protocol']">
    <systemitem>
      <xsl:apply-templates/>
    </systemitem>
  </xsl:template>

  <xsl:template match="systemitem[ancestor::screen]">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ################################################################## -->
  <!-- Templates for Block Elements                                       -->

  <xsl:template match="cmdsynopsis">
   <screen><xsl:apply-templates/></screen>
  </xsl:template>

  <xsl:template match="cmdsynopsis/text()"/>

  <xsl:template match="cmdsynopsis/command">
   <command><xsl:apply-templates/></command>
   <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="group | arg" name="group-or-arg">
   <xsl:variable name="choice" select="@choice"/>
   <xsl:variable name="rep" select="@rep"/>
   <xsl:variable name="sepchar">
    <xsl:choose>
     <xsl:when test="ancestor-or-self::*/@sepchar">
      <xsl:value-of select="ancestor-or-self::*/@sepchar"/>
     </xsl:when>
     <xsl:otherwise>
      <xsl:text> </xsl:text>
     </xsl:otherwise>
    </xsl:choose>
   </xsl:variable>

   <xsl:if test="preceding-sibling::*">
    <xsl:value-of select="$sepchar"/>
   </xsl:if>
   <xsl:choose>
    <xsl:when test="$choice = 'plain'">
     <xsl:value-of select="$arg.choice.plain.open.str"/>
    </xsl:when>
    <xsl:when test="$choice = 'req'">
     <xsl:value-of select="$arg.choice.req.open.str"/>
    </xsl:when>
    <xsl:when test="$choice = 'opt'">
     <xsl:value-of select="$arg.choice.opt.open.str"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$arg.choice.def.open.str"/>
    </xsl:otherwise>
   </xsl:choose>
   <xsl:apply-templates/>
   <xsl:choose>
    <xsl:when test="$rep = 'repeat'">
     <xsl:value-of select="$arg.rep.repeat.str"/>
    </xsl:when>
    <xsl:when test="$rep = 'norepeat'">
     <xsl:value-of select="$arg.rep.norepeat.str"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$arg.rep.def.str"/>
    </xsl:otherwise>
   </xsl:choose>
   <xsl:choose>
    <xsl:when test="$choice = 'plain'">
     <xsl:value-of select="$arg.choice.plain.close.str"/>
    </xsl:when>
    <xsl:when test="$choice = 'req'">
     <xsl:value-of select="$arg.choice.req.close.str"/>
    </xsl:when>
    <xsl:when test="$choice = 'opt'">
     <xsl:value-of select="$arg.choice.opt.close.str"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$arg.choice.def.close.str"/>
    </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

  <xsl:template match="group/arg">
   <xsl:variable name="choice" select="@choice"/>
   <xsl:variable name="rep" select="@rep"/>
   <xsl:if test="preceding-sibling::*">
    <xsl:value-of select="$arg.or.sep"/>
   </xsl:if>
   <xsl:call-template name="group-or-arg"/>
  </xsl:template>

  <xsl:template match="sbr">
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="blockquote/attribution">
   <xsl:call-template name="info">
      <xsl:with-param name="text">Changed blockquote/attribution -> para/emphasis</xsl:with-param>
    </xsl:call-template>
   <para><emphasis>
    <xsl:apply-templates/>
   </emphasis></para>
  </xsl:template>

  <xsl:template match="mediaobject[textobject]" priority="1">
    <xsl:call-template name="info">
      <xsl:with-param name="text">Changed order of mediaobject/textobject</xsl:with-param>
    </xsl:call-template>
    <mediaobject>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="textobject"/>
      <xsl:apply-templates select="*[not(self::textobject)]"/>
    </mediaobject>
  </xsl:template>

  <xsl:template match="textobject[not(@role)]">
    <xsl:call-template name="info">
      <xsl:with-param name="text">Added missing textobject/@role attribute</xsl:with-param>
    </xsl:call-template>
    <textobject>
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="role">description</xsl:attribute>
      <xsl:apply-templates/>
    </textobject>
  </xsl:template>

  <xsl:template match="mediaobject/textobject[screen]">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="mediaobject[not(parent::entry)]">
   <xsl:choose>
    <xsl:when test="parent::figure or parent::informalfigure">
     <xsl:copy-of select="."/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:message>Wrapped informalfigure around mediaobject. Parent: <xsl:value-of
      select="local-name(parent::*)"/></xsl:message>
     <informalfigure>
      <xsl:copy-of select="."/>
     </informalfigure>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:template>

  <xsl:template match="literallayout">
    <screen>
      <xsl:apply-templates/>
    </screen>
  </xsl:template>

  <xsl:template match="simplelist[@type='vert']">
    <xsl:call-template name="info">
      <xsl:with-param name="text">
        <xsl:text>Converted simplelist[@type='vert'] -> itemizedlist</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <itemizedlist>
      <xsl:apply-templates/>
    </itemizedlist>
  </xsl:template>

  <xsl:template match="simplelist[@type='vert']/member">
    <xsl:call-template name="info">
      <xsl:with-param name="text">
        <xsl:text>Converted simplelist[@type='vert']/member -> listitem</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <listitem>
      <para>
        <xsl:apply-templates/>
      </para>
    </listitem>
  </xsl:template>

  <xsl:template match="itemizedlist[para or note]">
    <xsl:apply-templates select="itemizedlist/para | itemizedlist/note"/>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()[not(self::para or self::note)]"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="listitem/procedure">
    <xsl:call-template name="info">
      <xsl:with-param name="text">
        <xsl:text>Converted listitem/procedure -> listitem/itemizedlist</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <itemizedlist>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </itemizedlist>
  </xsl:template>
  <xsl:template match="listitem/procedure/step">
    <xsl:call-template name="info">
      <xsl:with-param name="text">
        <xsl:text>Converted listitem/procedure/step -> listitem/itemizedlist/listitem</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <listitem>
      <xsl:apply-templates/>
    </listitem>
  </xsl:template>

  <xsl:template match="note/procedure|tip/procedure|warning/procedure|important/procedure">
    <xsl:call-template name="info">
      <xsl:with-param name="text">Changed procedure -> orderedlist inside <xsl:value-of select="local-name(.)"/></xsl:with-param>
    </xsl:call-template>
    <orderedlist>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </orderedlist>
  </xsl:template>

  <xsl:template match="note/procedure/step|tip/procedure/step|warning/procedure/step|important/procedure/step">
    <!--<xsl:call-template name="info">
      <xsl:with-param name="text">Changed step -> listitem inside procedure</xsl:with-param>
    </xsl:call-template>-->
    <listitem>
      <xsl:apply-templates/>
    </listitem>
  </xsl:template>

  <xsl:template match="note/formalpara">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="note[figure]|caution[figure]|warning[figure]|important[figure]">
    <xsl:comment> Removed <xsl:value-of select="name()"/> start</xsl:comment>
    <xsl:choose>
      <xsl:when test="@id">
        <xsl:call-template name="warn">
          <xsl:with-param name="text">
            <xsl:text>Admonition with id='</xsl:text>
            <xsl:value-of select="@id"/>
            <xsl:text>' contains figure.&#10;</xsl:text>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="warn">
          <xsl:with-param name="text">
            <xsl:text>Removed admonition (</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>) and figure, but preserved content</xsl:text>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:apply-templates select="*[not(self::title)]"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:comment> Removed <xsl:value-of select="name()"/> end</xsl:comment>
  </xsl:template>


  <xsl:template match="step/procedure">
   <substeps>
    <xsl:apply-templates/>
   </substeps>
  </xsl:template>

  <xsl:template match="step/title">
    <para><emphasis role="bold">
      <xsl:apply-templates/>
    </emphasis></para>
  </xsl:template>

  <xsl:template match="step[*[1][not(self::para)]]">
    <xsl:call-template name="info">
      <xsl:with-param name="text">Added para at first position under step</xsl:with-param>
    </xsl:call-template>
    <step>
      <xsl:apply-templates select="@*"/>
      <para/>
      <xsl:apply-templates/>
    </step>
  </xsl:template>

  <xsl:template match="stepalternatives|stepalternatives/step/substeps">
    <itemizedlist>
      <xsl:apply-templates/>
    </itemizedlist>
  </xsl:template>

  <xsl:template match="stepalternatives/step|stepalternatives/step/substeps/step">
    <listitem>
      <xsl:apply-templates/>
    </listitem>
  </xsl:template>

  <xsl:template match="title/menuchoice">
      <xsl:call-template name="process.menuchoice"/>
  </xsl:template>

  <xsl:template match="screen/@remap">
    <xsl:attribute name="remap">
      <xsl:value-of select="."/>
    <xsl:if test="../@language">
      <xsl:value-of select="concat('-', ../@language)"/>
    </xsl:if>
    </xsl:attribute>
  </xsl:template>

  <xsl:template
    match="screen/*[not(
                     self::co|self::emphasis|self::replaceable|self::command|
                     self::prompt| self::option|self::phrase|self::xref|
                     self::link|self::ulink|self::uri
                   )]">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

  <!-- entry/variablelist handling -->
  <xsl:template match="entry/variablelist">
    <itemizedlist>
      <xsl:apply-templates/>
    </itemizedlist>
  </xsl:template>

  <xsl:template match="entry/variablelist/varlistentry">
    <listitem>
      <xsl:apply-templates select="term"/>
      <xsl:apply-templates select="node()[not(self::term)]"/>
    </listitem>
  </xsl:template>

  <xsl:template match="entry/variablelist/varlistentry/term">
    <para>
      <xsl:apply-templates/>
    </para>
  </xsl:template>

  <xsl:template match="entry/variablelist/varlistentry/listitem">
    <xsl:apply-templates/>
  </xsl:template>
  <!-- entry/variablelist handling end -->

  <!-- entry/procedure handling -->
  <xsl:template match="procedure[ancestor::entry]|substeps[ancestor::entry]">
    <orderedlist>
      <xsl:apply-templates/>
    </orderedlist>
  </xsl:template>

  <xsl:template match="step[ancestor::entry]">
    <listitem>
      <xsl:apply-templates select="@*|node()"/>
    </listitem>
  </xsl:template>

  <!-- entry/procedure handling end -->

  <!-- handling of complicated examples -->
  <xsl:template match="example[*[not(self::title or self::itemizedlist or
                                     self::orderedlist or self::simplelist or
                                     self::variablelist or self::calloutlist or
                                     self::formalpara or self::para or
                                     self::screen or self::indexterm)]]">
    <!-- I'd rather have it render like sect5 but that is forbidden in Novdoc. -->
    <bridgehead renderas="sect4">
      <xsl:if test="@id">
        <xsl:copy-of select="@id"/>
      </xsl:if>
      <xsl:apply-templates select="title/node()"/>
    </bridgehead>
    <xsl:apply-templates select="node()[not(self::title)]"/>
    <xsl:call-template name="info">
      <xsl:with-param name="text">Removed example tag and replaced its title with bridgehead</xsl:with-param>
    </xsl:call-template>
  </xsl:template>
  <!-- handling of complicated examples end -->

  <!-- we don't allow informalfigure in entry, but mediaobject. So... -->
  <xsl:template match="entry/informalfigure">
   <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="entry">
    <xsl:variable name="dbinline" select="count(&dbinline;)"/>
    <xsl:variable name="all" select="count(*)"/>
    <xsl:variable name="diff" select="$all - $dbinline"/>
    <entry>
      <!--<xsl:call-template name="info">
        <xsl:with-param name="text">
          <xsl:text>>> Table entry first child: </xsl:text>
          <xsl:value-of select="local-name(*[1])"/>
          <xsl:text>&#10; first text node: "</xsl:text>
          <xsl:value-of select="normalize-space(text()[1])"/>
          <xsl:text>"</xsl:text>
          <xsl:text>&#10; inlines=</xsl:text>
          <xsl:value-of select="count(&dbinline;)"/>
          <xsl:text> - </xsl:text>
          <xsl:value-of select="count(*)"/>
        </xsl:with-param>
      </xsl:call-template>-->
      <xsl:choose>
        <xsl:when test="$diff = 0">
          <!-- Attributes that belong to entry itself need to stay with entry
          and not be pushed onto the para. -->
          <xsl:apply-templates select="@*"/>
          <para>
            <xsl:apply-templates select="node()"/>
          </para>
        </xsl:when>
        <xsl:when test="normalize-space(text()[1]) != '' and $diff >0">
          <xsl:call-template name="warn">
            <xsl:with-param name="text">
              <xsl:text>Sorry, can't handle mixed content of inlines and blocks in entry for now. </xsl:text>
              <xsl:text>Check your XML source and wrap text in paras. </xsl:text>
              <xsl:if test="ancestor::table/@id">
                <xsl:text>table id=</xsl:text>
                <xsl:value-of select="ancestor::table/@id"/>
              </xsl:if>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:otherwise>
      </xsl:choose>
    </entry>
  </xsl:template>

  <!-- Novdoc does not support tfoot, but we can try to treat its content
  like normal tbody content (but we'll append the tfoot content after the
  normal rows). -->
  <xsl:template match="tfoot"/>
  <xsl:template match="tbody">
    <tbody>
      <xsl:apply-templates select="node()|@*"/>
      <xsl:if test="../tfoot">
        <xsl:apply-templates select="../tfoot/node()|../tfoot/@*"/>
      </xsl:if>
    </tbody>
  </xsl:template>

  <!-- Novdoc does not allow affiliation, but we can do tricks to pull that
  info into one of the name fields (here: surname). To make sure that we
  always get same layout, we just try stuff everything in the same tag. -->
  <xsl:template match="*[self::author|self::collab|self::editor|self::othercredit][affiliation]">
    <xsl:variable name="element">
      <xsl:choose>
        <xsl:when test="ancestor::authorgroup">
          <xsl:value-of select="local-name(.)"/>
        </xsl:when>
        <xsl:otherwise>author</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$element}">
      <!-- Firstname is bogus, but necessary for Novdoc. However, if we use
      some non-bogus first name, that would allow for ugly firstname/surname
      resortings with optional added punctuation *somewhere*, depending on
      locale. This way, we at least always correctly print a Western order of
      the names. -->
      <firstname/>
      <surname>
        <xsl:if test="honorific">
          <xsl:value-of select="honorific[1]"/>
          <xsl:if test="firstname or surname or lineage">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:if test="firstname">
          <xsl:value-of select="firstname[1]"/>
          <xsl:if test="surname or lineage">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:if test="surname">
          <xsl:value-of select="surname[1]"/>
          <xsl:if test="lineage">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:if test="lineage">
          <xsl:value-of select="lineage[1]"/>
        </xsl:if>
        <xsl:if test="affiliation">
          <xsl:text>, </xsl:text>
          <xsl:if test="affiliation[1]/jobtitle">
            <xsl:value-of select="affiliation[1]/jobtitle[1]"/>
            <xsl:if test="affiliation[1]/orgname">
              <xsl:text>, </xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:if test="affiliation[1]/orgname">
            <xsl:value-of select="affiliation[1]/orgname[1]"/>
          </xsl:if>
          <xsl:if test="affiliation[1]/orgdiv">
            <xsl:text> (</xsl:text>
            <xsl:value-of select="affiliation[1]/orgdiv[1]"/>
            <xsl:text>)</xsl:text>
          </xsl:if>
        </xsl:if>
      </surname>
    </xsl:element>
  </xsl:template>

  <!-- Novdoc does not support callouts with multiple arearefs, e.g. like:
  <callout arearefs="callout1 callout2". We separate this out into one
  callout with normal text and then callouts with just - " - (ditto mark) as
  text. -->

  <xsl:template match="callout[contains(normalize-space(@arearefs), ' ')]">
    <xsl:param name="refs" select="concat(normalize-space(@arearefs), ' ')"/>
    <xsl:variable name="thisref" select="substring-before($refs, ' ')"/>
    <xsl:variable name="node" select="."/>

    <callout arearefs="{$thisref}">
      <xsl:apply-templates select="@*[not(name(.) = 'arearefs')]"/>
      <xsl:choose>
        <xsl:when test="local-name(*[1]) = 'para'">
          <para>
            <xsl:apply-templates select="*[1]/@*"/>
            <xsl:call-template name="generate-co">
              <xsl:with-param name="refs" select="substring-after($refs, ' ')"/>
            </xsl:call-template>
            <xsl:apply-templates select="(*[1]/node())"/>
          </para>
          <xsl:apply-templates select="node()[not(self::* = $node/*[1])]"/>
        </xsl:when>
        <xsl:otherwise>
          <para>
            <xsl:call-template name="generate-co">
              <xsl:with-param name="refs" select="substring-after($refs, ' ')"/>
            </xsl:call-template>
          </para>
          <xsl:apply-templates select="*"/>
        </xsl:otherwise>
      </xsl:choose>
    </callout>
  </xsl:template>

  <xsl:template name="generate-co">
    <xsl:param name="refs" select="' '"/>
    <xsl:variable name="thisref" select="substring-before($refs, ' ')"/>

    <xsl:if test="$refs != ' ' and $refs != ''">
      <xref linkend="{$thisref}" xrefstyle="select:label nopage"/>

      <xsl:call-template name="generate-co">
        <xsl:with-param name="refs" select="substring-after($refs, ' ')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template match="glosslist">
   <variablelist>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
   </variablelist>
  </xsl:template>

  <xsl:template match="glosslist/glossentry">
   <varlistentry>
    <xsl:apply-templates/>
   </varlistentry>
  </xsl:template>

 <xsl:template match="glosslist/glossentry/glossterm">
  <term>
   <xsl:apply-templates/>
  </term>
 </xsl:template>

 <xsl:template match="glosslist/glossentry/glossdef">
  <listitem>
   <xsl:apply-templates/>
  </listitem>
 </xsl:template>

</xsl:stylesheet>

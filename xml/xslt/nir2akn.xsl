<?xml version="1.0" encoding="UTF-8"?>
<!--
    CC-by 4.0 CIRSFID- University of Bologna
    Author: CIRSFID, University of Bologna
    Developers: Monica Palmirani, Luca Cervone, Matteo Nardi
    Contacts: monica.palmirani@unibo.it
 -->
<xsl:stylesheet version="2.0"
    xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0/CSD13"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:nir="http://www.normeinrete.it/nir/2.2/"
    xmlns:dsp="http://www.normeinrete.it/nir/disposizioni/2.2/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:h="http://www.w3.org/HTML/1998/html4"
    xmlns:cirsfid="http://www.cirsfid.unibo.it/norma/proprietario/"
    xmlns:u="http://www.sinatra.cirsfid.unibo.it/nir2akn/#conversioneUrn"
    exclude-result-prefixes="xsl nir dsp xlink h u">
    <xsl:output indent="yes"/>
    <xsl:strip-space elements="*"/>

    <!-- - - - - - - - - - - - - -->
    <!-- Parametri dello script  -->
    <!-- - - - - - - - - - - - - -->
    <xsl:param name="today"/>

    <!-- - - - - - - - - - - - - - - - - - - -->
    <!-- Variabili usate in tutto lo script  -->
    <!-- - - - - - - - - - - - - - - - - - - -->

    <!-- Identifica la sorgente del documento -->
    <!-- Questa euristica non e' completamente corretta: sarebbe meglio avere un parametro allo script -->
    <xsl:variable name="sorgente">
        <xsl:choose>
            <xsl:when test="contains(//nir:urn/@valore, 'urn:nir:regione.piemonte:')">
                <xsl:value-of select="'consiglioRegionalePiemonte'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'supremaCorteDiCassazione'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:variable name="nomeSorgente">
        <xsl:choose>
            <xsl:when test="contains(//nir:urn/@valore, 'urn:nir:regione.piemonte:')">
                <xsl:value-of select="'Consiglio Regionale Piemonte'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'Suprema Corte Di Cassazione'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Parsing URN -->
    <xsl:variable name="urn_documento" select="substring-after(//nir:urn/@valore, 'urn:nir:')"/>
    <xsl:variable name="urn_emanante" select="substring-before($urn_documento, ':')"/>
    <!-- <xsl:variable name="urn_expression_date" select="substring-before(substring-after($urn_documento, '@'), ';')"/> -->
    <xsl:variable name="uri_work" select="u:convertiUrn(//nir:urn/@valore)"/>
    <xsl:variable name="urn_date" select="replace($uri_work, '.*?(\d{4}-\d{2}-\d{2}).*', '$1')"/>
    <xsl:variable name="urn_expression_date" select="$urn_date"/>
    <xsl:variable name="uri_expression" select="concat($uri_work, '/ita@', $urn_expression_date)"/>
    <xsl:variable name="uri_manifestation" select="concat($uri_expression, '/main.xml')"/>

    <!-- - - - - - - -->
    <!--- Traduzione -->
    <!-- - - - - - - -->

    <!-- Radice -->
    <xsl:template match="/">
        <xsl:if test="not(nir:NIR)">
            <xsl:text>
                Errore: l'input non e' un file NIR valido.
                Controllare che il namespace sia giusto e che vi sia
                il tag NIR.
            </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="nir:NIR"/>
    </xsl:template>

    <xsl:template match="nir:NIR">
        <akomaNtoso>
            <xsl:apply-templates/>
        </akomaNtoso>
    </xsl:template>

    <!-- Tipi documento -->
    <xsl:template match="nir:Legge | nir:LeggeCostituzionale | nir:DecretoLegge |
                         nir:DecretoLegislativo | nir:DecretoMinisteriale |
                         nir:RegioDecreto | nir:Dpr | nir:Dpcm | nir:LeggeRegionale |
                         nir:AttoDiAuthority | nir:DecretoMinisterialeNN |
                         nir:DprNN | nir:DpcmNN">
        <act>
            <xsl:call-template name="insertRootName"/>
            <xsl:apply-templates/>
            <xsl:call-template name="generaConclusioni" />
        </act>
    </xsl:template>


    <xsl:template match="nir:DocumentoNIR | nir:Comunicato">
        <doc>
            <xsl:call-template name="insertRootName"/>
            <xsl:apply-templates/>
            <xsl:call-template name="generaConclusioni" />
        </doc>
    </xsl:template>

    <!-- Insert @name attribute taking it from //nir:mTipodoc or //nir:NIR/* -->
    <xsl:template name="insertRootName">
        <xsl:attribute name="name">
            <xsl:choose>
                <xsl:when test="//nir:mTipodoc/@valore">
                    <!-- TODO: Normalizza -->
                    <!-- TODO: Forse conviene fare un controllo su un dizionario -->
                    <xsl:value-of select="//nir:mTipodoc/@valore" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="name(//nir:NIR/*)" />
                </xsl:otherwise>
            </xsl:choose>

        </xsl:attribute>
    </xsl:template>

    <xsl:template match="nir:DocArticolato | nir:SemiArticolato">
        <doc>
            <xsl:text>TODO: DocArticolato/SemiArticolato</xsl:text>
        </doc>
    </xsl:template>

    <!-- Meta -->
    <xsl:template match="nir:meta">
        <meta>
            <xsl:call-template name="generaIdentification"/>                   <!-- Identification -->
            <xsl:apply-templates select="nir:descrittori/nir:pubblicazione"/>  <!-- Publication -->
            <xsl:apply-templates select="nir:descrittori/nir:materie"/>        <!-- Classification -->
            <xsl:call-template name="generaLifecycle"/>                        <!-- Lyfecycle -->
            <!-- Workflow -->
            <xsl:call-template name="generaAnalysis"/>                         <!-- Analysis -->
            <!-- TemporalData -->
            <xsl:call-template name="generaReferences"/>                       <!-- References -->
            <xsl:apply-templates select="nir:redazionale"/>                    <!-- Notes -->
            <xsl:apply-templates select="//nir:meta/*[namespace-uri()!='http://www.normeinrete.it/nir/2.2/']|
                                         //nir:meta/nir:descrittori/*[namespace-uri()!='http://www.normeinrete.it/nir/2.2/']|
                                         nir:inquadramento |
                                         nir:lavoripreparatori |
                                         nir:altro |
                                         nir:proprietario"/>                   <!-- Proprietary -->
            <!-- Presentation -->
        </meta>
    </xsl:template>

    <xsl:template match="nir:inlinemeta">
        <!-- inlinemeta viene tolto dal body e spostato nel meta -->
    </xsl:template>

    <xsl:template name="generaIdentification">
        <identification source="#{$sorgente}">
            <FRBRWork>
                <FRBRthis value="{$uri_work}/main"/>
                <FRBRuri value="{$uri_work}"/>

                <!-- Alias a URN NIR -->
                <xsl:if test="//nir:urn/@valore">
                    <FRBRalias value="{//nir:urn/@valore}" name="urn:nir"/>
                </xsl:if>
                <!-- Aggiungi gli altri alias se presenti -->
                <xsl:for-each select="//nir:descrittori/nir:alias">
                    <!-- TODO: elimina name="nir" una volta che avremo la conversione -->
                    <FRBRalias name="nir">
                        <xsl:attribute name="value">
                            <xsl:call-template name="convertiURN">
                                <xsl:with-param name="urn" select="@valore"/>
                            </xsl:call-template>
                        </xsl:attribute>
                    </FRBRalias>
                </xsl:for-each>

                <!-- Indica la data -->
                <FRBRdate name="Enactment" date="{$urn_date}"/>

                <!-- Autore -->
                <FRBRauthor href="#emanante" as="#author"/>

                <!-- Nazione -->
                <FRBRcountry value="it"/>

                <!-- Indica tipo documento -->
                <xsl:if test="//nir:mTipodoc">
                    <FRBRname value="{//nir:mTipodoc/@valore}"/>
                </xsl:if>

                <!-- Indica se e' normativa -->
                <xsl:if test="//nir:infodoc/@normativa = 'si'">
                    <FRBRprescriptive value="true"/>
                </xsl:if>
                <xsl:if test="//nir:infodoc/@normativa = 'no'">
                    <FRBRprescriptive value="false"/>
                </xsl:if>


                <!-- Numero del documento -->
                <xsl:if test="//nir:mNumdoc">
                    <FRBRnumber value="{//nir:mNumdoc/@valore}"/>
                </xsl:if>
            </FRBRWork>

            <FRBRExpression>
                <FRBRthis value="{$uri_expression}/main"/>
                <FRBRuri value="{$uri_expression}"/>
                <xsl:if test="$urn_expression_date">
                    <FRBRdate date="{$urn_expression_date}" name=""/>
                </xsl:if>
                <xsl:if test="not($urn_expression_date)">
                    <FRBRdate date="{$urn_date}" name=""/>
                </xsl:if>
                <FRBRauthor href="#emanante" as="#author"/>
                <FRBRlanguage language="it"/>
            </FRBRExpression>

            <FRBRManifestation>
                <FRBRthis value="{$uri_manifestation}"/>
                <FRBRuri value="{$uri_manifestation}"/>

                <!-- Redazione -->
                <FRBRdate name="XMLConversion" date="{$today}"/>
                <!-- <xsl:if test="//nir:redazione[@contributo='redazione']">
                    <FRBRdate name="XMLConversion" date="substring-before(current-date(), '+')">
                        <xsl:attribute name="date">
                            <xsl:call-template name="convertiData">
                                <xsl:with-param name="date"
                                    select="//nir:redazione[@contributo='redazione']/@norm"/>
                            </xsl:call-template>
                        </xsl:attribute>
                    </FRBRdate>
                    <FRBRauthor href="#redazione" as="#editor"/>
                </xsl:if> -->
                <FRBRauthor href="#cirsfid"/>

                <xsl:if test="//nir:redazione[@contributo='editor']">
                    <preservation>
                        <cirsfid:software value="{//nir:redazione[@contributo='editor']/@nome}"/>
                        <cirsfid:affiliation value="{//nir:redazione[@contributo='editor']/@url}"/>
                    </preservation>
                </xsl:if>
            </FRBRManifestation>
        </identification>
    </xsl:template>

    <xsl:template name="generaLifecycle">
        <!-- Nella convertire del lifecycle gli id vengono mantenuti -->
        <lifecycle source="#{$sorgente}">
            <xsl:for-each select="//nir:ciclodivita/nir:eventi/nir:evento">
                <eventRef eId="{@id}" source="{@fonte}">
                    <xsl:attribute name="date">
                        <xsl:call-template name="convertiData">
                            <xsl:with-param name="date" select="@data"/>
                        </xsl:call-template>
                    </xsl:attribute>
                    <!-- Todo: il mappaggio va completato -->
                    <xsl:if test="@tipo = 'originale'">
                        <xsl:attribute name="type"><xsl:text>generation</xsl:text></xsl:attribute>
                    </xsl:if>
                    <xsl:if test="@tipo = 'modifica'">
                        <xsl:attribute name="type"><xsl:text>amendment</xsl:text></xsl:attribute>
                    </xsl:if>
                </eventRef>
            </xsl:for-each>

            <!-- Nel caso manchi nir:ciclodivita, inseriamo noi l'evento crazione -->
            <xsl:if test="not(//nir:ciclodivita/nir:eventi/nir:evento/@tipo='originale')">
                <eventRef eId="genEvnt" source="#genRef" type="generation">
                    <xsl:attribute name="date">
                        <xsl:if test="//nir:entratainvigore/@norm">
                            <xsl:call-template name="convertiData">
                                    <xsl:with-param name="date" select="//nir:entratainvigore/@norm"/>
                            </xsl:call-template>
                        </xsl:if>
                        <xsl:if test="not(//nir:entratainvigore/@norm)">
                            <xsl:value-of select="'0001-01-01'"/>
                        </xsl:if>
                    </xsl:attribute>
                </eventRef>
            </xsl:if>
        </lifecycle>
    </xsl:template>

    <xsl:template name="generaReferences">
        <references source="#{$sorgente}">
            <!-- Reference a documento originale -->
            <xsl:for-each select="//nir:ciclodivita//nir:originale">
                <original eId="{@id}" showAs="">
                    <xsl:attribute name="href">
                        <xsl:call-template name="convertiURN">
                            <xsl:with-param name="urn" select="@xlink:href"/>
                        </xsl:call-template>
                    </xsl:attribute>
                </original>
            </xsl:for-each>

            <!-- Nel caso manchi nir:ciclodivita, inseriamo noi l'evento crazione -->
            <xsl:if test="not(//nir:ciclodivita//nir:originale)">
                <original eId="genRef" showAs="" href="{$uri_work}"/>
            </xsl:if>

            <!-- Reference a modifiche attive -->
            <xsl:for-each select="//nir:ciclodivita//nir:attiva">
                <activeRef eId="{@id}" showAs="">
                    <xsl:attribute name="href">
                        <xsl:call-template name="convertiURN">
                            <xsl:with-param name="urn" select="@xlink:href"/>
                        </xsl:call-template>
                    </xsl:attribute>
                </activeRef>
            </xsl:for-each>

            <!-- Reference a modifiche passive -->
            <xsl:for-each select="//nir:ciclodivita//nir:passiva">
                <passiveRef eId="{@id}" showAs="">
                    <xsl:attribute name="href">
                        <xsl:call-template name="convertiURN">
                            <xsl:with-param name="urn" select="@xlink:href"/>
                        </xsl:call-template>
                    </xsl:attribute>
                </passiveRef>
            </xsl:for-each>

            <!-- Reference a sorgente documento -->
            <TLCOrganization eId="{$sorgente}" href="/ontology/organizations/it/{$sorgente}" showAs="{$nomeSorgente}"/>

            <!-- Reference all'emanante -->
            <xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'"/>
            <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
            <xsl:variable name="amanante">
                <xsl:if test="//nir:mEmanante">
                    <xsl:value-of select="//nir:mEmanante/@valore"/>
                </xsl:if>
                <xsl:if test="not(//nir:mEmanante)">
                    <xsl:value-of select="$urn_emanante"/>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="idEmanante" select="concat(
                translate(substring($amanante, 1, 1), $smallcase, $uppercase),
                translate(substring($amanante, 2), ' ', '_')
            )"/>
            <TLCOrganization eId="emanante" href="/ontology/organizations/it/{$idEmanante}" showAs="{$amanante}"/>

            <!-- Redazione -->
            <xsl:if test="//nir:redazione[@contributo='redazione']">
                <TLCOrganization eId="redazione" href="{//nir:redazione[@contributo='redazione']/@url}"
                    showAs="{//nir:redazione[@contributo='redazione']/@nome}"/>
            </xsl:if>

            <!-- Allegati -->
            <xsl:for-each select="//nir:haallegato">
                <hasAttachment href="{@xlink:href}" showAs=""/>
            </xsl:for-each>
            <xsl:for-each select="//nir:allegatodi">
                <attachmentOf href="{@xlink:href}" showAs=""/>
            </xsl:for-each>

            <!-- Giurisprudenza -->
            <xsl:for-each select="//nir:giurisprudenza">
                <jurisprudence href="{@xlink:href}" showAs=""/>
            </xsl:for-each>

            <!-- Firme -->
            <xsl:for-each select="//nir:firma">
                <xsl:if test="not(@tipo=preceding::nir:firma/@tipo)">
                    <TLCConcept eId="{@tipo}" href="/ontology/concepts/it/{@tipo}" showAs="{@tipo}"/>
                </xsl:if>
            </xsl:for-each>

            <!-- Cirsfid -->
            <TLCOrganization eId="cirsfid" href="http://www.cirsfid.unibo.it/" showAs="CIRSFID"/>

            <!-- Riferimenti esterni -->

            <xsl:for-each select="//nir:rif">
                <xsl:variable name="href" select="@xlink:href"/>
                <xsl:variable name="n" select="count(./preceding::nir:rif)+1"/>
                <xsl:if test="not(./preceding::nir:rif[@xlink:href = $href])">
                    <TLCReference eId="rif{$n}" showAs="NIR" name="urn:nir" href="{$href}"/>
                </xsl:if>
            </xsl:for-each>

            <!-- Todo: aggiusta anche questo..
            <xsl:for-each select="//nir:irif">
                <xsl:variable name="href" select="@xlink:href"/>
                <xsl:variable name="start" select="count(./preceding::nir:irif[@xlink:href != $href])+1"/>
                <xsl:variable name="finoa" select="@finoa"/>
                <xsl:variable name="end" select="count(./preceding::nir:irif[@finoa != $finoa])+1"/>
                <xsl:if test="not(./preceding::nir:irif[@xlink:href = $href])">
                    <TLCReference eId="irif_s{$start}" showAs="">
                        <xsl:attribute name="href">
                            <xsl:call-template name="convertiURN">
                                <xsl:with-param name="urn" select="@xlink:href"/>
                            </xsl:call-template>
                        </xsl:attribute>
                    </TLCReference>
                </xsl:if>
                <xsl:if test="not(./preceding::nir:irif[@finoa = $finoa])">
                    <TLCReference eId="irif_e{$end}" showAs="">
                        <xsl:attribute name="href">
                            <xsl:call-template name="convertiURN">
                                <xsl:with-param name="urn" select="@finoa"/>
                            </xsl:call-template>
                        </xsl:attribute>
                    </TLCReference>
                </xsl:if>
            </xsl:for-each> -->
        </references>
    </xsl:template>

    <xsl:template match="nir:descrittori/nir:pubblicazione">
        <publication showAs="">
            <xsl:if test="@norm">
                <xsl:attribute name="date">
                    <xsl:call-template name="convertiData">
                        <xsl:with-param name="date" select="@norm"/>
                    </xsl:call-template>
                </xsl:attribute>
            </xsl:if>
            <xsl:attribute name="name">
                <xsl:value-of select="@tipo"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@tipo='GU'">
                    <xsl:attribute name="showAs">Gazzetta Ufficiale</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="showAs">
                        <xsl:value-of select="@tipo"/>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="@num">
                <xsl:attribute name="number">
                    <xsl:value-of select="@num"/>
                </xsl:attribute>
            </xsl:if>
        </publication>
    </xsl:template>

    <xsl:template match="nir:descrittori/nir:materie">
        <classification source="#{$sorgente}">
            <xsl:for-each select="nir:materia">
                <keyword dictionary="#tesauroCassazione" showAs="{@valore}" value="{@valore}"/>
            </xsl:for-each>
        </classification>
    </xsl:template>

    <xsl:template match="nir:inquadramento">
        <xsl:if test="nir:oggetto">
            <proprietary source="#{$sorgente}">
                <cirsfid:oggetto>
                    <xsl:for-each select="nir:oggetto/*">
                        <xsl:element name="cirsfid:{name()}">
                            <xsl:attribute name="valore">
                                <xsl:value-of select="@valore"/>
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:for-each>
                </cirsfid:oggetto>
            </proprietary>
        </xsl:if>
        <xsl:if test="nir:proponenti">
            <proprietary source="#{$sorgente}">
                <cirsfid:proponenti>
                    <xsl:for-each select="nir:proponenti/*">
                        <xsl:element name="cirsfid:{name()}">
                            <xsl:attribute name="valore">
                                <xsl:value-of select="@valore"/>
                            </xsl:attribute>
                        </xsl:element>
                    </xsl:for-each>
                </cirsfid:proponenti>
            </proprietary>
        </xsl:if>
    </xsl:template>

    <xsl:template match="nir:lavoripreparatori |
                         nir:altro |
                         nir:proprietario |
                         nir:meta/nir:descrittori/*[namespace-uri()!='http://www.normeinrete.it/nir/2.2/']">
        <proprietary>
            <xsl:attribute name="source">
                <xsl:value-of select="$sorgente"/>
            </xsl:attribute>
            <xsl:apply-templates select="." mode="copyEverything"/>
        </proprietary>
    </xsl:template>

    <xsl:template match="nir:redazionale">
        <xsl:if test="nir:nota">
            <notes>
                <xsl:attribute name="source">
                    <xsl:value-of select="$sorgente"/>
                </xsl:attribute>
                <xsl:apply-templates select="nir:nota"/>
            </notes>
        </xsl:if>
        <xsl:if test="nir:altro">
            <proprietary>
                <xsl:attribute name="source">
                    <xsl:value-of select="$sorgente"/>
                </xsl:attribute>
                <xsl:apply-templates select="nir:altro/node()" mode="copyEverything"/>
            </proprietary>
        </xsl:if>
    </xsl:template>


    <xsl:template match="nir:nota">
        <note eId="{@id}">
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </note>
    </xsl:template>

    <xsl:template match="nir:risoluzioni">
        <!-- <xsl:for-each select="nir:risoluzione"> -->
            <!-- TODO -->
        <!-- </xsl:for-each> -->
    </xsl:template>

    <!-- - - - - - - - -->
    <!-- Disposizioni  -->
    <!-- - - - - - - - -->
    <xsl:template name="generaAnalysis">
        <analysis source="#{$sorgente}">
            <xsl:if test="//nir:modificheattive">
                <activeModifications>
                    <!-- Todo: genera id? -->
                    <xsl:apply-templates select="//nir:modificheattive"/>
                </activeModifications>
            </xsl:if>
            <xsl:if test="//nir:modifichepassive">
                <passiveModifications>
                    <!-- Todo: genera id? -->
                    <xsl:apply-templates select="//nir:modifichepassive"/>
                </passiveModifications>
            </xsl:if>
            <xsl:apply-templates select="//nir:regole"/>
        </analysis>
    </xsl:template>

    <xsl:template match="dsp:norma">
        <destination>
            <xsl:choose>
                <xsl:when test="dsp:subarg/cirsfid:sub">
                    <xsl:attribute name="href">
                        <xsl:call-template name="convertiURN">
                            <xsl:with-param name="urn" select="dsp:subarg/cirsfid:sub[1]/@xlink:href"/>
                        </xsl:call-template>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="dsp:pos">
                    <xsl:attribute name="href">
                        <xsl:call-template name="convertiURN">
                            <xsl:with-param name="urn" select="dsp:pos/@xlink:href"/>
                        </xsl:call-template>
                    </xsl:attribute>
                    <xsl:attribute name="pos">
                        <xsl:text>unspecified</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="href">
                        <xsl:call-template name="convertiURN">
                            <xsl:with-param name="urn" select="@xlink:href"/>
                        </xsl:call-template>
                    </xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
        </destination>
    </xsl:template>

    <xsl:template match="dsp:termine      | dsp:condizione    | dsp:posizione   |

                         dsp:visto        | dsp:sentito       | dsp:considerato |
                         dsp:suproposta   | dsp:basegiuridica | dsp:proposta    |
                         dsp:parere       | dsp:richiesta     | dsp:procedura   |
                         dsp:considerando | dsp:motivazione   | dsp:finalita    |
                         dsp:finanziaria  | dsp:ambito        | dsp:metaregola  |
                         dsp:definitoria  | dsp:istitutiva    |dsp:organizzativa|
                         dsp:status       | dsp:competenza    | dsp:delega      |
                         dsp:revoca       | dsp:diritto       | dsp:dovere      |
                         dsp:pretesa      | dsp:obbligo       | dsp:divieto     |
                         dsp:permesso     | dsp:procedimento  | dsp:sanzione    |
                         dsp:riparazione  | dsp:informazione  | dsp:regola      |

                         dsp:soggetto     | dsp:effetto       | dsp:partizione  |
                         dsp:tiporegola   | dsp:fatto         | dsp:organo      |
                         dsp:fine         | dsp:destinatario  | dsp:territorio  |
                         dsp:attivita     | dsp:definiendum   | dsp:definiens   |
                         dsp:qualifica    | dsp:delegante     | dsp:controparte |
                         dsp:azione       | dsp:pena          |

                         nir:regole">
        <!-- <proprietary>
            <xsl:apply-templates select="." mode="copyEverything"/>
        </proprietary> -->
    </xsl:template>

    <xsl:template match="nir:modificheattive/*/dsp:pos | nir:modifichepassive/*/dsp:pos">
        <xsl:variable name="oId" select="substring-after(@xlink:href, '#')"/>
        <source>
            <xsl:attribute name="href">#<xsl:apply-templates mode="genera_id" select="//node()[@id = $oId]"/></xsl:attribute>
            <xsl:apply-templates />
        </source>
    </xsl:template>

    <xsl:template match="dsp:abrogazione">
        <textualMod type="repeal">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </textualMod>
    </xsl:template>

    <xsl:template match="dsp:sostituzione">
        <textualMod type="substitution">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </textualMod>
    </xsl:template>

    <xsl:template match="dsp:integrazione">
        <textualMod type="insertion">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </textualMod>
    </xsl:template>

    <xsl:template match="dsp:ricollocazione">
        <textualMod type="renumbering">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </textualMod>
    </xsl:template>

    <xsl:template match="dsp:intautentica">
        <meaningMod type="authenticInterpretation">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </meaningMod>
    </xsl:template>

    <xsl:template match="dsp:variazione">
        <meaningMod type="variation">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </meaningMod>
    </xsl:template>

    <xsl:template match="dsp:modtermini">
        <meaningMod type="termModification">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </meaningMod>
    </xsl:template>

    <xsl:template match="dsp:vigenza">
        <forceMod type="entryIntoForce">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </forceMod>
    </xsl:template>

    <xsl:template match="dsp:annullamento">
        <forceMod type="uncostitutionality">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </forceMod>
    </xsl:template>

    <xsl:template match="dsp:proroga">
        <efficacyMod type="prorogationOfEfficacy">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </efficacyMod>
    </xsl:template>

    <xsl:template match="dsp:posticipo">
        <efficacyMod type="postponementOfEfficacy">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </efficacyMod>
    </xsl:template>

    <xsl:template match="dsp:reviviscenza">
    </xsl:template>

    <xsl:template match="dsp:retroattivita">
        <efficacyMod type="retroactivity">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </efficacyMod>
    </xsl:template>

    <xsl:template match="dsp:ultrattivita">
        <efficacyMod type="extraEfficacy">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </efficacyMod>
    </xsl:template>

    <xsl:template match="dsp:inapplicazione">
        <efficacyMod type="inapplication">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </efficacyMod>
    </xsl:template>

    <xsl:template match="dsp:deroga">
        <scopeMod type="exceptionOfScope" incomplete="true">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </scopeMod>
    </xsl:template>

    <xsl:template match="dsp:estensione">
        <scopeMod type="extensionOfScope" incomplete="true">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </scopeMod>
    </xsl:template>

    <xsl:template match="dsp:recepisce">
        <legalSystemMod type="application">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:attua">
        <legalSystemMod type="implementation">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:ratifica">
        <legalSystemMod type="ratification">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:attuadelega">
        <legalSystemMod type="legislativeDelegation">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:attuadelegifica">
        <legalSystemMod type="deregulation">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:converte">
        <legalSystemMod type="conversion">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:reitera">
        <legalSystemMod type="reiteration">
            <xsl:apply-templates select="./dsp:*[not(name() = 'dsp:novella') and not(name() = 'dsp:novellando')]"/>
            <xsl:apply-templates select="dsp:novellando"/>
            <xsl:apply-templates select="dsp:novella"/>
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:modifica">
    </xsl:template>

    <xsl:template match="dsp:decadimento">
        <legalSystemMod type="expiration">
            <xsl:apply-templates />
        </legalSystemMod>
    </xsl:template>

    <xsl:template match="dsp:novella">
        <xsl:variable name="oId" select="substring-after(dsp:pos/@xlink:href, '#')"/>
        <new>
            <xsl:attribute name="href">
                <xsl:apply-templates mode="genera_id" select="//node()[@id = $oId]"/>
            </xsl:attribute>
            <xsl:apply-templates />
        </new>
    </xsl:template>

    <xsl:template match="dsp:novellando">
        <xsl:variable name="oId" select="substring-after(dsp:pos/@xlink:href, '#')"/>
        <old>
            <xsl:attribute name="href">
                <xsl:apply-templates mode="genera_id" select="//node()[@id = $oId]"/>
            </xsl:attribute>
            <xsl:apply-templates />
        </old>
    </xsl:template>

    <!-- - - - - - - -->
    <!--  Contenuto  -->
    <!-- - - - - - - -->
    <xsl:template match="nir:intestazione">
        <preface>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </preface>
    </xsl:template>

    <xsl:template match="nir:intestazione//nir:tipoDoc">
        <docType>
            <xsl:apply-templates/>
        </docType>
    </xsl:template>

    <xsl:template match="nir:intestazione//nir:numDoc">
        <docNumber>
            <xsl:apply-templates/>
        </docNumber>
    </xsl:template>

    <xsl:template match="nir:intestazione//nir:titoloDoc">
        <docTitle>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
            <xsl:if test=". = //nir:titoloDoc[1]">
                <xsl:for-each select="//nir:avvertenza">
                    <authorialNote>
                        <xsl:apply-templates/>
                    </authorialNote>
                </xsl:for-each>
            </xsl:if>
        </docTitle>
    </xsl:template>

    <xsl:template match="nir:intestazione//nir:emanante">
        <docAuthority>
            <xsl:apply-templates/>
        </docAuthority>
    </xsl:template>

    <xsl:template match="nir:intestazione//nir:dataDoc">
        <docDate>
            <xsl:apply-templates select="node()|@*"/>
        </docDate>
    </xsl:template>

    <xsl:template match="nir:intestazione//nir:dataDoc/@norm">
        <xsl:attribute name="date">
            <xsl:call-template name="convertiData">
                <xsl:with-param name="date" select="."/>
            </xsl:call-template>
        </xsl:attribute>
    </xsl:template>

    <!-- Preambolo -->
    <xsl:template match="nir:formulainiziale">
        <preamble>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </preamble>
    </xsl:template>

    <xsl:template match="nir:preambolo">
        <container name="preambolo_nir">
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </container>
    </xsl:template>

    <!-- Articolato -->
    <xsl:template match="nir:articolato">
        <xsl:choose>
            <xsl:when test="//nir:DocumentoNIR  | //nir:Comunicato |
                            //nir:DocArticolato | //nir:SemiArticolato">
                <mainBody>
                    <xsl:apply-templates/>
                </mainBody>
            </xsl:when>
            <xsl:otherwise>
                <body>
                    <xsl:apply-templates/>
                </body>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Conclusione -->
    <xsl:template match="nir:formulafinale | nir:conclusione">
        <!-- Vengono gia' gestisti in generaConclusioni -->
    </xsl:template>

    <xsl:template name="generaConclusioni">
        <xsl:if test="//nir:conclusione | //nir:formulafinale">
            <conclusions>
                <xsl:apply-templates select="//nir:conclusione | //nir:formulafinale" mode="conclusioni"/>
            </conclusions>
        </xsl:if>
    </xsl:template>

    <xsl:template match="nir:formulafinale" mode="conclusioni">
        <container name="formulafinale" eId="comp1-sgn1" class="right">
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </container>
    </xsl:template>

    <xsl:template match="nir:conclusione" mode="conclusioni">
        <xsl:apply-templates select="." mode="aggiusta_pattern"/>
    </xsl:template>

    <!-- Conversione elementi interni e gerarchia -->
    <xsl:template match="nir:decorazione/nir:rango">
        <decoration>
            <xsl:copy-of select="@tipo"/>
        </decoration>
    </xsl:template>

    <xsl:template match="nir:libro">
        <book>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </book>
    </xsl:template>

    <xsl:template match="nir:parte">
        <part>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </part>
    </xsl:template>

    <xsl:template match="nir:titolo">
        <title>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </title>
    </xsl:template>

    <xsl:template match="nir:capo">
        <chapter>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </chapter>
    </xsl:template>

    <xsl:template match="nir:sezione">
        <section>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </section>
    </xsl:template>

    <xsl:template match="nir:paragrafo">
        <paragraph>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="node()"/>
        </paragraph>
    </xsl:template>

    <xsl:template match="nir:articolo">
        <article>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="node()"/>
        </article>
    </xsl:template>

    <xsl:template match="nir:rubrica">
        <!-- Come scelgo se mettere subheading? -->
        <heading>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </heading>
    </xsl:template>

    <xsl:template match="nir:num">
        <xsl:if test=".//node()">
            <num>
                <xsl:apply-templates/>
            </num>
        </xsl:if>
    </xsl:template>

    <xsl:template match="nir:comma">
        <paragraph>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="node()"/>
        </paragraph>
    </xsl:template>

    <xsl:template match="nir:el[name(./preceding-sibling::node()[1]) != 'el'] |
                         nir:en[name(./preceding-sibling::node()[1]) != 'en'] |
                         nir:ep[name(./preceding-sibling::node()[1]) != 'ep']">
        <list>
            <xsl:variable name="current" select="."/>
            <xsl:for-each select="$current | following-sibling::node()[name() = name($current)]">
                <point>
                    <xsl:apply-templates select="." mode="genera_eId"/>
                    <xsl:apply-templates select="node()"/>
                </point>
            </xsl:for-each>
        </list>
    </xsl:template>

    <xsl:template match="nir:el | nir:en | nir:ep">
    </xsl:template>

    <xsl:template match="nir:corpo">
        <content>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </content>
    </xsl:template>

    <!-- Workaround per bug in file Piemonte, dove si ha un nir:corpo invece che
    nir:alinea in alcune liste -->
    <xsl:template match="nir:corpo[following-sibling::*[1][self::nir:en or self::nir:el or self::nir:ep]]">
        <intro>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </intro>
    </xsl:template>

    <xsl:template match="nir:alinea">
        <intro>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </intro>
    </xsl:template>

    <xsl:template match="nir:coda">
        <wrapUp>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </wrapUp>
    </xsl:template>

    <xsl:template match="nir:dataeluogo">
        <date>
            <xsl:attribute name="date">
                <xsl:call-template name="convertiData">
                    <xsl:with-param name="date" select="@norm"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </date>
    </xsl:template>

    <xsl:template match="nir:firma">
        <signature refersTo="#{@tipo}">
            <xsl:apply-templates select="node()"/>
        </signature>
    </xsl:template>

    <xsl:template match="nir:annessi">
        <!-- TODO: qui c'e' molto da fare
        <attachments>
            <xsl:apply-templates/>
        </attachments>
        -->
    </xsl:template>

    <xsl:template match="nir:elencoAnnessi">
        <!-- Non serve in Akomantoso -->
    </xsl:template>

    <xsl:template match="nir:annesso">
        <!-- TODO: qui c'e' molto da fare
        <attachments>
            <xsl:apply-templates/>
        </attachments>
        -->
    </xsl:template>

    <xsl:template match="nir:rif">
        <xsl:variable name="href" select="@xlink:href"/>
        <xsl:variable name="firstSimilar" select="//nir:rif[@xlink:href=$href][1]"/>
        <xsl:variable name="n" select="count($firstSimilar/preceding::nir:rif)+1"/>
        <ref refersTo="#rif{$n}">
            <xsl:attribute name="href">
                <xsl:call-template name="convertiURN">
                    <xsl:with-param name="urn" select="@xlink:href"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </ref>
    </xsl:template>

    <xsl:template match="nir:mrif">
        <mref>
            <xsl:apply-templates select="node()"/>
        </mref>
    </xsl:template>

    <xsl:template match="nir:irif">
        <rref>
            <xsl:attribute name="from">
                <xsl:call-template name="convertiURN">
                    <xsl:with-param name="urn" select="@xlink:href"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="upTo">
                <xsl:call-template name="convertiURN">
                    <xsl:with-param name="urn" select="@finoa"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates/>
        </rref>
    </xsl:template>

    <xsl:template match="nir:mod">
        <mod>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </mod>
    </xsl:template>

    <xsl:template match="nir:mmod">
        <mmod>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </mmod>
    </xsl:template>

    <xsl:template match="nir:imod">
        <rmod>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:attribute name="from">
                <xsl:call-template name="convertiURN">
                    <xsl:with-param name="urn" select="@xlink:href"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="upTo">
                <xsl:call-template name="convertiURN">
                    <xsl:with-param name="urn" select="@finoa"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates/>
        </rmod>
    </xsl:template>

    <xsl:template match="nir:virgolette">
        <!-- Todo: pensa e riabilita quotedText -->
        <!-- <xsl:choose> -->
            <!-- <xsl:when test="@tipo = 'struttura'"> -->
                <quotedStructure>
                    <xsl:variable name="children" select="node()[position()!=1]"/>
                    <xsl:variable name="content">
                        <nir:virgolette><xsl:copy-of select="$children"/></nir:virgolette>
                    </xsl:variable>
                    <xsl:apply-templates select="." mode="genera_eId"/>
                    <xsl:apply-templates select="$content" mode="aggiusta_pattern"/>
                </quotedStructure>
            <!-- </xsl:when> -->
            <!-- <xsl:otherwise> -->
                <!-- <quotedText> -->
                    <!-- <xsl:apply-templates select="." mode="genera_eId"/> -->
                    <!-- <xsl:apply-templates select="node()"/> -->
                <!-- </quotedText> -->
            <!-- </xsl:otherwise> -->
        <!-- </xsl:choose> -->
    </xsl:template>

    <xsl:template match="nir:virgolette[@tipo = 'struttura']/text()[string-length(.) &lt; 5][position() = 1]">
        <xsl:attribute name="startQuote">
            <xsl:value-of select="."/>
        </xsl:attribute>
        <xsl:attribute name="endQuote">
            <xsl:value-of select="following-sibling::text()[last()]"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="nir:def">
        <def>
            <xsl:apply-templates/>
        </def>
    </xsl:template>

    <xsl:template match="nir:atto">
        <proprietary source="#{$sorgente}">
            <cirsfid:atto>
                <xsl:apply-templates/>
            </cirsfid:atto>
        </proprietary>
    </xsl:template>

    <xsl:template match="nir:data">
        <date>
            <xsl:attribute name="date">
                <xsl:call-template name="convertiData">
                    <xsl:with-param name="date" select="@norm"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates/>
        </date>
    </xsl:template>

    <xsl:template match="nir:soggetto">
        <person>
            <xsl:apply-templates/>
        </person>
    </xsl:template>

    <xsl:template match="nir:ente">
        <!-- Come uso @codice? -->
        <organization>
            <xsl:apply-templates/>
        </organization>
    </xsl:template>

    <xsl:template match="nir:luogo">
        <!-- Come uso @dove? -->
        <location>
            <xsl:apply-templates/>
        </location>
    </xsl:template>

    <xsl:template match="nir:importo">
        <quantity>
            <xsl:apply-templates/>
        </quantity>
    </xsl:template>

    <xsl:template match="nir:ndr">
        <noteRef href="{@num}">
            <xsl:apply-templates select="node()"/>
        </noteRef>
    </xsl:template>

    <xsl:template match="nir:vuoto">
        <omissis>
            <xsl:apply-templates/>
        </omissis>
    </xsl:template>

    <xsl:template match="nir:inlinea">
        <inline name="nir:inlinea">
            <xsl:apply-templates/>
        </inline>
    </xsl:template>

    <xsl:template match="nir:blocco">
        <block>
            <xsl:apply-templates/>
        </block>
    </xsl:template>

    <xsl:template match="nir:contenitore">
        <container name="{@nome}">
            <xsl:apply-templates/>
        </container>
    </xsl:template>

    <xsl:template match="nir:DocumentoNIR/nir:contenitore">
        <mainBody>
            <container name="{@nome}">
                <xsl:apply-templates/>
            </container>
        </mainBody>
    </xsl:template>

    <xsl:template match="nir:partizione">
    </xsl:template>

    <xsl:template match="nir:lista">
        <blockList>
            <xsl:apply-templates select="." mode="genera_eId"/>
            <xsl:apply-templates/>
        </blockList>
    </xsl:template>

    <xsl:template match="nir:gerarchia">
        <mainBody>
            <xsl:apply-templates/>
        </mainBody>
    </xsl:template>

    <xsl:template match="nir:l1 | nir:l2 | nir:l3 | nir:l4 | nir:l5 | nir:l6 | nir:l7 | nir:l8 | nir:l9">
        <hcontainer>
            <xsl:apply-templates/>
        </hcontainer>
    </xsl:template>

    <xsl:template match="nir:tit">
    </xsl:template>

    <!-- - - - - - - - - - -->
    <!-- Conversione HTML  -->
    <!-- - - - - - - - - - -->
    <xsl:template match="h:*">
        <!-- Gli elementi HTML restano uguali, cambia solo il namespace -->
        <xsl:element name="{local-name()}">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="h:a">
        <a href="{@xlink:href}">
            <xsl:if test="@h:title">
                <xsl:attribute name="title">
                    <xsl:value-of select="@h:title"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates />
        </a>
    </xsl:template>

    <xsl:template match="h:br">
        <eol>
            <xsl:apply-templates />
        </eol>
    </xsl:template>

    <xsl:template match="h:tbody">
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="h:td">
        <td>
            <xsl:apply-templates select="." mode="aggiusta_pattern"/>
        </td>
    </xsl:template>

    <xsl:template match="h:p[text() = 'omissis']">
        <p>
            <omissis>
                <xsl:apply-templates/>
            </omissis>
        </p>
    </xsl:template>

    <!-- - - - - - - - - - - -->
    <!-- Funzioni ausiliari  -->
    <!-- - - - - - - - - - - -->
    <xsl:template match="*" mode="aggiusta_pattern">
        <xsl:variable name="blocks" select="'|p|table|en|el|ep|articolo|libro|parte|titolo|capo|sezione|paragrafo|rubrica|preambolo|'"/>
        <xsl:for-each select="node()">
            <xsl:variable name="prev" select="preceding-sibling::node()[1]"/>
            <xsl:choose>
                <xsl:when test="contains($blocks, concat('|', local-name(), '|'))">
                    <xsl:apply-templates select="."/>
                </xsl:when>
                <xsl:when test="not($prev) or
                                $prev[contains($blocks, concat('|', local-name(), '|'))]">
                    <xsl:variable name="nextBreak" select="following-sibling::node()
                        [contains($blocks, concat('|', local-name(), '|'))]
                        [1]"/>
                    <xsl:variable name="nextBreakPos" select="count($nextBreak/preceding-sibling::node()) + 1"/>
                    <xsl:variable name="myPos" select="position()"/>
                    <p>
                        <xsl:if test="$nextBreakPos = 1">
                            <xsl:apply-templates select="(.|following-sibling::node())"/>
                        </xsl:if>
                        <xsl:if test="$nextBreakPos > 1">
                            <xsl:apply-templates select="(.|following-sibling::node())
                                [(position() + $myPos -1)&lt;$nextBreakPos]"/>
                        </xsl:if>

                    </p>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="*" mode="genera_eId">
        <xsl:attribute name="eId">
            <xsl:apply-templates select="." mode="genera_id"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="*" mode="genera_id">
        <xsl:for-each select="./ancestor-or-self::node()
            [(name() = 'virgolette') or
             (name() = 'articolo') or
             (name() = 'capo') or
             (name() = 'alinea') or
             (name() = 'list') or
             (name() = 'paragrafo' or name() = 'comma') or
             (name() = 'sezione') or
             (name() = 'rubrica') or
             (name() = 'intestazione') or
             (name() = 'preambolo') or
             (name() = 'formulainiziale') or
             (name() = 'libro') or
             (name() = 'parte') or
             (name() = 'titolo') or
             (name() = 'corpo') or
             (name() = 'mod') or
             (name() = 'mmod') or
             (name() = 'preambolo') or
             (name() = 'titoloDoc') or
             (name() = 'el' or name() = 'en' or name() = 'ep') or
             (name() = 'imod')]">

            <xsl:choose>
                <xsl:when test="name() = 'virgolette'">
                    <xsl:text>qstr</xsl:text>
                </xsl:when>
                <!-- Todo: riabilita quotedText -->
                <!-- <xsl:when test="name() = 'virgolette' and @tipo = 'struttura'"> -->
                    <!-- <xsl:text>qstr</xsl:text> -->
                <!-- </xsl:when> -->
                <!-- <xsl:when test="name() = 'virgolette' and not(@tipo = 'struttura')"> -->
                    <!-- <xsl:text>qtext</xsl:text> -->
                <!-- </xsl:when> -->
                <xsl:when test="name() = 'articolo'">
                    <xsl:text>art</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'capo'">
                    <xsl:text>chp</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'alinea'">
                    <xsl:text>intro</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'list'">
                    <xsl:text>list</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'paragrafo' or name() = 'comma'">
                    <xsl:text>para</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'sezione'">
                    <xsl:text>Sec</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'rubrica'">
                    <xsl:text>hdg</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'intestazione'">
                    <xsl:text>preface</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'formulainiziale'">
                    <xsl:text>preamble</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'libro'">
                    <xsl:text>book</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'parte'">
                    <xsl:text>part</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'titolo'">
                    <xsl:text>title</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'corpo'">
                    <xsl:text>content</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'mod'">
                    <xsl:text>mod</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'mmod'">
                    <xsl:text>mmod</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'imod'">
                    <xsl:text>rmod</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'titoloDoc'">
                    <xsl:text>docTitle</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'preambolo'">
                    <xsl:text>preambolonir</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'el' or name() = 'en' or name() = 'ep'">
                    <xsl:text>point</xsl:text>
                </xsl:when>
                <xsl:otherwise><xsl:text>error</xsl:text></xsl:otherwise>
            </xsl:choose>

            <xsl:text>_</xsl:text>
            <xsl:variable name="name" select="name()"/>
            <xsl:value-of select="count(. | ./preceding-sibling::node()[name() = $name])"/>

            <xsl:if test="position() != last()">
                <xsl:text>__</xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="convertiData">
        <xsl:param name="date"/>
        <xsl:variable name="year" select="substring($date, 1, 4)"/>
        <xsl:variable name="month" select="substring($date, 5, 2)"/>
        <xsl:variable name="day" select="substring($date, 7, 2)"/>
        <xsl:value-of select="concat($year, '-', $month, '-', $day)"/>
    </xsl:template>

    <xsl:template name="convertiURN">
        <!--
            nir       urn:nir:autorita:provvedimento:estremi[:annesso..][@versione][*comunicato..][$manifestazione][#id]
                      urn:nir:presidenza.consiglio.ministri:decreto:2009-12-18;206
            akn       /akn/it/act/provvedimento/autorita/data/num_title/ita@
            example   urn:nir:stato:decreto.legislativo:1992-04-30;285#art118-com6
        -->
        <xsl:param name="urn"/>
        <xsl:variable name="i1" select="substring-after($urn, 'urn:nir:')"/>
        <!-- Eg. autorita:provvedimento:estremi[:annesso..][@versione][*comunicato..][$manifestazione][#id] -->
        <xsl:variable name="autorita" select="substring-before($i1, ':')"/>
        <!-- Eg. autorita -->
        <xsl:variable name="i2" select="substring-after($i1, ':')"/>
        <!-- Eg. provvedimento:estremi[:annesso..][@versione][*comunicato..][$manifestazione][#id] -->
        <xsl:variable name="provvedimento" select="substring-before($i2, ':')"/>
        <!-- Eg. provvedimento -->
        <xsl:variable name="i3" select="substring-after($i2, ':')"/>
        <!-- Eg. estremi[:annesso..][@versione][*comunicato..][$manifestazione][#id] -->
        <xsl:variable name="n1" select="substring-before($i3, ':')"/>
        <xsl:variable name="n2" select="substring-before($i3, '@')"/>
        <xsl:variable name="n3" select="substring-before($i3, '*')"/>
        <xsl:variable name="n4" select="substring-before($i3, '#')"/>
        <xsl:variable name="estremi">
            <xsl:choose>
                <xsl:when test='$n1'><xsl:value-of select="$n1"/></xsl:when>
                <xsl:when test='$n2'><xsl:value-of select="$n2"/></xsl:when>
                <xsl:when test='$n3'><xsl:value-of select="$n3"/></xsl:when>
                <xsl:when test='$n4'><xsl:value-of select="$n4"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$i3"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Eg. 2010-03-08;nir-s2102504 -->
        <xsl:variable name="data" select="substring-before($estremi, ';')"/>
        <xsl:variable name="num" select="substring-after($estremi, ';')"/>

        <xsl:variable name="id" select="substring-after($urn, '#')"/>

        <!-- Output -->
        <xsl:if test="starts-with($urn, 'urn:nir')">
            <xsl:text>/akn/it/</xsl:text>
            <xsl:choose>
                <xsl:when test="$provvedimento = 'decreto.legislativo'"><xsl:text>act</xsl:text></xsl:when>
                <xsl:when test="$provvedimento = 'decreto'"><xsl:text>act</xsl:text></xsl:when>
                <xsl:otherwise><xsl:text>act</xsl:text></xsl:otherwise>
            </xsl:choose>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$provvedimento"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$autorita"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$data"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="$num"/>

            <!-- Questo serve solo in caso di manifestation
                <xsl:value-of select="'/ita'"/> -->
        </xsl:if>
        <xsl:if test="$id">
            <!-- Se siamo in fondo ad un uri dobbiamo mettere la manifestation -->
            <xsl:if test="starts-with($urn, 'urn:nir')">
                <xsl:text>/ita/</xsl:text>
                <xsl:value-of select="$data"/>
            </xsl:if>
            <xsl:text>#</xsl:text>
            <xsl:if test="//node()[@id = $id]">
                <xsl:apply-templates mode="genera_id" select="//node()[@id = $id]"/>
            </xsl:if>
            <xsl:if test="not(//node()[@id = $id])">
                <xsl:value-of select="$id"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>

    <xsl:function name="u:convertiUrn">
        <xsl:param name="urn"/>
        <!-- urn:nir:stato:legge:2000-09-29;300*entrata.vigore;2001-08-07 -->
        <!-- /akn/it/doc/entrata_vigore/stato/2001-08-07/legge_2000-09-29_300 -->

        <!-- Macroparti -->
        <xsl:variable name="principale" select="u:primoMacroblocco($urn)"/>
        <xsl:variable name="comunicato" select="u:cercaMacroblocco($urn, '*')"/>

        <xsl:choose>
            <xsl:when test="$comunicato!=''">
                <xsl:value-of select="u:convertiComunicato($urn)"/>
            </xsl:when>

            <xsl:otherwise>
                <xsl:variable name="type" select="'act'"/>
                <xsl:variable name="subtype" select="tokenize($principale, ':')[4]"/>
                <xsl:variable name="author" select="tokenize($principale, ':')[3]"/>
                <xsl:variable name="date" select="substring-before(tokenize($principale, ':')[5], ';')"/>
                <xsl:variable name="num" select="substring-after(tokenize($principale, ':')[5], ';')"/>

                <xsl:value-of select="string-join(('/akn', 'it', $type, $subtype, $author, $date, $num), '/')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Estrai un blocco da un urn (Separatori ammessi: *, @, $, !, ~)
         cercaMacroblocco("<...>*<comunicato>@<versione>", "*") -> "<comunicato>" -->
    <xsl:function name="u:cercaMacroblocco">
        <xsl:param name="input"/>
        <xsl:param name="separatore"/>
        <xsl:variable name="dopoSeparatore" select="substring-after($input, $separatore)"/>
        <xsl:value-of select="u:primoMacroblocco($dopoSeparatore)"/>
    </xsl:function>

    <xsl:function name="u:primoMacroblocco">
        <xsl:param name="input"/>
        <xsl:variable name="macroSeparatori" select="'[\*@!~]'"/>
        <xsl:value-of select="tokenize($input, $macroSeparatori)[1]"/>
    </xsl:function>

    <xsl:function name="u:convertiComunicato">
        <!-- urn:nir:stato:legge:2000-09-29;300*entrata.vigore;2001-08-07 -->
        <!-- /akn/it/doc/entrata_vigore/stato/2001-08-07/legge_2000-09-29_300 -->
        <xsl:param name="urn"/>
        <xsl:variable name="principale" select="u:primoMacroblocco($urn)"/>
        <xsl:variable name="comunicato" select="u:cercaMacroblocco($urn, '*')"/>
        <xsl:variable name="subtype" select="replace(substring-before($comunicato, ';'), '\.', '_')"/>
        <xsl:variable name="author" select="tokenize($principale, ':')[3]"/>
        <xsl:variable name="date" select="substring-after($comunicato, ';')"/>
        <xsl:variable name="referencedSubtype" select="tokenize($principale, ':')[4]"/>
        <xsl:variable name="referencedDate" select="substring-before(tokenize($principale, ':')[5], ';')"/>
        <xsl:variable name="referencedNum" select="substring-after(tokenize($principale, ':')[5], ';')"/>
        <xsl:variable name="num" select="string-join(($referencedSubtype, $referencedDate, $referencedNum), '_')"/>
        <xsl:value-of select="string-join(('/akn', 'it', 'doc', $subtype, $author, $date, $num), '/')"/>
    </xsl:function>

    <xsl:template match="node()|@*" mode="copyEverything">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="copyEverything"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>

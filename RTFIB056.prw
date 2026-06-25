#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} RTFIB056
Cadastro de IML
@type function
@version 1.0
@author maria.fasollo
@since 12/11/2025
/*/

User Function RTFIB056()

    Local aArea     := GetArea()
    Local oBrowse
    Local cFiltro
    Private aRotina := MenuDef()

    // Monta lista de ZOE_SEQ unicos (um por TABELA+FORNEC+LOJA) via query
    cFiltro := ZOESeqList()

    //Cria um browse para a ZOE
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias("ZOE")
    oBrowse:SetDescription("Cadastro de IML")

    // Aplica filtro com a lista de SEQs unicos
    If !Empty(cFiltro)
        oBrowse:SetFilterDefault("ZOE_SEQ $ '" + cFiltro + "'")
    EndIf

    // Define somente os campos que devem aparecer no browse
    oBrowse:SetOnlyFields({"ZOE_TABELA", "ZOE_FORNEC", "ZOE_LOJA", "ZOE_NMFOR", "ZOE_TIPO", "ZOE_VALID"})

    // Legenda baseada no campo ZOE_STATUS
    oBrowse:AddLegend( "ZOE->ZOE_STATUS == 'E'", "BR_AMARELO", "Elaboracao" )
    oBrowse:AddLegend( "ZOE->ZOE_STATUS == 'A'", "BR_LARANJA", "Aprovacao"  )
    oBrowse:AddLegend( "ZOE->ZOE_STATUS == 'V'", "CHECKED",    "Vigente"    )
    oBrowse:AddLegend( "ZOE->ZOE_STATUS == 'F'", "BR_CANCEL",  "Finalizada" )

    oBrowse:Activate()

    RestArea(aArea)
Return Nil


Static Function ZOESeqList()

    Local cQuery
    Local cAlias
    Local cList
    Local cSeq

    // Busca o menor ZOE_SEQ de cada grupo FILIAL+TABELA+FORNEC+LOJA
    cQuery := "SELECT MIN(ZOE_SEQ) AS MINSEQ "
    cQuery += "FROM " + RetSQLName("ZOE") + " "
    cQuery += "WHERE D_E_L_E_T_ = ' ' "
    cQuery += "  AND ZOE_FILIAL = '" + xFilial("ZOE") + "' "
    cQuery += "GROUP BY ZOE_TABELA, ZOE_FORNEC, ZOE_LOJA "
    cAlias  := GetNextAlias()
    cList   := "/"

    DBUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)

    Do While Select(cAlias) > 0 .And. !(cAlias)->(EOF())
        cSeq  := AllTrim((cAlias)->MINSEQ)
        cList := cList + cSeq + "/"
        (cAlias)->(DBSkip())
    EndDo

    If Select(cAlias) > 0
        (cAlias)->(DBCloseArea())
    EndIf

Return cList

Static Function MenuDef()
    Local aRot := {}

    //Adicionando opcoes
    ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.RTFIB056' OPERATION MODEL_OPERATION_VIEW   ACCESS 0
    ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.RTFIB056' OPERATION MODEL_OPERATION_INSERT ACCESS 0
    ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.RTFIB056' OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.RTFIB056' OPERATION MODEL_OPERATION_DELETE ACCESS 0
Return aRot

Static Function ModelDef()
    //Na montagem da estrutura do Modelo de dados, o cabeçalho vai filtrar e exibir; somente 3 campos
    //Já a grid vai carregar a estrutura inteira conforme ffunção fModStruct
    Local oModel      := NIL
    Local oStruCab    := FWFormStruct(1, 'ZOE',{|cCampo| AllTRim(cCampo) $ "ZOE_FORNEC;ZOE_LOJA;ZOE_NMFOR;ZOE_LITRAG;ZOE_TIPO;"})
    Local oStruGrid   := FWFormStruct(1, 'ZOE')// fModStruct()

    //Monta o modelo de dados, e validação, informa a função fValidGrid
    oModel := MPFormModel():New('ZOEMODEL', /*bPreValidacao*/, {|oModel| f0212Pos(oModel)}, /*bCommit*/, /*bCancel*/ )

    //Agora, define no modelo de dados, que terao um Cabeçalho e uma Grid apontando para estruturas acima
    oModel:AddFields('MdFieldZOE', NIL, oStruCab)
    oModel:AddGrid('MdGridZOE', 'MdFieldZOE', oStruGrid,{|oGrid, nLine, cAction| fValidGrid(oModel,oGrid,nLine,cAction)} )

    //Monta o relacionamento entre Grid e Cabeçalho, as expressoes da esquerda representam campo Grid e direita cabeçalho 
    oModel:SetRelation('MdGridZOE', {{'ZOE_FILIAL', 'xFilial("ZOE")'},;
        {"ZOE_FORNEC", "ZOE_FORNEC"},{"ZOE_LOJA", "ZOE_LOJA"},;
        {"ZOE_NMFOR", "ZOE_NMFOR"},{"ZOE_TIPO", "ZOE_TIPO"};
        }, ZOE->(IndexKey(1)))

    //Definindo outras informaçoes do Modelo e da Grid
    oModel:GetModel("MdGridZOE"):SetMaxLine(9999)
    oModel:SetDescription("Fornecedores  ")
    oModel:SetPrimaryKey({"ZOE_FILIAL", "ZOE_FORNEC", "ZOE_LOJA", "ZOE_NMFOR", "ZOE_LITRAG", "ZOE_TIPO"}) 

Return oModel

Static Function ViewDef()
    //Na montagem da estrutura da visualização de dados, chamar o modelo criado anteriormente
    //No cabeçalho, mostrar somente 3 campos, e na grid carregar conforme a função fViewStruct
    Local oView     := NIL
    Local oModel    := FWLoadModel('RTFIB056')
    Local oStruCab  := FWFormStruct(2, "ZOE", {|cCampo| AllTRim(cCampo) $ "ZOE_FORNEC;ZOE_LOJA;ZOE_NMFOR;ZOE_TIPO"})
    Local oStruGRID := fViewStruct()//FWFormStruct(2, "ZOE")

    //Define que no cabeçalhos que não terão sparação de abas (SXA)
    oStruCab:SetNoFolder()

    //Cria o View
    oView:= FWFormView():New()
    oView:SetModel(oModel)

    //Cria uma área de Field vinculando a estrutura do cabeçalho com MdFieldZOE e uma Grid vinculando com MdGridZOE
    oView:AddField('VIEW_ZOE', oStruCab, 'MdFieldZOE')
    oView:AddGrid('GRID_ZOE', oStruGRID, 'MdGridZOE' )

    //O cabeçalho (MAIN) terá 25% de tamanho, e o restante de 75% vai para a GRID
    oView:CreateHorizontalBox("MAIN", 25)
    oView:CreateHorizontalBox("GRID", 75)

    //Vincula o MAIN com a VIEW_ZOE e a GRID com a GRID_ZOE
    oView:SetOwnerView('VIEW_ZOE', 'MAIN')
    oView:SetOwnerView('GRID_ZOE', 'GRID')
    oView:EnableControlBar(.T.)

Return oView

//Função chamada para montar a visualização de dados da Grid
Static Function fViewStruct()
    Local cCampoCom := "ZOE_FORNEC;ZOE_LOJA;ZOE_NMFOR;ZOE_TIPO"

    Local oStruct

    //Irá filtrar, e trazer todos os campos, menos os que tiverem na variável cCampoCom
    oStruct := FWFormStruct(2, "ZOE", {|cCampo| !(Alltrim(cCampo) $ cCampoCom)})
Return oStruct

//Função que faz a validação da grid
Static Function fValidGrid(oModel,oGrid, nLine, cAction)
    Local lRet     := .T.
   
Return lRet

Static Function f0212POS( oMdl ) 
    Local lRet := .T.
    Local nOperation := oMdl:GetOperation()

    Local oCab := oMdl:GetModel("MdFieldZOE")
    //Local oDet := oMdl:GetModel("MdGridZOE")
    //Local _i

    If nOperation == MODEL_OPERATION_INSERT

        If Empty(oCab:GetValue("ZOE_FORNEC"))
            Help(nil,nil,'Inclusão de Fornecedor.',nil,'O campo Fornecedor está vazio',1,0,nil,nil,nil,nil,nil,;
                {'Verifique o campo Fornecedor no cabeçalho.'})
            lRet := .F.
        EndIf

        If Empty(oCab:GetValue("ZOE_LOJA"))
            Help(nil,nil,'Inclusão de Loja.',nil,'O campo Loja está vazio',1,0,nil,nil,nil,nil,nil,;
                {'Verifique o campo Loja no cabeçalho.'})
            lRet := .F.
        EndIf

        If Empty(oCab:GetValue("ZOE_TIPO"))
            Help(nil,nil,'Inclusão de Tipo.',nil,'O Tipo de IML está vazio',1,0,nil,nil,nil,nil,nil,;
                {'Verifique Tipo de IML no cabeçalho.'})
            lRet := .F.
        EndIf

        /*If Empty(oCab:GetValue("ZOE_LITRAG"))
            Help(nil,nil,'Inclusão de Litragem.',nil,'O campo Litragem esta vazio',1,0,nil,nil,nil,nil,nil,;
                {'Verifique o campo Litragem no cabeçalho.'})
            lRet := .F.
        EndIf*/

    EndIf

Return lRet


--[[

    Extensible DTree based entity editor as an alternative to the default garrysmod editor
    by shadowscion

]]

local PANEL = {}

surface.CreateFont( "DTreeEditorBaseSmall", { font = "Arial", size = 14 } )
surface.CreateFont( "DTreeEditorBaseLarge", { font = "Arial Bold", size = 14 } )

local pretty = {
    fontSmall = "DTreeEditorBaseSmall",
    fontLarge = "DTreeEditorBaseLarge",
    panelBevel = 4,
    colorHeader = Color( 122, 189, 254, 255 ),
    colorHeaderLight = Color( 122, 189, 254, 255 ),
    colorTextEntry = Color( 122, 189, 254, 50 ),
    colorBackground = Color( 245, 245, 245, 255 ),
    colorRowHighlight = Color( 122, 189, 254, 50 ),
}

function PANEL:GetEditorSkin()
    return pretty
end

function PANEL:PostNodeAdded( pNode )
end

function PANEL:OnEntityLost()
end

function PANEL:OnWindowStopDragging()
end

function PANEL:HideRow( name, hide )
    if self.rows[name] then
        self.rows[name]:SetVisible( hide )
        self:InvalidateChildren( true )
    end
end

function PANEL:HideCategory( name, hide )
    if self.categories[name] then
        self.categories[name]:SetVisible( hide )
        self:InvalidateChildren( true )
    end
end

function PANEL:Init()
    self.categories = {}
    self.rows = {}

    self:DockMargin( 0, 3, 0, 3 )
    self.RootNode:DockMargin( 0, 0, 0, 0 )
    self.Paint = nil

    self.VBar.SetEnabled = function( self, b )
        DVScrollBar.SetEnabled( self, true )
    end
    self.VBar:SetHideButtons( true )
end

function PANEL:PerformLayoutInternal()
    local Tall = self.pnlCanvas:GetTall()
    local Wide = self:GetWide()
    local YPos = 0

    self:Rebuild()

    self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
    YPos = self.VBar:GetOffset()

    if self.VBar.Enabled then Wide = Wide - self.VBar:GetWide() - 3 end

    self.pnlCanvas:SetPos( 0, YPos )
    self.pnlCanvas:SetWide( Wide )

    self:Rebuild()

    if Tall ~= self.pnlCanvas:GetTall() then
        self.VBar:SetScroll( self.VBar:GetScroll() )
    end
end

function PANEL:OnNodeSelected(item)
    self:SetSelectedItem( nil )
end


function PANEL:OnRemove()
    if IsValid( self.m_Entity ) then
        if isfunction( self.m_Entity.EditorCallback ) then self.m_Entity:EditorCallback( self, "EDITOR_OPEN", false ) end
        self.m_Entity:RemoveCallOnRemove( "DTreeEditorBase_DTree" )
    end
end


function PANEL:SetEntity( entity )
    if self.m_Entity == entity then return end

    if IsValid( self.m_Entity ) then
        self.m_Entity:RemoveCallOnRemove( "DTreeEditorBase_DTree" )
    end

    if not IsValid( entity ) then return end

    self.m_Entity = entity

    self.m_Entity:CallOnRemove( "DTreeEditorBase_DTree", function( e )
        timer.Simple( 0, function()
            if IsValid( e ) then return end

            if IsValid( self) then
                self:GetParent():Remove()
            end
        end )
    end )

    self:GetParent():SetTitle( tostring( self.m_Entity ) )

    self:RebuildControls()
end


function PANEL:EntityLost()
    self:Clear()
    self:OnEntityLost()
end


function PANEL:AddNode( strName, strIcon )
    self.RootNode:CreateChildNodes()

    local pNode = vgui.Create( "DTreeEditorBase_Category", self.RootNode )
    pNode:SetText( string.upper( strName ) )
    pNode:SetParentNode( self.RootNode )
    pNode:SetRoot( self.RootNode:GetRoot() )
    pNode.Label:SetFont( self:GetEditorSkin().fontLarge )

    self.RootNode:InstallDraggable( pNode )

    self.RootNode.ChildNodes:Add( pNode )
    self.RootNode:InvalidateLayout()

    self.RootNode:OnNodeAdded( pNode )

    return pNode
end


function PANEL:CreateRow( editName, editData )
    local category = self:CreateCategory( editData.category or "GENERAL" )
    local node = category

    if editData.subcategory then
        if not category.subcategories then
             category.subcategories = {}
        end
        if not category.subcategories[editData.subcategory] then
            category.subcategories[editData.subcategory] = category:AddNode( editData.subcategory )
        end

        node = category.subcategories[editData.subcategory]
    end

    local row = node:AddNode( editData.title or editName )
    row:SetRowCategory( category )

    category.RowNodes[editName] = row

    return row
end


function PANEL:CreateCategory( name )
    if not self.categories[name] then
        self.categories[name] = self:AddNode( name )
        self.categories[name].RowNodes = {}
    end

    return self.categories[name]
end


function PANEL:RebuildControls()
    self:Clear()

    if not IsValid( self.m_Entity ) then return end
    if not isfunction( self.m_Entity.GetEditingData ) then return end

    local editor = self.m_Entity:GetEditingData()

    local i = 100000
    for name, edit in pairs( editor ) do
        if edit.order == nil then edit.order = i end
        i = i + 1
    end

    self.m_iLabelWidth = 0
    self.categories = {}
    self.rows = {}

    for name, edit in SortedPairsByMemberValue( editor, "order" ) do
        self.rows[name] = self:EditVariable( name, edit )
    end

    self.m_bInitialzied = nil

    local callback = isfunction( self.m_Entity.EditorCallback )

    if callback then
        for name, row in pairs( self.rows ) do
            self.m_Entity:EditorCallback( self, name, self.m_Entity:GetNetworkKeyValue( name ) )
        end

        self.m_Entity:EditorCallback( self, "EDITOR_OPEN", true )
    end

    self.m_bInitialzied = true
end

function PANEL:EditVariable( editName, editData )
    local row = self:CreateRow( editName, editData )

    row:Setup( editData )

    if isstring( editData.help ) then row:SetTooltip( editData.help ) end

    local callback = isfunction( self.m_Entity.EditorCallback )

    row.DataUpdate = function( _ )
        if not IsValid( self.m_Entity ) then self:EntityLost() return end
        row:SetValue( self.m_Entity:GetNetworkKeyValue( editName ) )
    end

    row.DataChanged = function( _, val )
        if not IsValid( self.m_Entity ) then self:EntityLost() return end
        self.m_Entity:EditValue( editName, tostring( val ) )
        if callback then
            self.m_Entity:EditorCallback( self, editName, val )
        end
    end

    return row
end

function PANEL:OnNodeAdded( pNode )
    local lw = pNode.Label:GetTextSize()
    local ix = pNode.Label:GetTextInset()
    local ew = pNode.Expander:IsVisible() and pNode.Expander:GetWide() or 0
    local iw = pNode.Icon:IsVisible() and pNode.Icon:GetWide() or 0

    local x = ( lw + ix + ew + iw ) + ( pNode.m_iNodeLevel or 0 ) * 16

    if self.m_iLabelWidth < x then
        self.m_iLabelWidth = x
    end

    self:PostNodeAdded( pNode )
end

function PANEL:GetLabelWidth()
    return self.m_iLabelWidth
end

function PANEL:SetupWindow()
    local window = self:GetParent()
    if not IsValid( window ) then return end

    local header = 24
    local footer = 12

    window:DockPadding( 4, header, 4, footer )

    window.GetEditorSkin = self.GetEditorSkin

    local color_faded = Color( 120, 120, 120, 255 )

    local function Box( bevel, x, y, w, h, color, ... )
        if bevel then
            draw.RoundedBoxEx( bevel, x, y, w, h, color_faded, ... )
            draw.RoundedBoxEx( bevel, x + 1, y + 1, w - 2, h - 2, color, ... )
        else
            surface.SetDrawColor( color_faded )
            surface.DrawRect( x, y, w, h )
            surface.SetDrawColor( color )
            surface.DrawRect( x + 1, y + 1, w - 2, h - 2)
        end
    end

    window.Paint = function( pnl, w, h )
        local sk = pnl:GetEditorSkin()

        Box( sk.panelBevel, 0, 0, w, header, sk.colorHeader, true, true, false, false )
        Box( sk.panelBevel, 0, h - footer, w, footer, sk.colorHeader, false, false, true, true )
        Box( false, 0, header - 1, w, h - footer - header + 2, sk.colorBackground )
    end

    window.lblTitle:SetFont( self:GetEditorSkin().fontSmall )
    window.lblTitle:SetColor( color_white )
    window.lblTitle:SetTextInset( 4, 0 )
    window.lblTitle:SetContentAlignment( 5 )

    window.btnMinim:Remove()
    window.btnMaxim:Remove()
    window.btnClose:Remove()

    window.btnClose = vgui.Create( "DImageButton", window )
    window.btnClose:SetImage( "gui/cross.png" )
    window.btnClose.DoClick = function()
        window:Remove()
    end

    window.PerformLayout = function( _, w, h )
        window.lblTitle:SetPos( 0, 0 )
        window.lblTitle:SetSize( w - 20, header )

        window.btnClose:SetPos( w - 16 - 4, 4 )
        window.btnClose:SetSize( 16, 16 )
    end

    window.Think = function()
        DFrame.Think( window )

        if window.Dragging then
            self.m_bIsDragging = true
        elseif self.m_bIsDragging then
            self:WindowStopDragging()
            self.m_bIsDragging = nil
        end
    end
end

function PANEL:WindowStopDragging()
    self:OnWindowStopDragging()
end


vgui.Register( "DTreeEditorBase", PANEL, "DTree" )

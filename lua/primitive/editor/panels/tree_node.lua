
local PANEL = {}

AccessorFunc( PANEL, "m_pRowHighlight", "RowHighlight" )
AccessorFunc( PANEL, "m_pRowCategory", "RowCategory" )

local function expand( self )
    local self = self:GetParent()

    if self:HasChildren() then
        self:SetExpanded( not self:GetExpanded() )

        if self.Icon and self.Icon:IsVisible() then
            local sk = self:GetEditorSkin()

            self.Icon:SetImageColor( self:GetExpanded() and sk.colorHeader or sk.colorHeaderLight )
        end
    else
        self:SetExpanded( false )
    end
end

local faded = Color(255, 255, 255, 200)
local function paintExp( self, w, h )
    if self:GetExpanded() then
        self:GetSkin().tex.TreeMinus( 0, 0, w, h, faded )

        return
    end
    self:GetSkin().tex.TreePlus( 0, 0, w, h, faded )
end


function PANEL:GetEditorSkin()
    return self:GetRoot():GetEditorSkin()
end


function PANEL:GetIsDragging()
    return self:GetRoot().m_bIsDragging
end


function PANEL:Init()
    self:SetTall( self:GetLineHeight() )

    self:SetHideExpander( false )
    self:SetDrawLines( true )

    self.Label:SetTextColor( Color( 50, 50, 50, 255 ) )

    self.Label.DoClick = expand
    self.Expander.DoClick = expand
    self.Expander.Paint= paintExp

    self.Container = self:Add( "Panel" )
    self.Container.Paint = nil
    self.Container:DockPadding( 4, 1, 0, 1 )
end


function PANEL:PerformLayout( w, h )
    DTree_Node.PerformLayout( self )

    local inset = 18
    local l = self:GetRoot():GetLabelWidth() - ( self.m_iNodeLevel or 0 ) * inset

    self.Label:SetSize( l, self:GetLineHeight() )
    self.Container:SetSize( w - l, self:GetLineHeight() )
    self.Container:SetPos( l, 0 )
end


function PANEL:ShowIcons()
    return true
end


function PANEL:GetLineHeight()
    return 18
end


function PANEL:Paint( w, h )
    if self.m_pRowHighlight and self:GetExpanded() then
        local sk = self:GetEditorSkin()

        surface.SetDrawColor( sk.colorRowHighlight )
        surface.DrawRect(0, 1, w, h - 2)
    elseif self.Label.Hovered or self:IsChildHovered() then
        local sk = self:GetEditorSkin()

        surface.SetDrawColor( sk.colorRowHighlight )
        surface.DrawRect( 0, 0, w, self:GetLineHeight() )
    end

    return DTree_Node.Paint( self, w, h )
end


function PANEL:AddNode( strName )
    self.Icon:SetImage( "icon16/page_white_horizontal.png" )
    self.Label:SetFont( self:GetEditorSkin().fontLarge )
    self:SetRowHighlight( true )

    self:CreateChildNodes()

    local pNode = vgui.Create( "DTreeEditorBase_Node", self )
    pNode.Label:SetFont( self:GetEditorSkin().fontSmall )
    pNode:SetText( string.lower( strName ) )
    pNode:SetParentNode( self )
    pNode:SetRoot( self:GetRoot() )
    pNode.m_iNodeLevel = ( self.m_iNodeLevel or 0 ) + 1

    self:InstallDraggable( pNode )

    pNode.Icon:SetImage( "icon16/bullet_white.png" )
    pNode.Icon:SetImageColor( self:GetEditorSkin().colorHeader )

    self.ChildNodes:Add( pNode )
    self:InvalidateLayout()

    self:OnNodeAdded( pNode )

    return pNode
end


function PANEL:OnNodeAdded( pNode )
    self:GetRoot():OnNodeAdded( pNode )
end


function PANEL:SetValue( val )
    if self.CacheValue and self.CacheValue == val then return end
    self.CacheValue = val

    if IsValid( self.Inner ) then
        self.Inner:SetValue( val )
    end
end


local lookup = {
    int = "Number",
    float = "Number",
    number = "Number",
    string = "Generic",
    bool = "Checkbox",
    boolean = "Checkbox",
    checkbox = "Checkbox",
    bitfield = "Bitfield",
    combo = "Combo",
    vector = "Vector",
    angle = "Vector",
}

function PANEL:Setup( editData )
    self.Container:Clear()

    local rowType = tostring( editData.panel or editData.type )
    local control = "DTreeEditorBase_" .. rowType

    if not vgui.GetControlTable( control ) then
        control = "DTreeEditorBase_" .. ( lookup[string.lower( rowType )] or "Generic" )
    end

    if vgui.GetControlTable( control ) then
        self.Inner = self.Container:Add( control )
    else
        print( "DTreeEditorBase: Failed to create panel (" .. control .. ")" )
    end
    if not IsValid( self.Inner ) then self.Inner = self.Container:Add( "DTreeEditorBase_Generic" ) end

    self.Inner:SetRow( self )
    self.Inner:Dock( FILL )
    self.Inner:Setup( editData )

    self.Inner:SetEnabled( self:IsEnabled() )

    self.IsEnabled = function( self )
        return self.Inner:IsEnabled()
    end

    self.SetEnabled = function( self, b )
        self.Inner:SetEnabled( b )
    end
end


vgui.Register( "DTreeEditorBase_Node", PANEL, "DTree_Node" )

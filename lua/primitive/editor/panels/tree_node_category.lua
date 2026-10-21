
local PANEL = {}

AccessorFunc( PANEL, "m_pRowHighlight", "RowHighlight" )


function PANEL:GetEditorSkin()
    return self:GetRoot():GetEditorSkin()
end


function PANEL:GetIsDragging()
    return self:GetRoot().m_bIsDragging
end


function PANEL:DoClick()
    self:SetExpanded( not self:GetExpanded() )
end


function PANEL:Init()
    self:SetTall( self:GetLineHeight() )
    self:DockMargin( 0, 0, 0, 3 )

    self:SetHideExpander( true )
    self:SetDrawLines( false )

    self.Label:SetExpensiveShadow( 2, Color( 50, 50, 50, 50 ) )
    self.Label:SetTextColor( color_white )
end


function PANEL:ShowIcons()
    return false
end


function PANEL:GetLineHeight()
    return 20
end


function PANEL:Paint( w, h )
    local sk = self:GetEditorSkin()

    if self:GetExpanded() then
        draw.RoundedBoxEx( sk.panelBevel, 0, 0, w, self:GetLineHeight(), sk.colorHeaderLight, true, true, false, false )

        return
    end

    draw.RoundedBoxEx( sk.panelBevel, 0, 0, w, self:GetLineHeight(), sk.colorHeader, true, true, true, true )
    self:GetSkin().tex.Input.ComboBox.Button.Down(w - 18, self:GetLineHeight()*0.5 - 8, 15, 15 )
end


function PANEL:AddNode( strName )
    local pNode = vgui.GetControlTable( "DTreeEditorBase_Node" ).AddNode( self, strName )

    if not self.pNodeFirst then
        self.pNodeFirst = pNode
        pNode:DockMargin( 0, 3, 0, 0 )
    end

    return pNode
end


function PANEL:OnNodeAdded( pNode )
    self:GetRoot():OnNodeAdded( pNode )
end


vgui.Register( "DTreeEditorBase_Category", PANEL, "DTree_Node" )

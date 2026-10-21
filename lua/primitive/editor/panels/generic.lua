
--[[

    Most of these panels follow the same basic structure as DProperties_*

]]

local PANEL = {}

AccessorFunc( PANEL, "m_pRow", "Row" )


function PANEL:Init()
end


function PANEL:GetIsDragging()
    return self:GetRow():GetIsDragging()
end


function PANEL:GetEditorSkin()
    return self:GetRow():GetEditorSkin()
end


function PANEL:Think()
    if not self:IsEditing() and isfunction( self.m_pRow.DataUpdate ) then
        self.m_pRow:DataUpdate()
    end
end


function PANEL:ValueChanged( newval, bForce )
    if ( self:IsEditing() or bForce ) and isfunction( self.m_pRow.DataChanged ) then
        self.m_pRow:DataChanged( newval )
    end
end


function PANEL:Setup( editData )
    self:Clear()

    local editor = self:Add( "DTextEntry" )
    editor:SetUpdateOnType( false )
    editor:SetPaintBackground( false )
    editor:Dock( FILL )

    editor.Paint = function( t, w, h )
        local sk = self:GetEditorSkin()

        surface.SetDrawColor( sk.colorTextEntry )
        surface.DrawRect( 0, 0, w, h )
        t:DrawTextEntryText( t:GetTextColor(), t:GetHighlightColor(), t:GetCursorColor() )
    end

    self.IsEnabled = function( _ )
        return editor:IsEnabled()
    end

    self.SetEnabled = function( _, b )
        editor:SetEnabled( b )
    end

    self.IsEditing = function( _ )
        return editor:IsEditing()
    end

    self.SetValue = function( _, val )
        editor:SetText( util.TypeToString( val ) )
    end

    editor.OnValueChange = function( _, newval )
        self:ValueChanged( newval )
    end
end


vgui.Register( "DTreeEditorBase_Generic", PANEL, "Panel" )

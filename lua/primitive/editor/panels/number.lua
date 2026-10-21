
local PANEL = {}


function PANEL:Init()
end


function PANEL:Setup( editData )
    self:Clear()

    editData = editData or {}

    local editor = self:Add( "DNumSlider" )

    editor:SetMin( editData.min or 0 )
    editor:SetMax( editData.max or 1 )

    local int = ( editData.panel or editData.type ) == "int"
    editor:SetDecimals( int and 0 or ( editData.decimals or 2 ) )

    editor:Dock( FILL )
    editor.TextArea:Dock( LEFT )
    editor.Label:Dock( RIGHT )

    editor:SetDark( true )

    editor.Slider.Knob:NoClipping( false )
    editor.Slider.UpdateNotches = function( s ) return s:SetNotches (8 ) end
    editor.Slider:UpdateNotches()

    editor.Label:SetWide( 15 )
    editor.TextArea:SetWide( 50 )
    editor.TextArea:SetUpdateOnType( false )
    editor.Scratch:SetImageVisible( true )
    editor.Scratch:SetImage( "icon16/link.png" )

    editor.PerformLayout = function()
        editor.Scratch:SetVisible( true )
        editor.Label:SetVisible( true )
        editor.Slider:StretchToParent( 0, 0, 0, 0 )
        editor.Slider:SetSlideX( editor.Scratch:GetFraction() )
    end

    editor.TextArea.Paint = function( t, w, h )
        local sk = self:GetEditorSkin()

        surface.SetDrawColor( sk.colorTextEntry )
        surface.DrawRect( 0, 0, w, h )
        t:DrawTextEntryText( t:GetTextColor(), t:GetHighlightColor(), t:GetCursorColor() )
    end

    editor.OnValueChanged = function( _, newval )
        if editor:GetDecimals() == 0 then newval = math.floor( newval ) end
        self:ValueChanged( newval )
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
        editor:SetValue( val )
    end

    self.Paint = function()
        local vis = self:IsEditing() or self:GetIsDragging() or self:GetRow():IsChildHovered()

        editor.Slider:SetVisible( vis )
        editor.Scratch:SetVisible( vis )
    end
end


vgui.Register( "DTreeEditorBase_Number", PANEL, "DTreeEditorBase_Generic" )

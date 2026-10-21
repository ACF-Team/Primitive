
local PANEL = {}


function PANEL:Init()
end


function PANEL:Setup( editData )
    self:Clear()

    local editor = self:Add( "DCheckBox" )
    editor:SetPos( 0, 0 )

    self.IsEditing = function( _ )
        return editor:IsEditing()
    end

    self.IsEnabled = function( _ )
        return editor:IsEnabled()
    end

    self.SetEnabled = function( _, b )
        editor:SetEnabled( b )
    end

    self.SetValue = function( _, val )
        editor:SetChecked( tobool( val ) )
    end

    editor.OnChange = function( editor, newval )
        if newval then newval = 1 else newval = 0 end
        self:ValueChanged( newval )
    end
end


vgui.Register( "DTreeEditorBase_Checkbox", PANEL, "DTreeEditorBase_Generic" )

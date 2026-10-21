
local PANEL = {}


function PANEL:Init()
end


function PANEL:Setup( editData )
    editData = editData or {}

    self:Clear()

    local combo = vgui.Create( "DComboBox", self )
    combo:Dock( FILL )
    combo:DockMargin( 0, 0, 0, 0 )
    combo:SetValue( editData.text or "Select..." )

    -- combo.OnMenuOpened = function( _, menu )
    --     menu:SetDrawColumn( true )
    -- end

    local hasIcons, pattern, icon = editData.icons
    if isstring( hasIcons ) then pattern = true elseif not istable( hasIcons ) then hasIcons = nil end

    for id, thing in SortedPairs( editData.values or {} ) do
        if hasIcons then
            if pattern then icon = string.format( hasIcons, id ) else icon = hasIcons[ id ] end
        end

        combo:AddChoice( id, thing, id == editData.select, icon )
        combo:AddSpacer()
    end

    self.IsEditing = function( self )
        return combo:IsMenuOpen()
    end

    self.SetValue = function( self, val )
        for id, data in pairs( combo.Data ) do
            if data == val then
                combo:ChooseOptionID( id )
            end
        end
    end

    combo.OnSelect = function( _, id, val, data )
        self:ValueChanged( data, true )
    end

    combo.Paint = function( combo, w, h )
        if self:IsEditing() or self:GetRow():IsHovered() or self:GetIsDragging() or self:GetRow():IsChildHovered() then
            DComboBox.Paint( combo, w, h )
        end
    end

    self:GetRow().AddChoice = function( _, value, data, select )
        combo:AddChoice( value, data, select )
    end

    self:GetRow().SetSelected = function( _, id )
        combo:ChooseOptionID( id )
    end

    self.IsEnabled = function( _ )
        return combo:IsEnabled()
    end

    self.SetEnabled = function( _, b )
        combo:SetEnabled( b )
    end
end


vgui.Register( "DTreeEditorBase_Combo", PANEL, "DTreeEditorBase_Generic" )

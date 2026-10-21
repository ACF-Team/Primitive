

local function hasFlag( bits, flag )
    return bit.band( bits, flag ) == flag
end

local function setFlag( bits, flag )
    if not ( bit.band( bits, flag ) == flag ) then
        return bit.bor( bits, flag )
    end
    return bits
end

local function unsetFlag( bits, flag )
    if bit.band( bits, flag ) == flag then
        bits = bit.band( bits, bit.bnot( flag ) )
    end
    return bits
end


local PANEL = {}


function PANEL:Init()
end


function PANEL:Setup( editData )
    local innerVal = 0
    local editors = {}

    local istree = istable( editData.lbl )
    local count = istree and #editData.lbl or tonumber( editData.num ) or 1

    for i = 1, count do
        local parent = self
        if istree then
            parent = self:GetRow():AddNode( editData.lbl[i] or "" ).Container
        end

        local panel = parent:Add( "DCheckBox" )
        editors[i] = panel

        if not istree then panel:SetPos( i * 17 - 17 , 0 ) else panel:SetPos( 4, 0 ) end
        panel.flag = bit.lshift( 1, i - 1 )

        panel.OnChange = function( _, val )
            if val then
                innerVal = setFlag( innerVal, panel.flag )
            else
                innerVal = unsetFlag( innerVal, panel.flag )
            end
            self:ValueChanged( innerVal )
        end
    end

    self.SetValue = function( self, val )
        innerVal = tonumber( val )

        for i = 1, #editors do
            editors[i]:SetChecked( hasFlag( innerVal, editors[i].flag ) )
        end
    end

    self.IsEditing = function( self )
        for i = 1, #editors do
            if editors[i]:IsEditing() then
                return true
            end
        end

        return false
    end

    self.IsEnabled = function( self )
        return editors[1]:IsEnabled()
    end

    self.SetEnabled = function( self, b )
        for i = 1, #editors do
            editors[i]:SetEnabled( b )
        end
    end
end


vgui.Register( "DTreeEditorBase_Bitfield", PANEL, "DTreeEditorBase_Generic" )

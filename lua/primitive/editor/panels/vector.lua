
local function GetValue( val, editData )
    if editData.typename == "Angle" then
        val = Angle( val[1], val[2], val[3] )
        val:Normalize()
    else
        val = Vector( val[1], val[2], val[3] )
    end

    local min = editData.min
    local max = editData.max

    if min then
        if val.x < min.x then val.x = min.x end
        if val.y < min.y then val.y = min.y end
        if val.z < min.z then val.z = min.z end
    end
    if max then
        if val.x > max.x then val.x = max.x end
        if val.y > max.y then val.y = max.y end
        if val.z > max.z then val.z = max.z end
    end

    return val
end

local function GetTextValue( val )
    return string.format( "%.2f", val )
end


local PANEL = {}


function PANEL:Init()
end

function PANEL:Setup( editData )
    self:Clear()

    local inline = editData.inline
    local angle = editData.typename == "Angle"

    local x, y, z, innerVal

    local function painter( pnl, w, h )
        local sk = self:GetEditorSkin()

        surface.SetDrawColor( sk.colorTextEntry )
        surface.DrawRect( 0, 0, w, h )
        pnl:DrawTextEntryText( pnl:GetTextColor(), pnl:GetHighlightColor(), pnl:GetCursorColor() )
    end

    if inline then
        x = self:Add( "DTextEntry" )
        y = self:Add( "DTextEntry" )
        z = self:Add( "DTextEntry" )

        x:SetNumeric( true )
        y:SetNumeric( true )
        z:SetNumeric( true )

        for k, v in pairs( { x, y, z } ) do
            v.Paint = painter
            v.OnValueChange = function( _, val )
                innerVal[k] = val
                self:ValueChanged( innerVal )
            end
        end

        self.PerformLayout = function( pnl, w, h )
            local l = math.floor( w / 3 )

            x:SetSize( l - 2, h )
            y:SetSize( l - 2, h )
            z:SetSize( l - 2, h )

            if inline then
                x:SetPos( 0, 0 )
                y:SetPos( l, 0 )
                z:SetPos( l + l, 0 )
            else
                x:SetPos( l, 0 )
                y:SetPos( l, 0 )
                z:SetPos( l, 0 )
            end
        end
    else
        x = self:GetRow():AddNode(angle and "p" or "x").Container:Add( "DNumSlider" )
        y = self:GetRow():AddNode("y").Container:Add( "DNumSlider" )
        z = self:GetRow():AddNode(angle and "r" or "z").Container:Add( "DNumSlider" )

        local PerformLayout = function( v )
            v.Scratch:SetVisible( true )
            v.Label:SetVisible( true )
            v.Slider:StretchToParent( 0, 0, 0, 0 )
            v.Slider:SetSlideX( v.Scratch:GetFraction() )
        end

        for k, v in pairs( { x, y, z } ) do
            v:SetMin( angle and -180 or editData.min and editData.min[k] or 0 )
            v:SetMax( angle and 180 or editData.max and editData.max[k] or 0 )

            v:SetDark( true )
            v:Dock( FILL )
            v.TextArea:Dock( LEFT )
            v.Label:Dock( RIGHT )

            v.Slider.Knob:NoClipping( false )
            v.Slider.UpdateNotches = function( s ) return s:SetNotches (8 ) end
            v.Slider:UpdateNotches()

            v.Label:SetWide( 15 )
            v.TextArea:SetWide( 50 )
            v.TextArea:SetUpdateOnType( false )
            v.TextArea.Paint = painter
            v.Scratch:SetImageVisible( true )
            v.Scratch:SetImage( "icon16/link.png" )
            v.PerformLayout = PerformLayout

            v.OnValueChanged = function( _, val )
                innerVal[k] = val
                self:ValueChanged( innerVal )
            end
        end

        self.Paint = function()
            local vis = self:IsEditing() or self:GetIsDragging() or self:GetRow():IsChildHovered()

            x.Slider:SetVisible( vis )
            x.Scratch:SetVisible( vis )
            y.Slider:SetVisible( vis )
            y.Scratch:SetVisible( vis )
            z.Slider:SetVisible( vis )
            z.Scratch:SetVisible( vis )
        end
    end

    self.IsEnabled = function( _ )
        return x:SetEnabled( b )
    end

    self.SetEnabled = function( _, b )
        x:SetEnabled( b )
        y:SetEnabled( b )
        z:SetEnabled( b )
    end

    self.IsEditing = function( _ )
        return x:IsEditing() or y:IsEditing() or z:IsEditing()
    end

    self.SetValue = function( _, val )
        innerVal = GetValue( val, editData )

        x:SetValue( GetTextValue( innerVal[1] ) )
        y:SetValue( GetTextValue( innerVal[2] ) )
        z:SetValue( GetTextValue( innerVal[3] ) )
    end
end


vgui.Register( "DTreeEditorBase_Vector", PANEL, "DTreeEditorBase_Generic" )

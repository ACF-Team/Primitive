
properties.Add( "editprimitive", {
    MenuLabel = "Edit Primitive",
    MenuIcon = "icon16/brick_edit.png",
    PrependSpacer = true,
    Order = 90001,

    Filter = function( _, ent, ply )
        if not IsValid( ent ) then return false end
        if not scripted_ents.IsBasedOn( ent:GetClass(), "primitive_base" ) then return false end
        if not gamemode.Call( "CanProperty", ply, "editprimitive", ent ) then return false end

        return true
    end,

    Action = function( _, ent )
        local window = g_ContextMenu:Add( "DFrame" )
        local h = math.Round( ScrH() / 2 ) * 2
        local w = math.Round( ScrW() / 2 ) * 2

        local tall = math.Round( ( h * 0.8 ) / 2 ) * 2
        local wide = 380

        window:SetSize( wide + 8, tall + 8 )
        window:SetPos( w - wide - 50 - 4, h - 50 - tall - 4 )
        window:SetSizable( true )

        local control = window:Add( "DTreeEditorBase" )
        control:SetupWindow()
        control:SetEntity( ent )
        control:Dock( FILL )

        control.OnEntityLost = function()
            window:Remove()
        end
    end,

    MenuOpen = function( _, menu )
        menu.m_Image:SetImage( "primitive/icons/primitive.png", "icon16/brick_edit.png" )
    end,
 } )

if SERVER then return end

local function refresh( node )
    node.m_SetRefresh = nil

    node.SetExpanded = function( self, bExpand )
        DTree_Node.SetExpanded( self, bExpand, false )
        cookie.Set( "PrimitiveMenuExpand", self:GetExpanded() and 1 or 0 )
    end

    node.DoClick = function( self )
        self:SetExpanded( not self:GetExpanded() )
    end

    node.OnNodeSelected = function( self, ... )
        DTree_Node.OnNodeSelected( self, ... )
        self:GetRoot():SetSelectedItem( nil )
    end

    node:Clear()
    node:SetText( "Primitive" )
    node.Icon:SetImage( "primitive/icons/primitive.png", "icon16/bullet_blue.png" )

    local categories = {}
    local spawnlist = {}

    hook.Run( "Primitive_PreRefreshMenu", spawnlist )

    if not istable( spawnlist ) or next( spawnlist ) == nil then return end

    for _, list in ipairs( spawnlist ) do
        if not istable( list ) then
            print( "primitive spawnmenu badlist" )
            goto BADLIST
        end

        for _, info in ipairs( list ) do
            if not istable( info ) or not isstring( info.category ) or not isstring( info.title ) or not isstring( info.command ) then
                print( "primitive spawnmenu badinfo1" )
                goto BADINFO
            end

            if not isstring( info.entity ) or not scripted_ents.IsBasedOn( info.entity, "primitive_base" ) then
                print( "primitive spawnmenu badinfo2" )
                goto BADINFO
            end

            if not categories[info.category] then
                categories[info.category] = node:AddNode( info.category, "icon16/bullet_white.png" )
                categories[info.category].Icon:SetImageColor( Color( 18, 149, 241 ) )
            end

            local admin = scripted_ents.GetMember( info.entity, "AdminOnly" )
            local spawn = categories[info.category]:AddNode( info.title, admin and "icon16/shield.png" or "icon16/bullet_white.png" )
            if not admin then spawn.Icon:SetImageColor( Color( 18, 149, 241 ) ) else spawn:SetTooltip( "admin only" ) end

            spawn.DoClick = function()
                LocalPlayer():ConCommand( string.format( "primitive_spawn %s %s", info.entity, info.command ) )
                surface.PlaySound( "ui/buttonclickrelease.wav" )
            end

            ::BADINFO::
        end

        ::BADLIST::
    end

    -- sketchy hack to sort category nodes alphabetically
    -- there is a MoveToTop method on DTree_Node but it calls a non-existant method on DListLayout and has never worked

    for _, child in SortedPairs( categories ) do

        -- unset the parent, which triggers OnChildRemoved ( DListLayout )

        child:SetParent( nil )

        -- set the parent again, which triggers OnChildAdded ( DListLayout )
        -- this handles the dock and dragndrop functions internally

        child:SetParent( node.ChildNodes )
    end

    node:ExpandRecurse( tobool( cookie.GetNumber( "PrimitiveMenuExpand", 0 ) ) )
end

hook.Add( "PopulateContent", "Primitive_CreateMenu", function( _, tree )
    if IsValid( Primitive_SpawnMenu ) then
        Primitive_SpawnMenu:Remove()
    end

    Primitive_SpawnMenu = tree:AddNode("")

    refresh( Primitive_SpawnMenu )
end )

hook.Add( "Primitive_RefreshMenu", "Primitive_RefreshMenu", function()
    if not IsValid( Primitive_SpawnMenu ) or Primitive_SpawnMenu.m_SetRefresh then
        return
    end

    Primitive_SpawnMenu.m_SetRefresh = true

    timer.Simple( 0, function()
        refresh( Primitive_SpawnMenu )
    end )
end )

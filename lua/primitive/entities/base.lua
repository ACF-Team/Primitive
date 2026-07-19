local entMeta = FindMetaTable( "Entity" )
local entIsDormant = entMeta.IsDormant
local entGetTable = entMeta.GetTable

local CLIENT = CLIENT
local SERVER = SERVER

local class = { Type = "anim", Base = "base_anim", Spawnable = false, AdminOnly = true, IsPrimitive = true }


function class:PrimitivePostEntityPaste( ply, ent, createdEntities )
    self:SetPrimDEBUG( 0 )
end

function class:PrimitiveSetupDataTables()
end


function class:PrimitivePostNetworkNotify( name, old, new )
end


function class:PrimitiveGetConstruct()
end


function class:PrimitiveOnSetup( initial, args )
end


function class:EditorCallback( editor, name, val )
end


function class:PrimitiveSetup( initial, args )
    self:SetPrimMESHENUMS( bit.bor( 1, 1 ) )
    self:SetPrimMESHUV( 48 )
    self:SetPrimMESHPHYS( true )

    self:PrimitiveOnSetup( initial, args )
end


function class:SetupDataTables()
    self.primitive = { keys = {}, vdt = { index = {}, order = 0 }, init = SysTime() }

    self:PrimitiveVar( "PrimDEBUG", "Int", { global = true, category = "debug", title = "overlays", panel = "bitfield", lbl = { "hitbox", "vertex", "convex" } }, self.NotifyDebugDisplay )

    self:PrimitiveVar( "PrimMESHSMOOTH", "Int", { global = true, category = "mesh", title = "normals", panel = "int", min = 0, max = 90 }, true )
    self:PrimitiveVar( "PrimMESHUV", "Int", { global = true, category = "mesh", title = "uv size", panel = "int", min = 8, max = 512 }, true )
    self:PrimitiveVar( "PrimMESHENUMS", "Int", { global = true, category  = "mesh", title = "options", panel = "bitfield", num = 3, lbl = { "bumpmap", "inside", "invert" } }, true )

    self:PrimitiveVar( "PrimMESHPHYS", "Bool", { global = true, category = "model", title = "physics", panel = "bool" }, true )
    self:PrimitiveVar( "PrimMESHPOS", "Vector", { global = true, category = "model", title = "offset", panel = "vector", min = Vector( -500, -500, -500 ), max = Vector( 500, 500, 500 ) }, true )
    self:PrimitiveVar( "PrimMESHROT", "Angle", { global = true, category = "model", title = "rotate", panel = "angle" }, true )

    -- Tell improved clipping we are responsible for maintaining the mesh and its clips.
    self.ImprovedClippingExternalMesh = true

    self:PrimitiveSetupDataTables()
end


function class:PrimitiveGetConstructSimple( name )
    local keys = self:PrimitiveGetKeys()

    -- Bake any improved clips in as entity-local planes.
    if ImprovedClipping then
        local clips = ImprovedClipping.GetClips( self )

        if clips[1] then
            local param = {}
            for k, v in pairs( keys ) do param[k] = v end

            local planes = {}
            for i = 1, #clips do
                local clip = clips[i]
                planes[i] = {
                    pos = clip.Normal * clip.Distance,
                    normal = clip.Normal,
                    seal = clip.Seal ~= false,
                }
            end
            param.clips = planes

            return Primitive.construct.get( name, param, CLIENT, param.PrimMESHPHYS )
        end
    end

    return Primitive.construct.get( name, keys, CLIENT, keys.PrimMESHPHYS )
end


if SERVER then

    local constraint, duplicator =
          constraint, duplicator

    local function getmass( self )
        local mass = self.EntityMods and self.EntityMods.mass and self.EntityMods.mass.Mass

        if not mass then
            local phys = self:GetPhysicsObject()
            return phys:IsValid() and phys:GetMass()
        end

        return tonumber( mass ) or 1
    end


    local function getphysprop( self )
        return self.BoneMods and self.BoneMods[0] and self.BoneMods[0].physprops
    end


    local function getconstraints( self )
        local constraints = {}

        for _, constr in pairs( constraint.GetTable( self ) ) do
            table.insert( constraints, constr )
        end

        constraint.RemoveAll( self )

        self.Constraints = nil
        self.ConstraintSystem = nil

        if next( constraints ) == nil then return else return constraints end
    end


    local function setconstraints( self, constraints )
        for _, constr in pairs( constraints ) do
            local factory = duplicator.ConstraintType[constr.Type]

            if not factory then
                break
            end

            local args = {}
            for i = 1, #factory.Args do
                args[i] = constr[factory.Args[i]]
            end

            factory.Func( unpack( args ) )
        end
    end


    function class:PrimitiveGetProperties()
        local props = {}

        props.parent = self:GetParent():IsValid() and self:GetParent() or nil
        props.mass = getmass( self )
        props.physprop = getphysprop( self )
        props.constraints = getconstraints( self )

        return props
    end


    function class:PrimitiveSetProperties( props )
        if self.m_bIgnoreSetProperties then
            self.m_bIgnoreSetProperties = nil
            return
        end

        if not istable( props ) then return end

        local physobj = self:GetPhysicsObject()
        if not IsValid( physobj ) then return end

        if isnumber( props.mass ) then physobj:SetMass( props.mass ) end
        if istable( props.physprop ) then
            if isbool( props.physprop.Gravity ) then physobj:EnableGravity( props.physprop.Gravity ) end
            if isstring( props.physprop.Material ) then physobj:SetMaterial( props.physprop.Material ) end
        end

        if isentity( props.parent ) and props.parent:IsValid() then
            physobj:EnableMotion(true)
            physobj:Sleep()
            self:SetUnFreezable(true)

        else
            physobj:EnableMotion(false)
            physobj:Sleep()
            self:SetUnFreezable(false)

        end

        if not istable( props.constraints ) then return end

        timer.Simple( 0, function()
            if not self or not self:IsValid() or not self:GetPhysicsObject():IsValid() then return end
            setconstraints( self, props.constraints )
        end )
    end

end

local function rescale( self, scalar )
    scalar = math.Clamp( math.abs( scalar ), 0, 1 )
    if scalar == 0 or scalar == 1 then return end

    local convexes = self:GetPhysicsObject():GetMeshConvexes()

    for i = 1, #convexes do
        local convex = convexes[i]

        for j = 1, #convex do
            local vertex = convex[j].pos

            vertex.x = vertex.x * scalar
            vertex.y = vertex.y * scalar
            vertex.z = vertex.z * scalar

            convex[j] = vertex
        end
    end

    return convexes
end

function class:PrimitiveRebuildPhysics( result )
    local props
    if SERVER then
        props = self:PrimitiveGetProperties()
        hook.Run( "Primitive_PreRebuildPhysics", self, props )
    end

    if not istable( result ) then result = {} end

    local cphysics
    if istable( result.convexes ) and istable( result.convexes[1] ) then
        cphysics = self:PhysicsInitMultiConvex( result.convexes )

        if not cphysics then
            Primitive.funcs.log( self, "invalid convexes" )
        end
    end

    -- if cphysics then
    --     local scaled = rescale( self, self:GetModelScale() )
    --     if scaled ~= nil then
    --         cphysics = self:PhysicsInitMultiConvex( scaled )
    --     end
    -- end

    if cphysics then
        self.m_bCustomCollisions = true

        self:EnableCustomCollisions( true )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
    else
        self.m_bCustomCollisions = nil

        local b = bit.bor( FSOLID_CUSTOMRAYTEST, FSOLID_CUSTOMBOXTEST )
        if bit.band( self:GetSolidFlags(), b ) == b then
            -- using VPHYSICS, only initialize on server

            self:EnableCustomCollisions( false )
            self:PhysicsDestroy()

            if SERVER then
                self:PhysicsInit( SOLID_VPHYSICS )
                self:SetMoveType( MOVETYPE_VPHYSICS )
                self:SetSolid( SOLID_VPHYSICS )
            end
        end
    end

    if SERVER then
        props = istable( props ) and props or {}

        -- you can modify the passed properties table
        -- or also set self.m_bIgnoreSetProperties = true
        -- if you want to prevent PrimitiveSetProperties from doing anything

        hook.Run( "Primitive_PostRebuildPhysics", self, props )

        self:PrimitiveSetProperties( props )
    end
end


local function constructFromTable( self, result )
    self:PrimitiveRebuildPhysics( result )

    if CLIENT then
        self:SetRenderMesh( result )
    end
end


function class:PrimitiveReconstruct()
    local valid, result = self:PrimitiveGetConstruct()

    if not valid or not result then
        Primitive.funcs.log( self, "invalid primitive" )
        Primitive.funcs.log( self, "aborting reconstruction" )

        return
    end

    if istable( result ) then
        constructFromTable( self, result )

        return
    end

    if not result or type( result ) ~= "thread" then
        Primitive.funcs.log( self, "invalid thread" )

        return
    end

    self:PrimitiveSetThread( result )
end


local updateTime = GetConVar( "primitive_update_delay" )
local threadTime = GetConVar( "primitive_thread_runtime" )

local function resume( self )
    local t = SysTime()

    while SysTime() - t < 0.0015 do --threadTime:GetFloat() do
        local success, err, result = coroutine.resume( self.primitive.thread )

        if not success or ( err and not result ) then
            Primitive.funcs.log( self, "invalid thread" )
            print( success, err, result )

            self.primitive.thread = nil
            return true
        end

        if err and result then
            constructFromTable( self, result )

            self.primitive.thread = nil
            return true
        end
    end

    return false
end

local queue, overlay

if CLIENT then

    hook.Add( "HUDPaint", "Primitive_Async_Overlay", function()
        if overlay then
            if not IsValid( overlay ) then overlay = nil return end

            local pos = overlay:GetPos():ToScreen()
            draw.SimpleText( "Generating primitive...", "DermaDefault", pos.x, pos.y, color_white )
        end
    end )

end

hook.Add( "Think", "Primitive_Async_Generation", function()
    if not queue then
        return
    end

    if next( queue ) == nil then
        queue = nil
        return
    end

    local ent = next( queue )
    overlay = ent

    if not IsValid( ent ) or not istable( ent.primitive ) or type( ent.primitive.thread ) ~= "thread" then
        queue[ent] = nil
        overlay = nil

        return
    end

    if resume( ent ) then
        queue[ent] = nil
        overlay = nil
    end
end )

function class:PrimitiveSetThread( result )
    self.primitive.thread = result

    if not queue then queue = {} end
    queue[self] = true
end

function class:Think()
    if CLIENT and entIsDormant( self ) then return end

    local entTable = entGetTable( self )
    if entTable.primitive.init then
        if entTable.PRIMITIVE_FROM_DUPE then
            return
        end

        if SysTime() - entTable.primitive.init > updateTime:GetFloat() then
            self:PrimitiveReconstruct()
            self.primitive.init = nil
        end
    end

    if CLIENT and entTable.m_bCustomCollisions then

        -- workaround for clientside physics bug
        -- https://github.com/Facepunch/garrysmod-issues/issues/5060

        local physobj = self:GetPhysicsObject()

        if physobj:IsValid() then
            physobj:EnableMotion( false )
            physobj:SetPos( self:GetPos() )
            physobj:SetAngles( self:GetAngles() )
        end
    end
end


function class:Initialize()
    if SERVER then
        self:SetModel( "models/combine_helicopter/helicopter_bomb01.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
    end
end


--[[

    Convenience wrapper for NetworKVars

]]

do

    local typefilter = {}

    local inf = math.huge
    local nan = tostring( 0 / 0 )

    local function isinf( n )
        if n == inf then return true end
        if n == -inf then return true end
        return false
    end

    local function isnan( n )
        if isinf( n ) then return true end
        return tostring( n ) == nan
    end

    typefilter.Float = function( self, data, new )
        if isnan( new ) then return true, 0 end
        if data.min and new < data.min then return true, data.min end
        if data.max and new > data.max then return true, data.max end

        return false, new
    end

    typefilter.Int = function( self, data, new )
        local _, val = typefilter.Float( self, data, new )
        val = math.floor( val )

        return new ~= val, val
    end

    typefilter.Vector = function( self, data, new )
        if isnan( new.x ) then new.x = 0 end
        if isnan( new.y ) then new.y = 0 end
        if isnan( new.z ) then new.z = 0 end

        if data.min then
            if new.x < data.min.x then new.x = data.min.x end
            if new.y < data.min.y then new.y = data.min.y end
            if new.z < data.min.z then new.z = data.min.z end
        end
        if data.max then
            if new.x > data.max.x then new.x = data.max.x end
            if new.y > data.max.y then new.y = data.max.y end
            if new.z > data.max.z then new.z = data.max.z end
        end

        return false, new
    end

    typefilter.Angle = function( self, data, new )
        if isnan( new.p ) then new.p = 0 end
        if isnan( new.y ) then new.y = 0 end
        if isnan( new.r ) then new.r = 0 end

        if data.min then
            if new.p < data.min.p then new.p = data.min.p end
            if new.y < data.min.y then new.y = data.min.y end
            if new.r < data.min.r then new.r = data.min.r end
        end
        if data.max then
            if new.p > data.max.p then new.p = data.max.p end
            if new.y > data.max.y then new.y = data.max.y end
            if new.r > data.max.r then new.r = data.max.r end
        end

        return false, new
    end

    local function screenPrimitiveVar( self, name, new )
        local edit = self:GetEditingData()
        local data = edit and edit[name]

        -- do nothing if editing data does not exist for var
        -- should never happen

        if not data then
            return false, new
        end

        -- exists in entity vfilter list

        local filter = self.primitive.vfilters and self.primitive.vfilters[name]

        -- exists in typefilter list

        if not filter then
            filter = typefilter[data.typename]
        end

        if not filter then
            return false, new
        end

        return filter( self, data, new )
    end


    local function notifyPrimitiveVar( self, name, old, new )
        -- some garry shenaniganary may lead to double triggers

        if old == nil or old == new then return end

        -- we don't care what the actual NWVar is since this
        -- callback is ran before it changes, and there's nothing we can do about it

        local bad, val = screenPrimitiveVar( self, name, new )

        -- so we just set a clamped value to a table that
        -- gets sent to construct.lua instead

        self.primitive.keys[name] = val

        -- and then call this function if it needs to be further
        -- modified per entity

        self:PrimitivePostNetworkNotify( name, val )

        -- tell the entity to queue a rebuild

        self.primitive.init = SysTime()
    end


    function class:PrimitiveGetKeys()
        return self.primitive.keys
    end


    function class:PrimitiveVar( name, typename, edit, onNotify )
        -- the point of this function is to avoid setting
        -- the slot and order manually, because it's annoying

        self.primitive.vdt.index[typename] = ( self.primitive.vdt.index[typename] or -1 ) + 1
        self.primitive.vdt.order = self.primitive.vdt.order + 1

        edit.typename = typename
        edit.order = edit.order or self.primitive.vdt.order

        if edit.title then
            edit.title = string.lower( edit.title )
        end

        if edit.category then
            edit.category = string.lower( edit.category )
        end

        -- create the var, why is this KeyName stuff neccesary, garry?

        self:NetworkVar( typename, self.primitive.vdt.index[typename], name, { KeyName = name, Edit = edit } )

        if onNotify == true then
            -- use default callback if true

            self:NetworkVarNotify( name, notifyPrimitiveVar )

             -- call it once to set the key value for construct.lua

            notifyPrimitiveVar( self, name, self, self["Get" .. name]( self ) )

        elseif isfunction( onNotify ) then
            self:NetworkVarNotify( name, onNotify )

            onNotify( self, name, self, self["Get" .. name]( self ) )

        end
    end

    function class:PostEntityPaste( ply, ent, createdEntities )
        self:PrimitivePostEntityPaste( ply, ent, createdEntities )

        if self.PRIMITIVE_FROM_DUPE then

            -- dupe bug only affects parented primitives
            -- if parented, delay the initialization

            self.PRIMITIVE_FROM_DUPE = nil
            self.primitive.init = SysTime() + 1
        end
    end

    function class:OnDuplicated( tbl )
        if istable( tbl ) and istable( tbl.BuildDupeInfo ) and isnumber( tbl.BuildDupeInfo.DupeParentID ) then

            -- dupe bug only affects parented primitives
            -- if parented, delay the initialization

            self.PRIMITIVE_FROM_DUPE = true
        end
    end

    hook.Add( "AdvDupe_FinishPasting", "Primitive_FinishPasting", function( data )
        if not istable( data ) or not istable( data[1] ) or not istable( data[1].CreatedEntities ) then return end

        local t = SysTime() + 1

        for _, ent in pairs( data[1].CreatedEntities ) do
            if ent.IsPrimitive and istable( ent.primitive ) then
                --ent:PrimitiveReconstruct()

                ent.PRIMITIVE_FROM_DUPE = nil
                ent.primitive.init = t
            end
        end
    end)

    -- Rebuild on clip changes so the new planes get baked in ( see PrimitiveGetConstructSimple ).
    -- The hook only exists when Improved Clipping is installed, so neither addon depends on the other.
    hook.Add( "ImprovedClipping_ClipsChanged", "Primitive_ImprovedClipping", function( ent )
        if ent.IsPrimitive and istable( ent.primitive ) then
            ent:PrimitiveReconstruct()
        end
    end )
end


if CLIENT then

    function class:OnDrawDebug()
    end

    function class:GetRenderMesh()
        return self.primitive.renderMesh
    end


    function class:Draw()
        self:DrawModel()
    end


    function class:OnRemove()
        local mesh = isfunction( self.GetRenderMesh ) and self:GetRenderMesh()
        if not istable( mesh ) then return end

        timer.Simple( 0, function()
            if self and self:IsValid() then
                return
            end

            if mesh.Mesh and mesh.Mesh:IsValid() then
                mesh.Mesh:Destroy()
                mesh.Mesh = nil
            end
        end )
    end


    local baseMaterial = Material( "hunter/myplastic" )
    local ___error = Material( "___error" )
    local ___physics = CreateMaterial( "primitivephyswireframe", "Wireframe_DX9", {} )
    ___physics:SetVector( "$color", Vector( 1, 1, 1 ) )

    local dbg_g = Color( 0, 255, 0 )
    local dbg_r = Color( 255, 0, 0 )
    local dbg_b = Color( 0, 0, 255 )
    local dbg_y = Color( 255, 255, 0, 50 )
    local dbg_text = Color( 255, 255, 255, 255 )
    local dbg_vertex = Color( 255, 255, 0, 255 )

    local cam, surface, render = cam, surface, render
    local WorldToLocal, LocalToWorld = WorldToLocal, LocalToWorld

    local function getphysmesh( self )
        local physmesh = self:GetPhysicsObject():IsValid() and self:GetPhysicsObject():GetMesh()
        if not istable( physmesh ) or #physmesh < 3 then return end

        self.primitive.physmesh = Mesh( ___physics )
        self.primitive.physmesh:BuildFromTriangles( physmesh )
    end


    function class:DrawNormal()
        self:DrawModel()
    end


    function class:DrawDebug()
        if self.debugConvex and self.primitive.physmesh and self.primitive.physmesh:IsValid() then
            cam.PushModelMatrix( self:GetWorldTransformMatrix() )

            render.SetBlend( 0.25 )
            render.SetColorModulation( 1, 0, 1 )
            render.SetMaterial( ___physics )
            self.primitive.physmesh:Draw()
            render.SetColorModulation( 1, 1, 1 )
            render.SetBlend( 1 )

            cam.PopModelMatrix()
        end

        if self.primitive.renderMesh then
            self:DrawModel()
        end

        local pos = self:GetPos()
        local ang = self:GetAngles()

        if self.debugHitbox then
            render.DrawLine( pos, pos + ang:Forward()*6, dbg_g )
            render.DrawLine( pos, pos + ang:Right()*6, dbg_r )
            render.DrawLine( pos, pos + ang:Up()*6, dbg_b )

            local min, max = self:GetRenderBounds() --self:GetCollisionBounds()
            render.DrawWireframeBox( pos, ang, min, max, dbg_y )
        end

        if self.debugVertex and self.primitive.result and self.primitive.result.verts then
            cam.Start2D()

            surface.SetFont( "DermaDefaultBold" )
            surface.SetTextColor( dbg_vertex )
            surface.SetDrawColor( dbg_vertex )

            local vertices = self.primitive.result.verts
            local vertcount = #vertices

            for i = 1, vertcount do
                local pos = LocalToWorld( vertices[i], ang, pos, ang ):ToScreen()

                surface.SetTextPos( pos.x, pos.y )
                surface.DrawText( i )
                surface.DrawRect( pos.x, pos.y, 2, 2 )
            end

            cam.End2D()
        end

        self:OnDrawDebug()
    end


    function class:DrawError()
        render.ModelMaterialOverride( ___error )
        self:DrawModel()
        render.ModelMaterialOverride( nil )
    end


    local function renderBounds( self, result )
        local mins = result.mins
        local maxs = result.maxs

        if not mins or not maxs then
            mins, maxs = self:GetCollisionBounds()
        end

        if not mins or not maxs then return end

        if mins.x > 0 then mins.x = 0 end
        if mins.y > 0 then mins.y = 0 end
        if mins.z > 0 then mins.z = 0 end
        if maxs.x < 0 then maxs.x = 0 end
        if maxs.y < 0 then maxs.y = 0 end
        if maxs.z < 0 then maxs.z = 0 end

        self:SetRenderBounds( mins, maxs )
    end


    function class:SetRenderMesh( result )
        if self.primitive.renderMesh and IsValid( self.primitive.renderMesh.Mesh ) then
            self.primitive.renderMesh.Mesh:Destroy()
            self.primitive.renderMesh = nil
        end

        self.Draw = self.DrawNormal
        self.primitive.result = result

        if istable( result ) and istable( result.tris ) and #result.tris >= 3 then
            self.primitive.renderMesh = { Mesh = Mesh(), Material = self.baseMaterial or baseMaterial }
            self.primitive.renderMesh.Mesh:BuildFromTriangles( result.tris )

            if result.error then
                self.Draw = self.DrawError
            else
                self:SetDrawFunction()
            end

            renderBounds( self, result )
        else
            Primitive.funcs.log( self, "invalid mesh" )

            self:SetDrawFunction()
        end
    end


    function class:NotifyDebugDisplay( _, old, new )
        self:SetDrawFunction( new )
    end


    local ENUM_HITBOX = 1
    local ENUM_VERTEX = 2
    local ENUM_CONVEX = 4

    function class:SetDrawFunction( bits )
        if self.Draw == self.DrawError then return end

        self.Draw = self.DrawNormal

        if CPPI and LocalPlayer() ~= self:CPPIGetOwner() then return end

        if not bits then bits = self:GetPrimDEBUG() or 0 end

        self.debugHitbox = bit.band( bits, ENUM_HITBOX ) == ENUM_HITBOX
        self.debugVertex = bit.band( bits, ENUM_VERTEX ) == ENUM_VERTEX
        self.debugConvex = bit.band( bits, ENUM_CONVEX ) == ENUM_CONVEX

        if self.debugHitbox or self.debugVertex or self.debugConvex then
            if self.debugConvex then
                getphysmesh( self )
            end

            self.Draw = self.DrawDebug
        else
            if self.primitive.physmesh and self.primitive.physmesh:IsValid() then
                self.primitive.physmesh:Destroy()
            end
            self.primitive.physmesh = nil
        end
    end

end


scripted_ents.Register( class, "primitive_base" )


local CreateEntity

local function capitalize( s )
    return string.upper( string.sub( s, 1, 1 ) ) .. string.sub( s, 2 )
end

function Primitive.funcs.registerClass( name, class, spawnlist )
    class.Type = "anim"
    class.Base = "primitive_base"

    class.Name = string.lower( name )
    if not string.StartWith( class.Name, "primitive_" ) then class.Name = "primitive_" .. class.Name end

    class.PrintName = string.gsub( string.gsub( class.Name, "_", " " ), "%a[^%s]*", capitalize )

    if class.AdminOnly == nil then class.AdminOnly = false end

    scripted_ents.Register( class, class.Name )

    Primitive.classes[class.Name] = spawnlist or true

    if SERVER then
        duplicator.RegisterEntityClass( class.Name, function( ply, data )
            if not ply:CheckLimit( "props" ) then return false end

            return CreateEntity( class.Name, ply, data )
        end, "Data" )
    else
        killicon.AddAlias( class.Name, "prop_physics" )

        hook.Run( "Primitive_RefreshMenu" )
    end
end

if CLIENT then
    hook.Add( "Primitive_PreRefreshMenu", "Primitive_AddSpawnlists", function( globalSpawnlist )
        for _class, spawnlist in pairs( Primitive.classes ) do
            -- for _, entry in pairs( spawnlist ) do
            --     table.insert( globalSpawnlist, entry )
            -- end

            table.insert( globalSpawnlist, spawnlist )
        end
    end )
end

if SERVER then
    function CreateEntity( class, ply, data )
        local ent = ents.Create( class )
        if not IsValid( ent ) then return false end

        if istable( data ) then
            duplicator.DoGeneric( ent, data )

            -- parenting sometimes messes up the physics objects on larger dupes, this prevents those primitives
            -- from updating until the entire dupe is finished pasting

            -- if istable( data.BuildDupeInfo ) and isnumber( data.BuildDupeInfo.DupeParentID ) then
            --     ent.PRIMITIVE_HALT_UPDATE = true
            -- end
        end

        ent:Spawn()
        ent:Activate()

        if IsValid( ply ) then
            ent:SetVar( "Player", ply )
            ply:AddCount( "props", ent )
        end

        return ent
    end

    concommand.Add( "primitive_spawn", function( ply, _, args )
        if not IsValid( ply ) or not Primitive or not Primitive.classes then return end

        local class = table.remove( args, 1 )
        if not Primitive.classes[class] then return end

        if not scripted_ents.GetStored( class ) or ( scripted_ents.GetMember( class, "AdminOnly" ) and not ply:IsAdmin() ) then return end
        if not gamemode.Call( "PlayerSpawnProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl" ) then return end

        local ent = CreateEntity( class, ply )
        if not ent then return end

        local tr = util.TraceLine( { start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 4096, filter = ply } )
        if not tr.Hit then return end

        local ang
        if math.abs( tr.HitNormal.x ) < 0.001 and math.abs( tr.HitNormal.y ) < 0.001 then
            ang = Vector( 0, 0, tr.HitNormal.z ):Angle()
        else
            ang = tr.HitNormal:Angle()
        end
        ang.p = ang.p + 90

        ent:SetAngles( ang )
        ent:SetPos( tr.HitPos + ang:Up() * 36 )

        gamemode.Call( "PlayerSpawnedProp", ply, "models/combine_helicopter/helicopter_bomb01.mdl", ent )

        undo.Create( "primitive" )
            undo.SetPlayer( ply )
            undo.AddEntity( ent )
            undo.SetCustomUndoText( string.format( "Undone primitive ( %s )", class ) )
        undo.Finish( string.format( "primitive ( %s )", class ) )

        ply:AddCleanup( "primitive", ent )

        DoPropSpawnedEffect( ent )

        if isfunction( ent.PrimitiveSetup ) then
            ent:PrimitiveSetup( true, args )
        end
    end )
end


do
    local output

    local function printLog()
        MsgC( Color( 255, 255, 0 ), "Primitive Log -> " .. os.date( "%H:%M:%S - %d/%m/%Y", os.time() ), "\n" )

        for ent, msg in pairs( output ) do
            if IsValid( ent ) then
                if CPPI then
                     Msg( "\t" )
                     MsgC( color_white, tostring( ent:CPPIGetOwner() ), "\n" )
                end

                Msg( "\t" )
                MsgC( color_white, tostring( ent ), "\n" )

                local red = Color( 255, 0, 0 )
                local err

                for i = 1, #msg do
                    if msg[i] == true then
                        err = true
                    else
                        Msg( "\t\t" )
                        MsgC( err and red or color_white, msg[i], "\n" )
                        err = nil
                    end
                end
            end
        end

        output = nil

        timer.Remove( "primitive_log" )
    end


    Primitive.funcs.log = function( ent, msg, err )
        if not output then output = {} end

        if not output[ent] then output[ent] = {} end

        output[ent][#output[ent] + 1] = err
        output[ent][#output[ent] + 1] = string.format( "%s", msg )

        if not timer.Exists( "primitive_log" ) then
            timer.Create( "primitive_log", 0.015, 1, printLog )
            return
        end

        timer.Adjust( "primitive_log", 0.015 )
    end
end

cleanup.Register("primitive")

CreateConVar( "primitive_update_delay", 0.015, { FCVAR_ARCHIVE }, "update delay in seconds, lower is faster", 0.0015, 0.5 )
CreateConVar( "primitive_thread_runtime", 0.25, { FCVAR_ARCHIVE }, "max thread runtime in seconds, higher is faster", 0.0015, 0.5 )

Primitive = { funcs = {}, classes = {} }
Primitive.minSize = 0.4

if SERVER then
    AddCSLuaFile( "primitive/load.lua" )
end

include( "primitive/load.lua" )


--[[
    HOOK: "Primitive_PreRebuildPhysics"
    DESC: called before physics are rebuilt

    hook.Add( "Primitive_PreRebuildPhysics", "", function( self, properties )

        properties is a table that can contain
            .mass (number)
            .physprop (table)
                .Gravity (number)
                .Material (string)
            .constraints (table)

    end )


    HOOK: "Primitive_PostRebuildPhysics"
    DESC: called after physics are rebuilt but before properties are restored

    hook.Add( "Primitive_PostRebuildPhysics", "", function( self, properties )

        -- you can modify the table passed to PrimitiveSetProperties
        if properties.mass and properties.mass > 1000 then
            properties.mass = 1000
        end

        -- or set this to true to prevent PrimitiveSetProperties, so you can use your own function here
        self.m_bIgnoreSetProperties = true
        SomeFunction( self )

    end )


    HOOK: "Primitive_PreRefreshMenu"
    DESC: adds spawn node to left spawnmenu, called when an entity is registered and on gamemode load

    hook.Add( "Primitive_PreRefreshMenu", "", function( globalSpawnlist )

        table.insert( globalSpawnlist, {
            { category = "shapes", entity = "primitive_shape", title = "dome", command = "dome 1 48" },
            { category = "shapes", entity = "primitive_shape", title = "pyramid", command = "pyramid 1 48" },
            { category = "shapes", entity = "primitive_shape", title = "sphere", command = "sphere 1 48" },
            { category = "shapes", entity = "primitive_shape", title = "torus", command = "torus 1 48" },
        } )

    end )
]]

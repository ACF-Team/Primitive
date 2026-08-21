
-- PROTOTYPE: a convex volume from a vertex count (4-10) and free XYZ per vertex; the render mesh is rebuilt from the physics engine's own computed hull.

do
    local class = {}

    -- Alternates Z so the default ring isn't coplanar (a flat ring is a degenerate zero-volume convex).
    local function ringDefault( i, n )
        local a = ( math.pi * 2 / n ) * ( i - 1 )
        local z = ( i % 2 == 0 ) and 24 or -24
        return Vector( math.cos( a ) * 48, math.sin( a ) * 48, z )
    end

    -- Sets keys.skip_tris since there's nothing to triangulate until physics exists (see SetRenderMesh).
    function class:PrimitiveGetConstruct()
        local keys = self:PrimitiveGetKeys()
        keys.skip_tris = true

        local clips = ImprovedClipping and ImprovedClipping.GetClips( self )
        local valid, result = Primitive.construct.get( "convex_hull", keys, CLIENT, keys.PrimMESHPHYS, clips )

        self.ImprovedClippingAllowSeal = not ( istable( result ) and result.multiConvex )

        return valid, result
    end


    if CLIENT then
        function class:SetRenderMesh( result )
            if istable( result ) and not result.error then
                local physobj = self:GetPhysicsObject()

                if physobj:IsValid() then
                    local convexes = physobj:GetMeshConvexes()

                    if istable( convexes ) then
                        local verts, index = {}, {}

                        -- Swap the last two verts of each triangle to match Build()'s winding, or the hull renders inside-out.
                        for i = 1, #convexes do
                            local convex = convexes[i]

                            for j = 1, #convex, 3 do
                                local a = #verts + 1

                                verts[a] = Vector( convex[j].pos )
                                verts[a + 1] = Vector( convex[j + 1].pos )
                                verts[a + 2] = Vector( convex[j + 2].pos )

                                index[#index + 1] = a
                                index[#index + 1] = a + 2
                                index[#index + 1] = a + 1
                            end
                        end

                        if #index >= 3 then
                            result.verts = verts
                            result.index = index

                            result:Build( self:PrimitiveGetKeys(), false, true )
                        end
                    end
                end
            end

            self.BaseClass.SetRenderMesh( self, result )
        end
    end


    function class:PrimitiveOnSetup( initial, args )
        if initial and SERVER then
            duplicator.StoreEntityModifier( self, "mass", { Mass = 100 } )
        end

        self:SetPrimPOINTS( 6 )

        for i = 1, 10 do
            local p = ringDefault( i, 10 )

            self[ "SetPrimPX" .. i ]( self, p.x )
            self[ "SetPrimPY" .. i ]( self, p.y )
            self[ "SetPrimPZ" .. i ]( self, p.z )
        end

        self:SetPrimMESHPHYS( true )
    end


    function class:PrimitiveSetupDataTables()
        self:PrimitiveVar( "PrimPOINTS", "Int", { category = "hull", title = "point count", panel = "int", min = 4, max = 10 }, true )

        for i = 1, 10 do
            self:PrimitiveVar( "PrimPX" .. i, "Float", { category = "points", subcategory = "point " .. i, title = "point " .. i .. " x", panel = "float", min = -1000, max = 1000 }, true )
            self:PrimitiveVar( "PrimPY" .. i, "Float", { category = "points", subcategory = "point " .. i, title = "point " .. i .. " y", panel = "float", min = -1000, max = 1000 }, true )
            self:PrimitiveVar( "PrimPZ" .. i, "Float", { category = "points", subcategory = "point " .. i, title = "point " .. i .. " z", panel = "float", min = -1000, max = 1000 }, true )
        end
    end


    local spawnlist
    if CLIENT then
        spawnlist = {
            { category = "shapes_extra", entity = "primitive_convex_hull", title = "convex hull", command = "" },
        }

        local callbacks = {
            EDITOR_OPEN = function( self, editor, name, val )
                for k, cat in pairs( editor.categories ) do
                    if k == "debug" or k == "mesh" or k == "model" then cat:ExpandRecurse( false ) else cat:ExpandRecurse( true ) end
                end
            end,

            PrimPOINTS = function( self, editor, name, val )
                for i = 1, 10 do
                    local visible = i <= val

                    for _, axis in ipairs( { "X", "Y", "Z" } ) do
                        local row = editor.rows[ "PrimP" .. axis .. i ]
                        if row then row:SetVisible( visible ) end
                    end
                end
            end,
        }

        function class:EditorCallback( editor, name, val )
            if callbacks[name] then callbacks[name]( self, editor, name, val ) end
        end
    end

    Primitive.funcs.registerClass( "convex_hull", class, spawnlist )
end

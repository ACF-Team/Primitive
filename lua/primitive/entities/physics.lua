
do
    local class = {}

    function class:PrimitiveGetConstruct()
        return self:PrimitiveGetConstructSimple( "ladder" )
    end


    function class:PrimitiveSetupDataTables()
        local category = "ladder"

        self:PrimitiveVar( "PrimSOPT", "Int", { category = category, title = "options", panel = "bitfield", lbl = { "solid", "rail_enabled" } }, true )

        self:PrimitiveVar( "PrimSCOUNT", "Int", { category = category, title = "step count", panel = "int", min = 1, max = 32 }, true )
        self:PrimitiveVar( "PrimSHEIGHT", "Float", { category = category, title = "step height", panel = "float", min = 1, max = 50 }, true )
        self:PrimitiveVar( "PrimRDIM", "Vector", { category = category, title = "rung size", panel = "vector", min = Vector( MinSize, MinSize, MinSize ), max = Vector( 1000, 1000, 50 ) }, true )

        self:PrimitiveVar( "PrimXDIM", "Vector", { category = category, title = "rail size", panel = "vector", min = Vector( MinSize, MinSize, 0 ), max = Vector( 1000, 1000, 50 ) }, true )

    end


    function class:PrimitiveOnSetup( initial, args )
        if initial and SERVER then
            duplicator.StoreEntityModifier( self, "mass", { Mass = 100 } )
        end

        self:SetPrimSOPT( bit.bor( 2 ) )

        self:SetPrimSCOUNT( 16 )
        self:SetPrimSHEIGHT( 12 )
        self:SetPrimRDIM( Vector( 1.5, 24, 1 ) )
        self:SetPrimXDIM( Vector( 3, 2, 12 ) )

        local physics, uv = unpack( args )

        if physics ~= nil then self:SetPrimMESHPHYS( tobool( physics ) ) end
        if tonumber( uv ) then self:SetPrimMESHUV( tonumber( uv ) ) end
    end


    local spawnlist
    if CLIENT then
        spawnlist = {
            { category = "physics", entity = "primitive_ladder", title = "ladder", command = "1 48" },
        }

        local callbacks = {
            EDITOR_OPEN = function ( self, editor, name, val )
                for k, cat in pairs( editor.categories ) do
                    if k == "debug" or k == "mesh" or k == "model" then cat:ExpandRecurse( false ) else cat:ExpandRecurse( true ) end
                end
            end,
        }

        function class:EditorCallback( editor, name, val )
            if callbacks[name] then callbacks[name]( self, editor, name, val ) end
        end
    end

    Primitive.funcs.registerClass( "ladder", class, spawnlist )
end


do
    local class = {}

    function class:PrimitiveGetConstruct()
        return self:PrimitiveGetConstructSimple( "staircase" )
    end


    function class:PrimitiveSetupDataTables()
        local category = "staircase"

        self:PrimitiveVar( "PrimSOPT", "Int", { category = category, title = "options", panel = "bitfield", lbl = { "solid" } }, true )
        self:PrimitiveVar( "PrimSCOUNT", "Int", { category = category, title = "step count", panel = "int", min = 1, max = 32 }, true )
        self:PrimitiveVar( "PrimSWIDTH", "Float", { category = category, title = "step width", panel = "float", min = 1, max = 1000 }, true )
        self:PrimitiveVar( "PrimSRISE", "Float", { category = category, title = "rise", panel = "float", min = 1, max = 50 }, true )
        self:PrimitiveVar( "PrimSRUN", "Float", { category = category, title = "run", panel = "float", min = 1, max = 50 }, true )
    end


    function class:PrimitiveOnSetup( initial, args )
        if initial and SERVER then
            duplicator.StoreEntityModifier( self, "mass", { Mass = 100 } )
        end

        self:SetPrimSOPT( 1 )
        self:SetPrimSCOUNT( 16 )
        self:SetPrimSRISE( 7 )
        self:SetPrimSRUN( 11 )
        self:SetPrimSWIDTH( 48 )

        local physics, uv = unpack( args )

        if physics ~= nil then self:SetPrimMESHPHYS( tobool( physics ) ) end
        if tonumber( uv ) then self:SetPrimMESHUV( tonumber( uv ) ) end
    end


    local spawnlist
    if CLIENT then
        spawnlist = {
            { category = "physics", entity = "primitive_staircase", title = "staircase", command = "1 48" },
        }

        local callbacks = {
            EDITOR_OPEN = function ( self, editor, name, val )
                for k, cat in pairs( editor.categories ) do
                    if k == "debug" or k == "mesh" or k == "model" then cat:ExpandRecurse( false ) else cat:ExpandRecurse( true ) end
                end
            end,
        }

        function class:EditorCallback( editor, name, val )
            if callbacks[name] then callbacks[name]( self, editor, name, val ) end
        end
    end

    Primitive.funcs.registerClass( "staircase", class, spawnlist )
end


do
    local class = {}

    function class:PrimitiveGetConstruct()
        return self:PrimitiveGetConstructSimple( "rail_slider" )
    end


    function class:PrimitiveSetupDataTables()
        self:PrimitiveVar( "PrimBASE", "Bool", { category = "base", title = "enabled", panel = "bool" }, true )
        self:PrimitiveVar( "PrimBPOS", "Vector", { category = "base", title = "offset", panel = "vector", min = Vector( -500, -500, -500 ), max = Vector( 500, 500, 500) }, true )
        self:PrimitiveVar( "PrimBDIM", "Vector", { category = "base", title = "size", panel = "vector", min = Vector( MinSize, MinSize, MinSize ), max = Vector( 100, 100, 100) }, true )

        local types = { wedge = "slider_wedge", spike = "slider_spike", cube = "slider_cube", blade = "slider_blade" }
        self:PrimitiveVar( "PrimCTYPE", "String", { category = "contact point", title = "type", panel = "combo", values = types }, true )

        local options = { "front left", "front right", "rear left", "rear right", "double" }
        self:PrimitiveVar( "PrimCENUMS", "Int", { category = "contact point", title = "options", panel = "bitfield", lbl = options }, true )
        self:PrimitiveVar( "PrimCGAP", "Float", { category = "contact point", title = "gap", panel = "float", min = 0, max = 100 }, true )
        self:PrimitiveVar( "PrimCPOS", "Vector", { category = "contact point", title = "offset", panel = "vector", min = Vector( 0, 0, 0 ), max = Vector( 500, 500, 500) }, true )
        self:PrimitiveVar( "PrimCROT", "Angle", { category = "contact point", title = "rotate", panel = "angle" }, true )
        self:PrimitiveVar( "PrimCDIM", "Vector", { category = "contact point", title = "size", panel = "vector", min = Vector( MinSize, MinSize, MinSize ), max = Vector( 100, 100, 100) }, true )

        local types = { wedge = "slider_wedge", spike = "slider_spike", cube = "slider_cube", blade = "slider_blade" }
        self:PrimitiveVar( "PrimFTYPE", "String", { category = "flange", title = "type", panel = "combo", values = types }, true )

        local options = { "front left", "front right", "rear left", "rear right" }
        self:PrimitiveVar( "PrimFENUMS", "Int", { category = "flange", title = "options", panel = "bitfield", lbl = options }, true )
        self:PrimitiveVar( "PrimFGAP", "Float", { category = "flange", title = "width", panel = "float", min = 0, max = 100 }, true )
    end


    function class:PrimitiveOnSetup( initial, args )
        if initial and SERVER then
            duplicator.StoreEntityModifier( self, "mass", { Mass = 100 } )
            duplicator.StoreBoneModifier( self, 0, "physprops", { GravityToggle = true, Material = "gmod_ice" } )
        end

        self:SetPrimBASE( true )
        self:SetPrimBDIM( Vector( 24, 24, 1 ) )

        self:SetPrimCTYPE( "slider_spike" )
        self:SetPrimFTYPE( "slider_spike" )

        self:SetPrimCENUMS( bit.bor( 1, 1, 2, 4, 8 ) )
        self:SetPrimFENUMS( bit.bor( 1, 1, 2, 4, 8 ) )

        self:SetPrimBPOS( Vector( 0, 0, 16 ) )
        self:SetPrimCPOS( Vector( 24, 38, 0 ) )
        self:SetPrimCDIM( Vector( 24, 1, 8 ) )

        self:SetPrimCGAP( 14 )
        self:SetPrimFGAP( 14 )

        self:SetPrimMESHPHYS( true )
    end


    local spawnlist
    if CLIENT then
        class.baseMaterial = Material( "phoenix_storms/iron_rails" )

        spawnlist = {
            { category = "physics", entity = "primitive_rail_slider", title = "rail_slider", command = "" },
        }

        local callbacks = {
            EDITOR_OPEN = function ( self, editor, name, val )
                for k, cat in pairs( editor.categories ) do
                    if k == "debug" or k == "mesh" or k == "model" then cat:ExpandRecurse( false ) else cat:ExpandRecurse( true ) end
                end
            end,

            PrimBASE = function( self, editor, name, val )
                editor:HideRow( "PrimBPOS", tobool( val ) )
                editor:HideRow( "PrimBDIM", tobool( val ) )
            end,

            PrimCENUMS = function( self, editor, name, val )
                local enabled = bit.band( val, bit.bor( 1, 1, 2, 4, 8 ) ) ~= 0
                local double = bit.band( val, 16 ) == 16

                editor:HideRow( "PrimCGAP", enabled and double ) -- double
                editor:HideRow( "PrimCPOS", enabled )
                editor:HideRow( "PrimCROT", enabled )
                editor:HideRow( "PrimCDIM", enabled )

                editor:HideRow( "PrimFGAP", not double )

                if editor.m_bInitialzied then
                    editor:ScrollToChild( editor.categories["contact point"] )
                end
            end,

            PrimFENUMS = function( self, editor, name, val )
                local enabled = bit.band( val, bit.bor( 1, 1, 2, 4, 8 ) ) ~= 0

                if editor.m_bInitialzied then
                    editor:ScrollToChild( editor.categories.flange )
                end
            end,
        }

        function class:EditorCallback( editor, name, val )
            if callbacks[name] then callbacks[name]( self, editor, name, val ) end
        end
    end

    Primitive.funcs.registerClass( "rail_slider", class, spawnlist )
end


--[=====[
do

    --[[
        SPUR GEAR

        it's beautiful
        and unfortunately for now, generation is too expensive to include in the addon
    ]]

    do
        local class = {}

        function class:PrimitiveGetConstruct()
            return self:PrimitiveGetConstructSimple( "gear" )
        end


        function class:PrimitiveSetupDataTables()
            self:PrimitiveVar( "PrimCOUNT", "Int", { category = "gear", title = "tooth count", panel = "int", min = 3, max = 60 }, true )
            self:PrimitiveVar( "PrimMODULE", "Float", { category = "gear", title = "module", panel = "float", min = 1, max = 50 }, true )
            self:PrimitiveVar( "PrimANGLE", "Float", { category = "gear", title = "pressure angle", panel = "float", min = 1, max = 45 }, true )
            self:PrimitiveVar( "PrimHEIGHT", "Float", { category = "gear", title = "height", panel = "float", min = 1, max = 1000 }, true )
        end


        function class:PrimitiveOnSetup( initial, args )
            if initial and SERVER then
                duplicator.StoreEntityModifier( self, "mass", { Mass = 100 } )
                duplicator.StoreBoneModifier( self, 0, "physprops", { GravityToggle = true, Material = "gmod_ice" } )
            end

            self:SetPrimMESHPHYS( true )

            self:SetPrimCOUNT( 20 )
            self:SetPrimMODULE( 7 )
            self:SetPrimANGLE( 20 )
            self:SetPrimHEIGHT( 12 )
        end


        local spawnlist
        if CLIENT then
            class.baseMaterial = Material( "metal6" )

            spawnlist = {
                { category = "physics", entity = "primitive_gear", title = "gear", command = "" },
            }

            local callbacks = {
                EDITOR_OPEN = function ( self, editor, name, val )
                    for k, cat in pairs( editor.categories ) do
                        if k == "debug" or k == "mesh" or k == "model" then cat:ExpandRecurse( false ) else cat:ExpandRecurse( true ) end
                    end
                end,
            }

            function class:EditorCallback( editor, name, val )
                if callbacks[name] then callbacks[name]( self, editor, name, val ) end
            end
        end

        Primitive.funcs.registerClass( "gear", class, spawnlist )
    end

    do

        local function curvePointXY( radius, dist )
            local t = ( math_sqrt( dist * dist - radius * radius ) / radius ) - math_acos( radius / dist )
            return dist * math_cos( t ), dist * math_sin( t )
        end

        local function curvePointW( x, y, dist )
            local len = math_sqrt( x * x + y * y )
            return ( x / len ) * dist, ( y / len ) * dist
        end

        local function curveCenterXY( numTeeth, baseRadius, pitchDiameter )
            local x, y = curvePointXY( baseRadius, pitchDiameter * 0.5 )

            local a = -math_atan( y / x )
            local l = ( ( -math_pi * 2 ) / ( numTeeth * 2 ) ) * 0.5

            return math_cos( a + l ), math_sin( a + l )
        end

        local function curvePoints( numTeeth, detail, height, pitchDiameter, baseDiameter, tipDiameter, rootDiameter )
            local baseRadius = baseDiameter * 0.5

            local cx, cy = curveCenterXY( numTeeth, baseRadius, pitchDiameter )      -- involute center
            local curveS = ( ( tipDiameter - baseDiameter ) * 0.5 ) / ( detail - 1 ) -- involute step
            local curveR = baseRadius                                                -- involute radius

            local dist = ( baseDiameter ~= rootDiameter ) and ( rootDiameter * 0.5 )
            local curveP = {}

            local ibuffer = detail * 2 + 1

            for i = 1, detail do
                local x, y = curvePointXY( baseRadius, curveR )
                curveR = curveR + curveS

                local px = x * cx - y * cy
                local py = x * cy + y * cx

                curveP[i] = Vector( px, py, height )
                curveP[ibuffer - i] = Vector( px, -py, height )
            end

            if dist then
                local rx, ry = curvePointW( curveP[1].x, curveP[1].y, dist )

                table_insert( curveP, 1, Vector( rx, ry, height ) )
                table_insert( curveP, Vector( rx, -ry, height ) )
            end

            return curveP
        end

        local generateGear

        if CLIENT then

            function generateGear( model, threaded, curveP, curveN, numTeeth )
                local toothAngle = Angle()
                local toothAngleStep = 360 / numTeeth

                local faceUpperCap = {}
                local faceLowerCap = {}

                local verts = model.verts
                local convexes = model.convexes

                for i = 0, numTeeth - 1 do
                    toothAngle.y = toothAngleStep * i

                    local vbuffer = #verts
                    local ibuffer = curveN * i

                    local faceUpper = {}
                    local faceLower = {}

                    local convex
                    if convexes then
                        convex = {}
                    end

                    local islast = i == numTeeth - 1
                    local isnext = i ~= 0

                    for j = 1, curveN do
                        local pointUpper = Vector( curveP[j] )
                        vec_rotate( pointUpper, toothAngle )

                        local pointLower = Vector( pointUpper.x, pointUpper.y, -pointUpper.z )

                        local idUpper = vbuffer + j
                        local idLower = vbuffer + j + curveN

                        verts[idUpper] = pointUpper
                        verts[idLower] = pointLower

                        faceUpper[j] = idUpper
                        faceLower[curveN - j + 1] = idLower

                        if j < curveN then
                            model:PushFace( idUpper, idUpper + curveN, idUpper + curveN + 1, idUpper + 1 )

                            if j == 1 then
                                faceUpperCap[#faceUpperCap + 1] = idUpper
                                faceUpperCap[#faceUpperCap + 1] = idUpper + curveN - 1
                                faceLowerCap[#faceLowerCap + 1] = idLower
                                faceLowerCap[#faceLowerCap + 1] = idLower + curveN - 1

                                if isnext then
                                    model:PushFace( idLower, idUpper, idUpper - curveN - 1, idUpper - 1 )
                                end
                            end
                        elseif islast then
                            model:PushFace( curveN + 1, 1, idUpper, idLower )
                        end

                        if convexes then
                            convex[j] = pointUpper
                            convex[j + curveN] = pointLower

                            if j == 1 or j == curveN then
                                local circle = convexes[1]
                                circle[#circle + 1] = verts[idUpper]
                                circle[#circle + 1] = verts[idLower]
                            end
                        end

                        if threaded and ( i % 30 == 0 ) then coroutine_yield( false ) end
                    end

                    model:PushFaceTable( faceUpper )
                    model:PushFaceTable( faceLower )

                    if convexes then
                        convexes[#convexes + 1] = convex
                    end
                end

                faceLowerCap = table.Reverse( faceLowerCap )

                model:PushFaceTable( faceUpperCap )
                model:PushFaceTable( faceLowerCap )
            end

        else

            function generateGear( model, threaded, curveP, curveN, numTeeth )
                local toothAngle = Angle()
                local toothAngleStep = 360 / numTeeth

                local verts = model.verts
                local convexes = model.convexes

                for i = 0, numTeeth - 1 do
                    toothAngle.y = toothAngleStep * i

                    local vbuffer = #verts
                    local ibuffer = curveN * i

                    local convex
                    if convexes then
                        convex = {}
                    end

                    local islast = i == numTeeth - 1
                    local isnext = i ~= 0

                    for j = 1, curveN do
                        local pointUpper = Vector( curveP[j] )
                        vec_rotate( pointUpper, toothAngle )

                        local pointLower = Vector( pointUpper.x, pointUpper.y, -pointUpper.z )

                        local idUpper = vbuffer + j
                        local idLower = vbuffer + j + curveN

                        verts[idUpper] = pointUpper
                        verts[idLower] = pointLower

                        if convexes then
                            convex[j] = pointUpper
                            convex[j + curveN] = pointLower

                            if j == 1 or j == curveN then
                                local circle = convexes[1]
                                circle[#circle + 1] = verts[idUpper]
                                circle[#circle + 1] = verts[idLower]
                            end
                        end
                    end

                    if convexes then
                        convexes[#convexes + 1] = convex
                    end
                end
            end

        end

        registerType( "gear", function( param, data, threaded, physics )
            local model = simpleton.New()

            if physics then
                model.convexes = { {} }
            end

            -- gear parameters
            local numTeeth = math_clamp( tonumber( param.PrimCOUNT ) or 20, 3, 60 )
            local module = math_clamp( tonumber( param.PrimMODULE ) or 1, 1, 50 )
            local gearHeight = math_clamp( tonumber( param.PrimHEIGHT ) or 1, 1, 1000 ) * 0.5
            local pressureAngle = math_clamp( tonumber( param.PrimANGLE ) or 20, 0, 45 )

            -- gear setup
            local toothDetail = SERVER and 2 or 4
            local addendum = module
            local dedendum = module * 1.25
            local pitchDiameter = module * numTeeth                                                              -- tooth mid point
            local rootDiameter = pitchDiameter - dedendum * 2                                                    -- tooth start point
            local tipDiameter = pitchDiameter + addendum * 2                                                     -- tooth end point
            local baseDiameter = math_max( rootDiameter, pitchDiameter * math_cos( math_rad( pressureAngle ) ) ) -- involute start point

            -- gear profile curve
            local curveP = curvePoints( numTeeth, toothDetail, gearHeight, pitchDiameter, baseDiameter, tipDiameter, rootDiameter )
            local curveN = #curveP

            -- gear profile array
            generateGear( model, threaded, curveP, curveN, numTeeth )

            util_Transform( model.verts, param.PrimMESHROT, param.PrimMESHPOS, threaded )

            return model
        end, { canThread = true } )

    end


--]=====]

--[[
	Starfall bindings for the primitive addon.

	Mirrors the gmod_wire_expression2/core/custom/primitive.lua E2 extension:
	primitiveGetVars reads an entity's editable variables, primitiveEdit
	writes to them through the same VariableEdited hook the stock sandbox
	entity editor and the E2 extension both use.
]]

local CheckLuaType      = SF.CheckLuaType
local CheckPerms        = SF.Permissions.check
local RegisterPrivilege = SF.Permissions.registerPrivilege

if SERVER then
	RegisterPrivilege("entities.primitive", "Primitive", "Allows the user to edit Primitive entity variables", { entities = {} })
end

----------------------------------------
-- Primitive Library
-- @name primitive
-- @class library
-- @libtbl primitive_library
SF.RegisterLibrary("primitive")

return function(instance)

local CheckType = instance.CheckType
local dgetmeta = debug.getmetatable

local ents_methods, ent_meta, unwrap = instance.Types.Entity.Methods, instance.Types.Entity, instance.Types.Entity.Unwrap
local vec_meta, vunwrap = instance.Types.Vector, instance.Types.Vector.Unwrap
local ang_meta, aunwrap = instance.Types.Angle, instance.Types.Angle.Unwrap

local function isValidPrimitive(ent)
	return IsValid(ent) and scripted_ents.IsBasedOn(ent:GetClass(), "primitive_base")
end

--===============================================================================================--
-- General Functions (Shared)
--===============================================================================================--

--- Returns the editable variables of a primitive entity
-- @shared
-- @return table Table mapping variable name -> typename (e.g. "Int", "Bool", "Vector", "Angle")
function ents_methods:primitiveGetVars()
	CheckType(self, ent_meta)

	local This = unwrap(self)

	if not isValidPrimitive(This) then SF.Throw("Entity is not a valid primitive", 2) end

	local ret = {}

	for name, edit in pairs(This:GetEditingData()) do
		ret[name] = edit.typename
	end

	return ret
end

--===============================================================================================--
-- General Functions (Server only)
--===============================================================================================--

if SERVER then
	local ANTISPAM_UPDATE_DELAY = 0.5

	local function antispam(ent, key)
		if not ent.PrimitiveSFAntispam then
			ent.PrimitiveSFAntispam = {}
		end

		local time = CurTime()
		local spam = ent.PrimitiveSFAntispam[key]

		if not spam then
			ent.PrimitiveSFAntispam[key] = time
			return true
		end

		if time - spam < ANTISPAM_UPDATE_DELAY then
			return false
		end

		ent.PrimitiveSFAntispam[key] = time

		return true
	end

	--- Edits an editable variable on a primitive entity, same as modifying it using the
	-- context menu properties editor. Values are clamped by the primitive entity itself.
	-- Use primitiveGetVars to see what variables are available on a given entity.
	-- @server
	-- @param string key The variable name
	-- @param number|string|boolean|Vector|Angle val The new value for the variable
	function ents_methods:primitiveEdit(key, val)
		CheckType(self, ent_meta)
		CheckLuaType(key, TYPE_STRING)

		local This = unwrap(self)

		if not isValidPrimitive(This) then SF.Throw("Entity is not a valid primitive", 2) end

		CheckPerms(instance, This, "entities.primitive")

		local editor = This:GetEditingData()[key]

		if not istable(editor) then SF.Throw("Invalid primitive variable: " .. key, 2) end
		if not antispam(This, key) then return end

		local meta = dgetmeta(val)
		local real

		if meta == vec_meta then
			real = vunwrap(val)
		elseif meta == ang_meta then
			real = aunwrap(val)
		elseif isnumber(val) or isstring(val) or isbool(val) then
			real = val
		else
			SF.Throw("Invalid value type for primitive variable", 2)
		end

		-- permissions are checked by the gamemode's CanEditVariable hook,
		-- values are clamped by the primitive entity itself
		hook.Run("VariableEdited", This, instance.player, key, tostring(real), editor)
	end

	end
end

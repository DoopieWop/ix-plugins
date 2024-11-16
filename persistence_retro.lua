local PLUGIN = PLUGIN
PLUGIN.name = "Persistence: Retro Edition"
PLUGIN.description = "Uses GMOD's built-in persistence system."
PLUGIN.author = "DoopieWop"

ix.plugin.SetUnloaded("persistence", true)

if SERVER then
	cvars.AddChangeCallback("sbox_persist", function(name, old, new)
		-- A timer in case someone tries to rapily change the convar, such as addons with "live typing" or whatever
		timer.Create("sbox_persist_change_timer", 2, 1, function()
			hook.Run("PersistenceSave", old)
	
			if (new == "") then
				return
			end
	
			-- stand in for game.CleanUpMap
			-- without this, you will have duplication
			for k, v in ents.Iterator() do
				if v:GetPersistent() then
					v:Remove()
				end
			end
	
			hook.Run("PersistenceLoad", new)
		end)
	end, "sbox_persist_load")
	
	PLUGIN.transferComplete = PLUGIN.transferComplete or false
	PLUGIN.acknowledgedWarning = PLUGIN.acknowledgedWarning or false

	local function LoadOldPersistence(fileContents)
		local data = util.JSONToTable(fileContents)[1]

		-- just ripped from the plugin
		for _, v in ipairs(data) do
			local entity = ents.Create(v.Class)

			if (IsValid(entity)) then
				entity:SetPos(v.Pos)
				entity:SetAngles(v.Angle)
				entity:SetModel(v.Model)
				entity:SetSkin(v.Skin)
				entity:SetColor(v.Color)
				entity:SetMaterial(v.Material)
				entity:Spawn()
				entity:Activate()

				if (v.bNoCollision) then
					entity:SetCollisionGroup(COLLISION_GROUP_WORLD)
				end

				if (istable(v.BodyGroups)) then
					for k2, v2 in pairs(v.BodyGroups) do
						entity:SetBodygroup(k2, v2)
					end
				end

				if (istable(v.SubMaterial)) then
					for k2, v2 in pairs(v.SubMaterial) do
						if (!isnumber(k2) or !isstring(v2)) then
							continue
						end

						entity:SetSubMaterial(k2 - 1, v2)
					end
				end

				local physicsObject = entity:GetPhysicsObject()

				if (IsValid(physicsObject)) then
					physicsObject:EnableMotion(v.Movable)
				end

				entity:SetPersistent(true)
			end
		end

		return #data
	end

	concommand.Add("ix_persistenceTransfer", function(ply, cmd, args)
		if IsValid(ply) then
			return
		end

		if PLUGIN.transferComplete then
			MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 0, 0), " Persistence transfer already completed!\n")
			return
		end

		local mapName = game.GetMap()
		if not PLUGIN.acknowledgedWarning then
			local convar = GetConVar("sbox_persist")

			MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 0, 0), string.format(" Warning: Running this command will override the contents of %s_%s.txt. Please run this command again to acknowledge this. (This command will NOT modify the old persistence plugin's files.)\n", mapName, convar:GetString()))

			PLUGIN.acknowledgedWarning = true
			return
		end

		PLUGIN.acknowledgedWarning = false

		MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 255, 255), " Starting persistence transfer...\n")
		MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 255, 255), " Searching for old persistence file...\n")

		local schemaFolder = Schema.folder
		local mapSaveFile = file.Read(string.format("helix/%s/%s/persistence.txt", schemaFolder, mapName), "DATA")
		if not mapSaveFile then
			MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 0, 0), string.format(" Failed to find old persistence file! Please ensure 'persistence.txt' is present in your server's directory 'garrysmod/data/helix/%s/%s/'\n", schemaFolder, mapName))
			return
		end

		MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 255, 255), " Found old persistence file!\n")
		MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(255, 255, 255), " Beginning transfer of entities...\n")

		local count = LoadOldPersistence(mapSaveFile)
		if count then
			MsgC(Color(0, 255, 0), "[Persistence Transfer]", Color(0, 255, 255), string.format(" Transfer complete! Successfully transferred %d entities!\n", count))

			PLUGIN.transferComplete = true
		end
	end,
	nil,
	"Spawns saved props from the old persistence plugin and then persists them with the new one. Can only be called on fresh server start (no persistet props from the old plugin)")
end

properties.Add( "persist", {
	MenuLabel = "#makepersistent",
	Order = 400,
	MenuIcon = "icon16/link.png",

	Filter = function( self, ent, ply )

		if ( ent:IsPlayer() or ent:CreatedByMap() or ent.bNoPersist ) then return false end
		if ( GetConVarString( "sbox_persist" ):Trim() == "" ) then return false end
		if ( !gamemode.Call( "CanProperty", ply, "persist", ent ) ) then return false end

		return !ent:GetPersistent()

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )

		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end
		if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end

		-- TODO: Start some kind of animation, take 5 seconds to make something persistent

		ent:SetPersistent( true )

		ix.log.Add(client, "persist", GetRealModel(entity), true)
	end

} )

properties.Add( "persist_end", {
	MenuLabel = "#stoppersisting",
	Order = 400,
	MenuIcon = "icon16/link_break.png",

	Filter = function( self, ent, ply )

		if ( ent:IsPlayer() ) then return false end
		if ( GetConVarString( "sbox_persist" ):Trim() == "" ) then return false end
		if ( !gamemode.Call( "CanProperty", ply, "persist", ent ) ) then return false end

		return ent:GetPersistent()

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )

		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end
		if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end

		-- TODO: Start some kind of animation, take 5 seconds to make something persistent

		ent:SetPersistent( false )

		ix.log.Add(client, "persist", GetRealModel(entity), false)
	end

} )

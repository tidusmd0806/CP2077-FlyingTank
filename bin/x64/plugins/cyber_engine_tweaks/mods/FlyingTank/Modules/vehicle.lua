local Position = require("Modules/position.lua")
local Engine = require("Modules/engine.lua")
local Radio = require("Modules/radio.lua")
local Utils = require("Tools/utils.lua")
local Vehicle = {}
Vehicle.__index = Vehicle

function Vehicle:New(all_models)
	---instance---
	local obj = {}
	obj.position_obj = Position:New(all_models)
	obj.engine_obj = Engine:New(obj.position_obj, all_models)
	obj.radio_obj = Radio:New(obj.position_obj)
	obj.log_obj = Log:New()
	obj.log_obj:SetLevel(LogLevel.Info, "Vehicle")
	---static---
	obj.all_models = all_models
	-- summon
	obj.spawn_distance = 5.5
	obj.spawn_high = 50
	obj.spawn_wait_count = 150
	obj.down_time_count = 300
	obj.land_offset = -1.0
	obj.door_open_time = 1.0
	-- collision
	obj.max_collision_count = obj.position_obj.collision_max_count
	-- for spawning vehicle and pedistrian
	obj.freeze_stage_num = 10
	---dynamic---
	-- summon
	obj.entity_id = nil
	obj.vehicle_model_tweakdb_id = nil
	obj.vehicle_model_type = nil
	obj.active_seat = nil
	obj.active_door = nil
	obj.seat_index = 1
	obj.is_crystal_dome = false
	-- collision
	obj.is_collision = false
	obj.colison_count = 0
	-- status
	obj.is_player_in = false
	obj.is_landed = false
	obj.is_leaving = false
	obj.is_unmounting = false
	obj.is_spawning = false
	-- for spawning vehicle and pedistrian
	obj.freeze_count = 0
	obj.max_freeze_count = 30
	obj.min_freeze_count = 8
	obj.max_speed_for_freezing = 100
	return setmetatable(obj, self)
end

function Vehicle:Init()

	local index = FlyingTank.model_index
	local type_number = FlyingTank.model_type_index
	self.vehicle_model_tweakdb_id = self.all_models[index].tweakdb_id
	self.vehicle_model_type = self.all_models[index].type[type_number]
	self.active_seat = self.all_models[index].actual_allocated_seat
	self.active_door = self.all_models[index].actual_allocated_door
	self.engine_obj:SetModel(index)
	self.position_obj:SetModel(index)

end

function Vehicle:IsPlayerIn()

	local veh_obj = GetMountedVehicle(Game.GetPlayer())
	if veh_obj ~= nil then
		local veh_record_id_hash = veh_obj:GetRecordID().hash
		if veh_record_id_hash == TweakDBID.new(FlyingTank.basilisk_aldecaldos_fly_record).hash or veh_record_id_hash == TweakDBID.new(FlyingTank.basilisk_militech_fly_record).hash then
			return true
		else
			return false
		end
	else
		return false
	end

end

function Vehicle:IsSpawning()
	return self.is_spawning
end

function Vehicle:IsDespawned()
	if self.entity_id == nil then
		return true
	else
		return false
	end
end

function Vehicle:Spawn(position, angle)

	if self.entity_id ~= nil then
		self.log_obj:Record(LogLevel.Info, "Entity already spawned")
		return false
	end

	self.is_spawning = true

	local entity_system = Game.GetDynamicEntitySystem()
	local entity_spec = DynamicEntitySpec.new()

	entity_spec.recordID = self.vehicle_model_tweakdb_id
	entity_spec.appearanceName = self.vehicle_model_type
	entity_spec.position = position
	entity_spec.orientation = angle
	entity_spec.persistState = false
	entity_spec.persistSpawn = false
	self.entity_id = entity_system:CreateEntity(entity_spec)

	-- set entity id to position object
	Cron.Every(0.1, {tick = 1}, function(timer)
		local entity = Game.FindEntityByID(self.entity_id)
		if entity ~= nil then
			self.is_spawning = false
			self.position_obj:SetEntity(entity)
			self.engine_obj:Init()
			Cron.Halt(timer)
		end
	end)

	return true

end

function Vehicle:SpawnToSky()

	local position = self.position_obj:GetSpawnPosition(self.spawn_distance, 0.0)
	position.z = position.z + self.spawn_high
	local angle = self.position_obj:GetSpawnOrientation(90.0)
	self:Spawn(position, angle)
	Cron.Every(0.01, { tick = 1 }, function(timer)
		if not FlyingTank.core_obj.event_obj:IsInMenuOrPopupOrPhoto() then
			timer.tick = timer.tick + 1
			if timer.tick == self.spawn_wait_count then
				self:LockDoor()
			elseif timer.tick > self.spawn_wait_count then
				if not self:Move(0.0, 0.0, Utils:CalculationQuadraticFuncSlope(self.down_time_count, self.land_offset ,self.spawn_high , timer.tick - self.spawn_wait_count + 1), 0.0, 0.0, 0.0) then
					self.is_landed = true
					Cron.Halt(timer)
				elseif timer.tick >= self.spawn_wait_count + self.down_time_count then
					self.is_landed = true
					Cron.Halt(timer)
				end
			end
		end
	end)

end

function Vehicle:Despawn()

	if self.entity_id == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to despawn")
		return false
	end
	local entity_system = Game.GetDynamicEntitySystem()
	entity_system:DeleteEntity(self.entity_id)
	self.entity_id = nil
	return true

end

function Vehicle:DespawnFromGround()

	Cron.Every(0.01, { tick = 1 }, function(timer)
		if not FlyingTank.core_obj.event_obj:IsInMenuOrPopupOrPhoto() then
			timer.tick = timer.tick + 1
			if timer.tick > self.spawn_wait_count then
				self:Move(0.0, 0.0, Utils:CalculationQuadraticFuncSlope(self.down_time_count, self.land_offset ,self.spawn_high , timer.tick - self.spawn_wait_count + 1 + self.down_time_count), 0.0, 0.0, 0.0)
				if timer.tick >= self.spawn_wait_count + self.down_time_count then
					self:Despawn()
					Cron.Halt(timer)
				end
			end
		end
	end)

end

function Vehicle:ToggleCrystalDome()

	local entity = Game.FindEntityByID(self.entity_id)
	local effect_name
	if entity == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to change crystal dome")
		return false
	elseif self.vehicle_model_tweakdb_id ~= "Vehicle.av_rayfield_excalibur_dav"
			and self.vehicle_model_tweakdb_id ~= "Vehicle.av_militech_manticore_dav" then
		self.log_obj:Record(LogLevel.Trace, "This vehicle does not have a crystal dome")
		return false
	end
	if not self.is_crystal_dome then
		effect_name = CName.new("crystal_dome_start")
		self.is_crystal_dome = true
	else
		effect_name = CName.new("crystal_dome_stop")
		self.is_crystal_dome = false
	end
	GameObjectEffectHelper.StartEffectEvent(entity, effect_name, false)
	return true

end

function Vehicle:UnlockDoor()
	if self.entity_id == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to change door lock")
		return false
	end
	local entity = Game.FindEntityByID(self.entity_id)
	local vehicle_ps = entity:GetVehiclePS()
	vehicle_ps:UnlockAllVehDoors()
	return true
end

function Vehicle:LockDoor()
	if self.entity_id == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to change door lock")
		return false
	end
	local entity = Game.FindEntityByID(self.entity_id)
	local vehicle_ps = entity:GetVehiclePS()
	vehicle_ps:QuestLockAllVehDoors()
	return true
end

---@param e_veh_door EVehicleDoor
---@return string
function Vehicle:GetDoorState(e_veh_door)

	if self.entity_id == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to get door state")
		return nil
	end
	local entity = Game.FindEntityByID(self.entity_id)
	local vehicle_ps = entity:GetVehiclePS()
	return vehicle_ps:GetDoorState(e_veh_door).value

end

---@param door_state Def.DoorOperation
---@return number
function Vehicle:ChangeDoorState(door_state)

	local change_counter = 0

	for _, door_name in ipairs(self.active_door) do
		local e_veh_door = EVehicleDoor.seat_front_left
		if door_name == "seat_front_left" then
			e_veh_door = EVehicleDoor.seat_front_left
		elseif door_name == "seat_front_right" then
			e_veh_door = EVehicleDoor.seat_front_right
		elseif door_name == "seat_back_left" then
			e_veh_door = EVehicleDoor.seat_back_left
		elseif door_name == "seat_back_right" then
			e_veh_door = EVehicleDoor.seat_back_right
		elseif door_name == "trunk" then
			e_veh_door = EVehicleDoor.trunk
		elseif door_name == "hood" then
			e_veh_door = EVehicleDoor.hood
		end

		local state = self:GetDoorState(e_veh_door)

		local door_event = nil
		local can_change = true
		if state == "Closed" then
			if door_state == Def.DoorOperation.Close then
				can_change = false
			end
			door_event = VehicleDoorOpen.new()
		elseif state == "Open" then
			if door_state == Def.DoorOperation.Open then
				can_change = false
			end
			door_event = VehicleDoorClose.new()
		else
			self.log_obj:Record(LogLevel.Error, "Door state is not valid : " .. state)
			return nil
		end

		if self.entity_id == nil then
			self.log_obj:Record(LogLevel.Warning, "No entity to get door state")
			return nil
		end
		local entity = Game.FindEntityByID(self.entity_id)
		local vehicle_ps = entity:GetVehiclePS()
		if can_change then
			change_counter = change_counter + 1
			door_event.slotID = CName.new(door_name)
			door_event.forceScene = false
			vehicle_ps:QueuePSEvent(vehicle_ps, door_event)
		end
	end
	return change_counter

end

function Vehicle:ControlCrystalDome()

	local e_veh_door = EVehicleDoor.seat_front_left
	if not self.is_crystal_dome then
		Cron.Every(1, {tick = 1}, function(timer)
			if self:GetDoorState(e_veh_door) == "Closed" then
				if self.vehicle_model_tweakdb_id == "Vehicle.av_rayfield_excalibur_dav" then
					Cron.After(3.0, function()
						self:ToggleCrystalDome()
					end)
				else
					self:ToggleCrystalDome()
				end
				Cron.Halt(timer)
			end
		end)
	elseif self.is_crystal_dome then
		self:ToggleCrystalDome()
	end

end

function Vehicle:Mount()

	self.is_landed = false

	local seat_number = self.seat_index

	self.log_obj:Record(LogLevel.Debug, "Mount Aerial Vehicle : " .. seat_number)
	if self.entity_id == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to mount")
		return false
	end
	local entity = Game.FindEntityByID(self.entity_id)
	local player = Game.GetPlayer()
	local ent_id = entity:GetEntityID()
	local seat = self.active_seat[seat_number]


	local data = NewObject('handle:gameMountEventData')
	data.isInstant = false
	data.slotName = seat
	data.mountParentEntityId = ent_id
	data.entryAnimName = "stand__2h_on_sides__01__to__sit_couch__AV_excalibur__01__turn270__getting_into_AV__01"


	local slot_id = NewObject('gamemountingMountingSlotId')
	slot_id.id = seat

	local mounting_info = NewObject('gamemountingMountingInfo')
	mounting_info.childId = player:GetEntityID()
	mounting_info.parentId = ent_id
	mounting_info.slotId = slot_id

	local mounting_request = NewObject('handle:gamemountingMountingRequest')
	mounting_request.lowLevelMountingInfo = mounting_info
	mounting_request.mountData = data

	Game.GetMountingFacility():Mount(mounting_request)

	self.position_obj:ChangePosition()

	if not self.is_crystal_dome then
		self:ControlCrystalDome()
	end

	-- return position near mounted vehicle	
	Cron.Every(0.01, {tick = 1}, function(timer)
		local entity = player:GetMountedVehicle()
		if entity ~= nil then
			Cron.After(1.5, function()
				self.is_player_in = true
			end)
			Cron.Halt(timer)
		end
	end)

	return true

end

function Vehicle:Unmount()

	if self.is_ummounting then
		return false
	end

	self.is_ummounting = true

	local seat_number = self.seat_index
	if self.entity_id == nil then
		self.log_obj:Record(LogLevel.Warning, "No entity to unmount")
		return false
	end
	local entity = Game.FindEntityByID(self.entity_id)
	local player = Game.GetPlayer()
	local ent_id = entity:GetEntityID()
	local seat = self.active_seat[seat_number]

	local data = NewObject('handle:gameMountEventData')
	data.isInstant = true
	data.slotName = seat
	data.mountParentEntityId = ent_id
	data.entryAnimName = "forcedTransition"

	local slotID = NewObject('gamemountingMountingSlotId')
	slotID.id = seat

	local mounting_info = NewObject('gamemountingMountingInfo')
	mounting_info.childId = player:GetEntityID()
	mounting_info.parentId = ent_id
	mounting_info.slotId = slotID

	local mount_event = NewObject('handle:gamemountingUnmountingRequest')
	mount_event.lowLevelMountingInfo = mounting_info
	mount_event.mountData = data

	if self.is_crystal_dome then
		self:ControlCrystalDome()
	end

	-- if all door are open, wait time is short
	local open_door_wait = self.door_open_time
	if self:ChangeDoorState(Def.DoorOperation.Open) == 0 then
		open_door_wait = 0.1
	end

	Cron.After(open_door_wait, function()

		Game.GetMountingFacility():Unmount(mount_event)

		-- set entity id to position object
		Cron.Every(0.01, {tick = 1}, function(timer)
			local entity = Game.FindEntityByID(self.entity_id)
			if entity ~= nil then
				local angle = entity:GetWorldOrientation():ToEulerAngles()
				angle.yaw = angle.yaw + 90
				local position = self.position_obj:GetExitPosition()
				Game.GetTeleportationFacility():Teleport(player, Vector4.new(position.x, position.y, position.z, 1.0), angle)
				self.is_player_in = false
				self.is_ummounting = false
				Cron.Halt(timer)
			end
		end)
	end)

	return true
end

function Vehicle:Move(x, y, z, roll, pitch, yaw)

	if not self.position_obj:SetNextPosition(x, y, z, roll, pitch, yaw, false) then
		return false
	end

	return true

end

function Vehicle:Operate(action_commands)

	if #action_commands == 1 and action_commands[1] == Def.ActionList.Nothing then
		return false
	end
	local x_total, y_total, z_total, roll_total, pitch_total, yaw_total = 0, 0, 0, 0, 0, 0
	self.log_obj:Record(LogLevel.Debug, "Operation Count:" .. #action_commands)
	for _, action_command in ipairs(action_commands) do
		if action_command >= Def.ActionList.Enter then
			self.log_obj:Record(LogLevel.Critical, "Invalid Event Command:" .. action_command)
			return false
		end
		local x, y, z, roll, pitch, yaw = self.engine_obj:GetNextPosition(action_command)
		x_total = x_total + x
		y_total = y_total + y
		z_total = z_total + z
		roll_total = roll_total + roll
		pitch_total = pitch_total + pitch
		yaw_total = yaw_total + yaw
	end
	if #action_commands == 0 then
		self.log_obj:Record(LogLevel.Critical, "Division by Zero")
		return false
	end

	self.is_collision = false

	x_total = x_total / #action_commands
	y_total = y_total / #action_commands
	z_total = z_total / #action_commands
	roll_total = roll_total / #action_commands
	pitch_total = pitch_total / #action_commands
	yaw_total = yaw_total / #action_commands

	if x_total == 0 and y_total == 0 and z_total == 0 and roll_total == 0 and pitch_total == 0 and yaw_total == 0 then
		self.log_obj:Record(LogLevel.Debug, "No operation")
		return false
	end

	local speed_count = self.max_freeze_count
	local level_speed_unit = self.max_speed_for_freezing / self.freeze_stage_num
	local speed_count_unit = math.ceil((self.max_freeze_count - self.min_freeze_count) / self.freeze_stage_num)
	for level = 1, self.freeze_stage_num do
		if self.engine_obj:GetSpeed() < level_speed_unit * level then
			speed_count = self.min_freeze_count + speed_count_unit * (level - 1)
			break
		end
	end

	local is_freeze = false
	-- Freeze for spawning vehicle and pedistrian
	if self.freeze_count < 1 and self:IsEnableFreeze() then
		self.freeze_count = self.freeze_count + 1
		is_freeze = true
	elseif self.freeze_count >= speed_count then
		self.freeze_count = 0
	elseif self.freeze_count >= 1 then
		self.freeze_count = self.freeze_count + 1
	end

	if FlyingTank.user_setting_table.is_disable_spinner_roll_tilt then
		roll_total = 0
	end

	local res = self.position_obj:SetNextPosition(x_total, y_total, z_total, roll_total, pitch_total, yaw_total, is_freeze)

	if res == Def.TeleportResult.Collision then
		self.engine_obj:SetSpeedAfterRebound()
		self.is_collision = true
		self.colison_count = self.colison_count + 1
		if self.colison_count > self.max_collision_count then
			self.log_obj:Record(LogLevel.Info, "Collision Count Over. Engine Reset")
			self.colison_count = 0
		end
		return false
	elseif res == Def.TeleportResult.AvoidStack then
		self.log_obj:Record(LogLevel.Info, "Avoid Stack")
		self.colison_count = 0
		return false
	elseif res == Def.TeleportResult.Error then
		self.log_obj:Record(LogLevel.Error, "Teleport Error")
		self.colison_count = 0
		return false
	end

	self.colison_count = 0

	return true

end

function Vehicle:IsEnableFreeze()

    if not FlyingTank.user_setting_table.is_enable_community_spawn then
        return false
    end

    if self.engine_obj:GetSpeed() < self.max_speed_for_freezing then
        return true
    else
        return false
    end

end

return Vehicle
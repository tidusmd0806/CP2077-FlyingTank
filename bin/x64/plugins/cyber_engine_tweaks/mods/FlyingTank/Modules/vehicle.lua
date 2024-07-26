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
	obj.spawn_high = 1
	obj.spawn_wait_count = 150
	obj.down_time_count = 30
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
	-- speed
	obj.previous_pos = nil
	obj.current_speed = 0
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

			self.previous_pos = self.position_obj:GetPosition()
			self.previous_pos.z = 0
			Cron.Every(0.1, {tick = 1}, function(timer)
				local current_pos = self.position_obj:GetPosition()
				current_pos.z = 0
				self.current_speed = Vector4.Distance(current_pos, self.previous_pos) / 0.1
				self.previous_pos = current_pos
				if self.entity_id == nil then
					self.log_obj:Record(LogLevel.Trace, "No entity to get speed")
					Cron.Halt(timer)
				end
			end)
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
	if self.current_speed > 5 then
		return false
	end
	local x_total, y_total, z_total, roll_total, pitch_total, yaw_total = 0, 0, 0, 0, 0, 0
	self.log_obj:Record(LogLevel.Debug, "Operation Count:" .. #action_commands)
	for _, action_command in ipairs(action_commands) do
		if action_command >= Def.ActionList.ChangeDoor then
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

	local res = self.position_obj:SetNextPosition(x_total, y_total, z_total, roll_total, pitch_total, yaw_total, is_freeze)

	if res == Def.TeleportResult.Collision then
		self.engine_obj:SetSpeedAfterRebound(self.current_speed)
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

return Vehicle
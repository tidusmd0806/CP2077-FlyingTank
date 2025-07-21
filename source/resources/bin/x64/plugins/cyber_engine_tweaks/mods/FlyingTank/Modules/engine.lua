Engine = {}
Engine.__index = Engine

function Engine:New(all_models)
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Engine")
    ---static---
    obj.all_models = all_models
    obj.model_index = 1
    obj.pitch_limit = 35
    obj.max_pitch = 70
    obj.reset_pitch_exception_area = 0.1
    obj.gravitational_acceleration = 9.8
    ---dynamic---
    -- set default parameters
    obj.next_indication = {roll = 0, pitch = 0, yaw = 0}
    obj.is_finished_init = false

    obj.entity = nil
    obj.fly_tank_system = nil
    obj.force = Vector3.new(0, 0, 0)
    obj.torque = Vector3.new(0, 0, 0)
    obj.prev_velocity = Vector3.new(0, 0, 0)
    obj.acceleration = Vector3.new(0, 0, 0)
    obj.direction_velocity = Vector3.new(0, 0, 0)
    obj.angular_velocity = Vector3.new(0, 0, 0)
    obj.control_type = Def.EngineControlType.None

    return setmetatable(obj, self)
end

function Engine:SetModel(index)
    -- set pyhsical parameters
    self.up_down_speed = self.all_models[index].up_down_speed
    self.pitch_speed = self.all_models[index].pitch_speed
    self.reset_pitch_speed = self.all_models[index].reset_pitch_speed
end

function Engine:Init(entity)
    if entity == nil then
        self.log_obj:Record(LogLevel.Warning, "Entity is nil for SetEntity")
    end
    self.entity = entity
    entity:TurnEngineOn(true)
    self.fly_tank_system = FlyTankSystem.new()
    local entity_id_hash = entity:GetEntityID().hash
    self.fly_tank_system:SetVehicle(entity_id_hash)

    self:SetForce(Vector3.new(0, 0, 0))
    self:SetTorque(Vector3.new(0, 0, 0))

    self.is_finished_init = true
end

function Engine:Update(delta)
    if not self.is_finished_init then
        return
    end
    self:UnsetPhysicsState()
    self:SetAcceleration(delta)

    if self.control_type == Def.EngineControlType.ChangeVelocity then
        self:ChangeVelocity(Def.ChangeVelocityType.Both ,self.direction_velocity, self.angular_velocity)
    elseif self.control_type == Def.EngineControlType.AddForce then
        -- reserve
    elseif self.control_type == Def.EngineControlType.LinearlyAutopilot then
        self:OperateLinelyAutopilot(delta)
    else
        self.log_obj:Record(LogLevel.Error, "Unknown control type")
    end
end

function Engine:UnsetPhysicsState()
    self.fly_tank_system:UnsetPhysicsState()
end

function Engine:SetControlType(control_type)
    self.control_type = control_type
    if control_type == Def.EngineControlType.ChangeVelocity and self:HasGravity() then
        self:EnableGravity(false)
    elseif control_type == Def.EngineControlType.AddVelocity and not self:HasGravity() then
        self:EnableGravity(true)
    end
end

function Engine:HasGravity()
    return self.fly_tank_system:HasGravity()
end

function Engine:EnableGravity(on)
    self.fly_tank_system:EnableGravity(on)
end

function Engine:AddForce(delta, force, torque)
    local delta_force = Vector3.new(force.x * delta, force.y * delta, (-self:GetGravitationalForce() + force.z) * delta)
    local delta_torque = Vector3.new(torque.x * delta, torque.y * delta, torque.z * delta)
    self.fly_tank_system:AddForce(delta_force, delta_torque)
end

--- Change velocity
---@param type integer
---@param direction_velocity Vector3
---@param angular_velocity Vector3
function Engine:ChangeVelocity(type, direction_velocity, angular_velocity)
    self.fly_tank_system:ChangeVelocity(direction_velocity, angular_velocity, type)
end

function Engine:SetForce(force)
    self.force = force
end

function Engine:SetTorque(torque)
    self.torque = torque
end

function Engine:GetDirectionVelocity()
    return self.direction_velocity
end

function Engine:GetAngularVelocity()
    return self.angular_velocity
end

function Engine:SetDirectionVelocity(direction_velocity)
    self.direction_velocity = direction_velocity
end

function Engine:SetAngularVelocity(angular_velocity)
    self.angular_velocity = angular_velocity
end

function Engine:GetGravitationalForce()
    local mass = self.fly_tank_system:GetMass()
    return -self.gravitational_acceleration * mass
end

function Engine:GetAcceleration()
    return self.acceleration
end

function Engine:SetAcceleration(delta)
    local current_velocity = self.fly_tank_system:GetVelocity()
    self.acceleration.x = (current_velocity.x - self.prev_velocity.x) / delta
    self.acceleration.y = (current_velocity.y - self.prev_velocity.y) / delta
    self.acceleration.z = (current_velocity.z - self.prev_velocity.z) / delta
    self.prev_velocity = current_velocity
end

function Engine:AddVelocity(x,y,z,roll,pitch,yaw)
    local pos = Vector3.new(x, y, z)
    local delta_roll, delta_pitch, delta_yaw = self:EulerAngleChange(roll, pitch, yaw)
    local angle = Vector3.new(delta_pitch, delta_roll, delta_yaw)
    self.fly_tank_system:AddVelocity(pos, angle)
end

function Engine:EulerAngleChange(local_roll, local_pitch, local_yaw)

    local angle = self.entity:GetWorldOrientation():ToEulerAngles()

    -- Convert Euler angles to radians
    local rad_roll = math.rad(angle.roll)
    local rad_pitch = math.rad(angle.pitch)
    local rad_yaw = math.rad(angle.yaw)
    local rad_local_roll = math.rad(local_roll)
    local rad_local_pitch = math.rad(local_pitch)
    local rad_local_yaw = math.rad(local_yaw)

    -- Calculate sin and cos
    local cos_roll, sin_roll = math.cos(rad_roll), math.sin(rad_roll)
    local cos_pitch, sin_pitch = math.cos(rad_pitch), math.sin(rad_pitch)
    local cos_yaw, sin_yaw = math.cos(rad_yaw), math.sin(rad_yaw)
    local cos_local_roll, sin_local_roll = math.cos(rad_local_roll), math.sin(rad_local_roll)
    local cos_local_pitch, sin_local_pitch = math.cos(rad_local_pitch), math.sin(rad_local_pitch)
    local cos_local_yaw, sin_local_yaw = math.cos(rad_local_yaw), math.sin(rad_local_yaw)

    -- Calculate rotation matrices
    local R1 = {
        {cos_roll * cos_pitch, cos_roll * sin_pitch * sin_yaw - sin_roll * cos_yaw, cos_roll * sin_pitch * cos_yaw + sin_roll * sin_yaw},
        {sin_roll * cos_pitch, sin_roll * sin_pitch * sin_yaw + cos_roll * cos_yaw, sin_roll * sin_pitch * cos_yaw - cos_roll * sin_yaw},
        {-sin_pitch, cos_pitch * sin_yaw, cos_pitch * cos_yaw}
    }

    local R2 = {
        {cos_local_roll * cos_local_pitch, cos_local_roll * sin_local_pitch * sin_local_yaw - sin_local_roll * cos_local_yaw, cos_local_roll * sin_local_pitch * cos_local_yaw + sin_local_roll * sin_local_yaw},
        {sin_local_roll * cos_local_pitch, sin_local_roll * sin_local_pitch * sin_local_yaw + cos_local_roll * cos_local_yaw, sin_local_roll * sin_local_pitch * cos_local_yaw - cos_local_roll * sin_local_yaw},
        {-sin_local_pitch, cos_local_pitch * sin_local_yaw, cos_local_pitch * cos_local_yaw}
    }

    -- Calculate composite rotation matrix
    local R = {}
    for i = 1, 3 do
        R[i] = {}
        for j = 1, 3 do
            R[i][j] = 0
            for k = 1, 3 do
                R[i][j] = R[i][j] + R1[i][k] * R2[k][j]
            end
        end
    end

    -- Calculate Euler angles from composite rotation matrix
    local new_roll = math.deg(math.atan2(R[2][1], R[1][1]))
    local new_pitch = math.deg(math.atan2(-R[3][1], math.sqrt(R[3][2] * R[3][2] + R[3][3] * R[3][3])))
    local new_yaw = math.deg(math.atan2(R[3][2], R[3][3]))

    return new_roll - angle.roll, new_pitch - angle.pitch, new_yaw - angle.yaw
end

function Engine:GetNextPosition(movement)

    -- wait for init
    if not self.is_finished_init then
        return 0, 0, 0, 0, 0, 0
    end

    local angle_pitch = self.entity:GetWorldOrientation():ToEulerAngles().pitch
    if angle_pitch > self.max_pitch or angle_pitch < -self.max_pitch then
        self.fly_tank_system:ChangeVelocity(Vector3.new(0, 0, 0), Vector3.new(0, 0, 0),2)
    end

    if movement == Def.ActionList.Up then
        local vec3 = self.fly_tank_system:GetVelocity()
        if vec3.z > 40 then
            return 0, 0, 0, 0, 0, 0
        end
        return 0, 0, self.up_down_speed, 0, 0, 0
    elseif movement == Def.ActionList.Down then
        local vec3 = self.fly_tank_system:GetVelocity()
        if vec3.z < -40 then
            return 0, 0, 0, 0, 0, 0
        end
        return 0, 0, -self.up_down_speed, 0, 0, 0
    elseif movement == Def.ActionList.PitchUp then
        if angle_pitch > self.pitch_limit then
            return 0, 0, 0, 0, 0, 0
        elseif angle_pitch > 0 then
            return 0, 0, 0, 0, self.pitch_speed * (1 - angle_pitch / self.pitch_limit), 0
        end
        return 0, 0, 0, 0, self.pitch_speed, 0
    elseif movement == Def.ActionList.PitchDown then
        if angle_pitch < -self.pitch_limit then
            return 0, 0, 0, 0, 0, 0
        elseif angle_pitch < 0 then
            return 0, 0, 0, 0, -self.pitch_speed * (1 + angle_pitch / self.pitch_limit), 0
        end
        return 0, 0, 0, 0, -self.pitch_speed, 0
    elseif movement == Def.ActionList.PitchReset then
        if angle_pitch > self.reset_pitch_exception_area then
            return 0, 0, 0, 0, -self.reset_pitch_speed, 0
        elseif angle_pitch < -self.reset_pitch_exception_area then
            return 0, 0, 0, 0, self.reset_pitch_speed, 0
        end
        return 0, 0, 0, 0, 0, 0
    else
        return 0, 0, 0, 0, 0, 0
    end

end

--- Set linearly autopilot mode
---@param enable boolean
---@param end_point Vector4
---@param end_decreased_distance number
---@param first_increased_time number
---@param end_decreased_time number
---@param min_speed number
---@param max_speed number
---@param is_rocked_angle boolean
function Engine:SetlinearlyAutopilotMode(enable, end_point, end_decreased_distance, first_increased_time, end_decreased_time, min_speed, max_speed, is_rocked_angle)
    if enable then
        self:SetControlType(Def.EngineControlType.LinearlyAutopilot)
        self.end_point_for_linearly_autopilot = end_point
        self.end_decreased_distance_for_linearly_autopilot = end_decreased_distance
        self.first_increased_time_for_linearly_autopilot = first_increased_time
        self.end_decreased_time_for_linearly_autopilot = end_decreased_time
        self.min_speed_for_linearly_autopilot = min_speed
        self.max_speed_for_linearly_autopilot = max_speed
        self.is_rocked_angle_for_linearly_autopilot = is_rocked_angle
        self.is_enable_limearly_autopilot = true
        self.autopilot_time = 0
    else
        self:SetControlType(Def.EngineControlType.ChangeVelocity)
        self:SetDirectionVelocity(Vector3.new(0, 0, 0))
        self:SetAngularVelocity(Vector3.new(0, 0, 0))
        self.autopilot_time = 0
        self.is_enable_limearly_autopilot = false
    end
end

--- Operate linely autopilot
---@param delta number
function Engine:OperateLinelyAutopilot(delta)
    if not self.is_enable_limearly_autopilot then
        self.log_obj:Record(LogLevel.Critical, "Don't operate because linely autopilot is not enabled")
        return
    end
    local av_position = Game.FindEntityByID(self.entity:GetEntityID()):GetWorldPosition()
    local direction_vector = Vector4.new(self.end_point_for_linearly_autopilot.x - av_position.x,
                                            self.end_point_for_linearly_autopilot.y - av_position.y,
                                            self.end_point_for_linearly_autopilot.z - av_position.z, 1)
    local direcrtion_vector_normalized = Vector4.Normalize(direction_vector)
    local gradient_start
    if self.first_increased_time_for_linearly_autopilot == 0 then
         gradient_start = 0
    else
        gradient_start = (self.max_speed_for_linearly_autopilot - self.min_speed_for_linearly_autopilot) / self.first_increased_time_for_linearly_autopilot
    end
    local gradient_end
    if self.end_decreased_time_for_linearly_autopilot == 0 then
        gradient_end = 0
    else
        gradient_end = (self.min_speed_for_linearly_autopilot - self.max_speed_for_linearly_autopilot) / self.end_decreased_time_for_linearly_autopilot
    end
    local remaining_distance = Vector4.Distance(av_position, self.end_point_for_linearly_autopilot)
    local current_velocity = self:GetDirectionVelocity()
    local current_velocity_norm = math.sqrt(current_velocity.x * current_velocity.x + current_velocity.y * current_velocity.y + current_velocity.z * current_velocity.z)
    if self.autopilot_time < self.first_increased_time_for_linearly_autopilot then
        local direction_velocity = Vector3.new(current_velocity.x + direcrtion_vector_normalized.x * gradient_start * delta, current_velocity.y + direcrtion_vector_normalized.y * gradient_start * delta, current_velocity.z + direcrtion_vector_normalized.z * gradient_start * delta)
        local direction_velocity_norm = math.sqrt(direction_velocity.x * direction_velocity.x + direction_velocity.y * direction_velocity.y + direction_velocity.z * direction_velocity.z)
        if direction_velocity_norm > self.max_speed_for_linearly_autopilot then
            direction_velocity.x = direction_velocity.x / direction_velocity_norm * self.max_speed_for_linearly_autopilot
            direction_velocity.y = direction_velocity.y / direction_velocity_norm * self.max_speed_for_linearly_autopilot
            direction_velocity.z = direction_velocity.z / direction_velocity_norm * self.max_speed_for_linearly_autopilot
        end
        self:SetDirectionVelocity(direction_velocity)
    elseif remaining_distance < 1 or current_velocity_norm == 0 then
        self:SetlinearlyAutopilotMode(false, Vector4.new(0, 0, 0, 1), 0, 0, 0, 0, 0, false)
        return
    elseif remaining_distance < self.end_decreased_distance_for_linearly_autopilot then
        local direction_velocity = Vector3.new(current_velocity.x + direcrtion_vector_normalized.x * gradient_end * delta, current_velocity.y + direcrtion_vector_normalized.y * gradient_end * delta, current_velocity.z + direcrtion_vector_normalized.z * gradient_end * delta)
        local direction_velocity_norm = math.sqrt(direction_velocity.x * direction_velocity.x + direction_velocity.y * direction_velocity.y + direction_velocity.z * direction_velocity.z)
        if direction_velocity_norm < self.min_speed_for_linearly_autopilot then
            direction_velocity.x = direction_velocity.x / direction_velocity_norm * self.min_speed_for_linearly_autopilot
            direction_velocity.y = direction_velocity.y / direction_velocity_norm * self.min_speed_for_linearly_autopilot
            direction_velocity.z = direction_velocity.z / direction_velocity_norm * self.min_speed_for_linearly_autopilot
        end
        self:SetDirectionVelocity(direction_velocity)
    end
    self:ChangeVelocity(Def.ChangeVelocityType.Both ,self.direction_velocity, self.angular_velocity)
    self.autopilot_time = self.autopilot_time + delta
end

return Engine

Engine = {}
Engine.__index = Engine

Engine.ControlType =
{
    None = -1,
    ChangeVelocity = 0,
    AddVelocity = 1,
}

function Engine:New(all_models)
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Engine")
    obj.all_models = all_models
    obj.model_index = 1

    obj.pitch_limit = 35
    obj.max_pitch = 70
    obj.reset_pitch_exception_area = 0.1

    -- set default parameters
    obj.next_indication = {roll = 0, pitch = 0, yaw = 0}
    obj.is_finished_init = false
    obj.horizenal_x_speed = 0
    obj.horizenal_y_speed = 0
    obj.horizenal_speed = 0
    obj.vertical_speed = 0
    obj.current_speed = 0
    obj.is_falling = false

    obj.entity = nil
    obj.fly_tank_system = nil
    obj.force = Vector3.new(0, 0, 0)
    obj.torque = Vector3.new(0, 0, 0)
    obj.limited_speed = 10
    obj.prev_velocity = Vector3.new(0, 0, 0)
    obj.acceleration = Vector3.new(0, 0, 0)
    obj.velocity = Vector3.new(0, 0, 0)
    obj.angular_velocity = Vector3.new(0, 0, 0)

    obj.gravitational_acceleration = 9.8
    obj.control_type = Engine.ControlType.None

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
    self.fly_tank_system = FlyTankSystem.new()
    local entity_id_hash = entity:GetEntityID().hash
    self.fly_tank_system:SetVehicle(entity_id_hash)

    self:SetForce(Vector3.new(0, 0, 0))
    self:SetTorque(Vector3.new(0, 0, 0))

    self.horizenal_x_speed = 0
    self.horizenal_y_speed = 0
    self.vertical_speed = 0
    self.is_finished_init = true
end

function Engine:Update(delta)
    if not self.is_finished_init then
        return
    end
    self:UnsetPhysicsState()
    self:SetAcceleration(delta)
    -- if self:IsOverLimitedVelocity() then
    --     self:ChangeForce(Vector3.new(0, 0, 0), Vector3.new(0, 0, 0))
    --     return
    -- end
    if self.control_type == Engine.ControlType.ChangeVelocity then
        self:ChangeVelocity(self.velocity, self.angular_velocity)
    elseif self.control_type == Engine.ControlType.AddVelocity then
        -- reserve
    else
        self.log_obj:Record(LogLevel.Error, "Unknown control type")
    end
end

function Engine:UnsetPhysicsState()
    self.fly_tank_system:UnsetPhysicsState()
end

function Engine:SetControlType(control_type)
    self.control_type = control_type
    if control_type == Engine.ControlType.ChangeVelocity and self:HasGravity() then
        self:EnableGravity(false)
    elseif control_type == Engine.ControlType.AddVelocity and not self:HasGravity() then
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

function Engine:ChangeVelocity(velocity, angular_velocity)
    self.fly_tank_system:ChangeVelocity(velocity, angular_velocity, 0)
end

function Engine:SetForce(force)
    self.force = force
end

function Engine:SetTorque(torque)
    self.torque = torque
end

function Engine:SetVelocity(velocity)
    self.velocity = velocity
end

function Engine:SetAngularVelocity(angular_velocity)
    self.angular_velocity = angular_velocity
end

function Engine:SetLimitedVelocity(limited_speed)
    self.limited_speed = limited_speed
end

function Engine:GetGravitationalForce()
    local mass = self.fly_tank_system:GetMass()
    return -self.gravitational_acceleration * mass
end

function Engine:IsOverLimitedVelocity()
    local vec3 = self.fly_tank_system:GetVelocity()
    local speed = math.sqrt(vec3.x * vec3.x + vec3.y * vec3.y + vec3.z * vec3.z)
    if self.limited_speed < speed then
        return true
    end
    return false
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

return Engine

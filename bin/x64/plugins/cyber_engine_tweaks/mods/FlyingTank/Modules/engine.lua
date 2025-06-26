Engine = {}
Engine.__index = Engine

function Engine:New(position_obj, all_models)
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Engine")
    obj.position_obj = position_obj
    obj.all_models = all_models
    obj.model_index = 1

    obj.pitch_limit = 35
    obj.max_pitch = 70
    obj.reset_pitch_exception_area = 0.1

    -- set default parameters
    obj.next_indication = {roll = 0, pitch = 0, yaw = 0}
    obj.base_angle = nil
    obj.is_finished_init = false
    obj.horizenal_x_speed = 0
    obj.horizenal_y_speed = 0
    obj.horizenal_speed = 0
    obj.vertical_speed = 0
    obj.current_speed = 0
    obj.is_falling = false

    obj.fly_tank_system = nil
    obj.force = Vector3.new(0, 0, 0)
    obj.torque = Vector3.new(0, 0, 0)

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

    self.force = Vector3.new(0, 0, 0)
    self.torque = Vector3.new(0, 0, 0)

    if not self.is_finished_init then
        self.base_angle = self.position_obj:GetEulerAngles()
    end

    self.horizenal_x_speed = 0
    self.horizenal_y_speed = 0
    self.vertical_speed = 0
    self.is_finished_init = true
end

function Engine:Update()
    self:UnsetPhysicsState()
    self:ChangeForce(self.force, self.torque)
end

function Engine:UnsetPhysicsState()
    self.fly_tank_system:UnsetPhysicsState()
end

function Engine:ChangeForce(force, torque)
    self.fly_tank_system:ChangeForce(force, torque, 0)
end

function Engine:SetForce(force)
    self.force = force
end

function Engine:GetNextPosition(movement)

    -- wait for init
    if not self.is_finished_init then
        return 0, 0, 0, 0, 0, 0
    end

    local angle_pitch = self.position_obj:GetEulerAngles().pitch
    if angle_pitch > self.max_pitch or angle_pitch < -self.max_pitch then
        -- self.position_obj:ChangeVelocity(0, 0, 0, 0, 0, 0, 2)
    end

    if movement == Def.ActionList.Up then
        -- local vec3 = self.position_obj.fly_tank_system:GetVelocity()
        -- if vec3.z > 40 then
        --     return 0, 0, 0, 0, 0, 0
        -- end
        return 0, 0, self.up_down_speed, 0, 0, 0
    elseif movement == Def.ActionList.Down then
        -- local vec3 = self.position_obj.fly_tank_system:GetVelocity()
        -- if vec3.z < -40 then
        --     return 0, 0, 0, 0, 0, 0
        -- end
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

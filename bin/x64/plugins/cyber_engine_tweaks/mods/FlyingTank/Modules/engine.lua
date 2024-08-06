Engine = {}
Engine.__index = Engine

function Engine:New(position_obj, all_models)
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Engine")
    obj.position_obj = position_obj
    obj.all_models = all_models
    obj.model_index = 1

    obj.reset_pitch_exception_area = 0.1

    --Common
    obj.rebound_constant = nil

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

    return setmetatable(obj, self)
end

function Engine:SetModel(index)
    -- set pyhsical parameters
    self.up_down_speed = self.all_models[index].up_down_speed
    self.pitch_speed = self.all_models[index].pitch_speed
    self.reset_pitch_speed = self.all_models[index].reset_pitch_speed
end

function Engine:Init()
    if not self.is_finished_init then
        self.base_angle = self.position_obj:GetEulerAngles()
    end

    self.horizenal_x_speed = 0
    self.horizenal_y_speed = 0
    self.vertical_speed = 0
    self.is_finished_init = true
end

function Engine:GetNextPosition(movement)

    -- wait for init
    if not self.is_finished_init then
        return 0, 0, 0, 0, 0, 0
    end

    if movement == Def.ActionList.Up then
        local vec3 = self.position_obj.fly_tank_system:GetVelocity()
        if vec3.z > 40 then
            return 0, 0, 0, 0, 0, 0
        end
        return 0, 0, self.up_down_speed, 0, 0, 0
    elseif movement == Def.ActionList.Down then
        local vec3 = self.position_obj.fly_tank_system:GetVelocity()
        if vec3.z < -40 then
            return 0, 0, 0, 0, 0, 0
        end
        return 0, 0, -self.up_down_speed, 0, 0, 0
    elseif movement == Def.ActionList.PitchUp then
        return 0, 0, 0, 0, self.pitch_speed, 0
    elseif movement == Def.ActionList.PitchDown then
        return 0, 0, 0, 0, -self.pitch_speed, 0
    elseif movement == Def.ActionList.PitchReset then
        local angle_pitch = self.position_obj:GetEulerAngles().pitch
        if angle_pitch > self.reset_pitch_exception_area then
            return 0, 0, 0, 0, -self.reset_pitch_speed, 0
        elseif angle_pitch < -self.reset_pitch_exception_area then
            return 0, 0, 0, 0, self.reset_pitch_speed, 0
        end
    else
        return 0, 0, 0, 0, 0, 0
    end

end

function Engine:SetSpeedAfterRebound(current_speed)
    local reflection_vector = self.position_obj:GetReflectionVector()
    local reflection_vector_norm = math.sqrt(reflection_vector.x * reflection_vector.x + reflection_vector.y * reflection_vector.y + reflection_vector.z * reflection_vector.z)
    local reflection_value = reflection_vector_norm * current_speed * self.rebound_constant

    self.horizenal_x_speed = reflection_vector.x * reflection_value
    self.horizenal_y_speed = reflection_vector.y * reflection_value
    self.vertical_speed = reflection_vector.z * reflection_value

    -- check falling
    local horizenal_speed = math.sqrt(self.horizenal_x_speed * self.horizenal_x_speed + self.horizenal_y_speed * self.horizenal_y_speed)
    if self.vertical_speed > 0 and math.abs(self.vertical_speed) > horizenal_speed then
        self.is_falling = true
    else
        self.is_falling = false
    end
end

function Engine:IsInFalling()
    if self.is_falling then
        return true
    else
        return false
    end
end

return Engine

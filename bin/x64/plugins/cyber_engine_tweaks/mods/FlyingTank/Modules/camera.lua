-- local Log = require("Tools/log.lua")
local Utils = require("Tools/utils.lua")
local Camera = {}
Camera.__index = Camera

function Camera:New(position_obj, all_models)
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Camera")
    obj.position_obj = position_obj
    obj.all_models = all_models

    -- set default parameters
    obj.current_camera_mode = Def.CameraDistanceLevel.Fpp

    return setmetatable(obj, self)
end

function Camera:ChangePosition(level)

    local camera_perspective = vehicleRequestCameraPerspectiveEvent.new()

    if level == Def.CameraDistanceLevel.Fpp then
		self.log_obj:Record(LogLevel.Trace, "Change Camera : FPP")
        camera_perspective.cameraPerspective = vehicleCameraPerspective.FPP
    elseif level == Def.CameraDistanceLevel.TppClose then
		self.log_obj:Record(LogLevel.Trace, "Change Camera : TPPClose")
        camera_perspective.cameraPerspective = vehicleCameraPerspective.TPPClose
    elseif level == Def.CameraDistanceLevel.TppMedium then
		self.log_obj:Record(LogLevel.Trace, "Change Camera : TPPMedium")
        camera_perspective.cameraPerspective = vehicleCameraPerspective.TPPMedium
    elseif level == Def.CameraDistanceLevel.TppFar then
		self.log_obj:Record(LogLevel.Trace, "Change Camera : TPPFar")
        camera_perspective.cameraPerspective = vehicleCameraPerspective.TPPFar

    end

    Game.GetPlayer():QueueEvent(camera_perspective)

end

function Camera:Toggle()
    if self.current_camera_mode ~= Def.CameraDistanceLevel.TppFar then
        self.current_camera_mode = self.current_camera_mode + 1
    elseif self.current_camera_mode == Def.CameraDistanceLevel.TppFar then
        self.current_camera_mode = Def.CameraDistanceLevel.Fpp
    end
    self:ChangePosition(self.current_camera_mode)
    return self.current_camera_mode
end

return Camera
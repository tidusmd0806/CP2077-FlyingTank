#include <RED4ext/RED4ext.hpp>
#include <RED4ext/RTTITypes.hpp>
#include <RED4ext/Scripting/Natives/vehicleBaseObject.hpp>
#include <RED4ext/Scripting/Natives/vehiclePhysicsData.hpp>

struct FlyTankSystem : RED4ext::IScriptable
{
    RED4ext::CClass* GetNativeType();
};

RED4ext::TTypedClass<FlyTankSystem> cls("FlyTankSystem");

RED4ext::CClass* FlyTankSystem::GetNativeType()
{
    return &cls;
}

void AddLinelyVelocity(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, float* aOut, int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(a4);

    RED4ext::ScriptGameInstance gameInstance;
    RED4ext::Handle<RED4ext::IScriptable> playerHandle;
    RED4ext::ExecuteGlobalFunction("GetPlayer;GameInstance", &playerHandle, gameInstance);
    
    RED4ext::WeakHandle<RED4ext::vehicle::BaseObject> wvehicle;
    RED4ext::ExecuteGlobalFunction("GetMountedVehicle;GameObject", &wvehicle, playerHandle);

    RED4ext::Vector3 velocity;
    RED4ext::Vector3 angularVelocity;

    RED4ext::GetParameter(aFrame, &velocity);
    RED4ext::GetParameter(aFrame, &angularVelocity);
    aFrame->code++; // skip ParamEnd

    auto vehicle = wvehicle.Lock();

    *aOut = 0;

     if (vehicle)
     {
         vehicle->physicsData->velocity += velocity;
         vehicle->physicsData->angularVelocity += angularVelocity;
         *aOut = 1;
     }
}

void ChangeLinelyVelocity(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, float* aOut, int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(a4);

    RED4ext::ScriptGameInstance gameInstance;
    RED4ext::Handle<RED4ext::IScriptable> playerHandle;
    RED4ext::ExecuteGlobalFunction("GetPlayer;GameInstance", &playerHandle, gameInstance);

    RED4ext::WeakHandle<RED4ext::vehicle::BaseObject> wvehicle;
    RED4ext::ExecuteGlobalFunction("GetMountedVehicle;GameObject", &wvehicle, playerHandle);

    RED4ext::Vector3 velocity;
    RED4ext::Vector3 angularVelocity;
    float switchIndex;

    RED4ext::GetParameter(aFrame, &velocity);
    RED4ext::GetParameter(aFrame, &angularVelocity);
    RED4ext::GetParameter(aFrame, &switchIndex);

    aFrame->code++; // skip ParamEnd

    auto vehicle = wvehicle.Lock();

    *aOut = 0;

    if (vehicle)
    {
        if (switchIndex == 1)
        {
            vehicle->physicsData->velocity = velocity;
        }
        else if (switchIndex == 2)
        {
            vehicle->physicsData->angularVelocity = angularVelocity;
        }
        else
        {
            vehicle->physicsData->velocity = velocity;
            vehicle->physicsData->angularVelocity = angularVelocity;
        }
        *aOut = 1;
    }
}

void GetVelocity(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::Vector3* aOut, int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(aFrame);
    RED4EXT_UNUSED_PARAMETER(a4);

    RED4ext::ScriptGameInstance gameInstance;
    RED4ext::Handle<RED4ext::IScriptable> playerHandle;
    RED4ext::ExecuteGlobalFunction("GetPlayer;GameInstance", &playerHandle, gameInstance);

    RED4ext::WeakHandle<RED4ext::vehicle::BaseObject> wvehicle;
    RED4ext::ExecuteGlobalFunction("GetMountedVehicle;GameObject", &wvehicle, playerHandle);

    RED4ext::Vector3 velocity;
    velocity.X = 0;
    velocity.Y = 0;
    velocity.Z = 0;

    *aOut = velocity;

    auto vehicle = wvehicle.Lock();

    if (vehicle)
    {
        *aOut = vehicle->physicsData->velocity;
    }
}

void GetAngularVelocity(RED4ext::IScriptable* aContext, RED4ext::CStackFrame* aFrame, RED4ext::Vector3* aOut, int64_t a4)
{
    RED4EXT_UNUSED_PARAMETER(aContext);
    RED4EXT_UNUSED_PARAMETER(aFrame);
    RED4EXT_UNUSED_PARAMETER(a4);

    RED4ext::ScriptGameInstance gameInstance;
    RED4ext::Handle<RED4ext::IScriptable> playerHandle;
    RED4ext::ExecuteGlobalFunction("GetPlayer;GameInstance", &playerHandle, gameInstance);

    RED4ext::WeakHandle<RED4ext::vehicle::BaseObject> wvehicle;
    RED4ext::ExecuteGlobalFunction("GetMountedVehicle;GameObject", &wvehicle, playerHandle);

    RED4ext::Vector3 angularVelocity;
    angularVelocity.X = 0;
    angularVelocity.Y = 0;
    angularVelocity.Z = 0;

    *aOut = angularVelocity;

    auto vehicle = wvehicle.Lock();

    if (vehicle)
    {
        *aOut = vehicle->physicsData->angularVelocity;
    }
}

RED4EXT_C_EXPORT void RED4EXT_CALL RegisterFlyTankSystem()
{
    RED4ext::CNamePool::Add("FlyTankSystem");

    cls.flags = {.isNative = true};
    RED4ext::CRTTISystem::Get()->RegisterType(&cls);
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterAddLinelyVelocity()
{
    auto rtti = RED4ext::CRTTISystem::Get();
    auto scriptable = rtti->GetClass("IScriptable");
    cls.parent = scriptable;

    RED4ext::CBaseFunction::Flags flags = {.isNative = true};
    auto func = RED4ext::CClassFunction::Create(&cls, "AddLinelyVelocity", "AddLinelyVelocity", &AddLinelyVelocity, {.isNative = true});
    func->flags = flags;
    func->SetReturnType("Float");
    func->AddParam("Vector3", "velocity");
    func->AddParam("Vector3", "angularVelocity");
    cls.RegisterFunction(func);
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterChangeLinelyVelocity()
{
    auto rtti = RED4ext::CRTTISystem::Get();
    auto scriptable = rtti->GetClass("IScriptable");
    cls.parent = scriptable;

    RED4ext::CBaseFunction::Flags flags = {.isNative = true};
    auto func = RED4ext::CClassFunction::Create(&cls, "ChangeLinelyVelocity", "ChangeLinelyVelocity", &ChangeLinelyVelocity, {.isNative = true});
    func->flags = flags;
    func->SetReturnType("Float");
    func->AddParam("Vector3", "velocity");
    func->AddParam("Vector3", "angularVelocity");
    func->AddParam("Float", "switchIndex");
    cls.RegisterFunction(func);
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterGetVelocity()
{
    auto rtti = RED4ext::CRTTISystem::Get();
    auto scriptable = rtti->GetClass("IScriptable");
    cls.parent = scriptable;

    RED4ext::CBaseFunction::Flags flags = {.isNative = true};
    auto func = RED4ext::CClassFunction::Create(&cls, "GetVelocity", "GetVelocity", &GetVelocity, {.isNative = true});
    func->flags = flags;
    func->SetReturnType("Vector3");
    cls.RegisterFunction(func);
}

RED4EXT_C_EXPORT void RED4EXT_CALL PostRegisterGetAngularVelocity()
{
    auto rtti = RED4ext::CRTTISystem::Get();
    auto scriptable = rtti->GetClass("IScriptable");
    cls.parent = scriptable;

    RED4ext::CBaseFunction::Flags flags = {.isNative = true};
    auto func = RED4ext::CClassFunction::Create(&cls, "GetAngularVelocity", "GetAngularVelocity", &GetAngularVelocity, {.isNative = true});
    func->flags = flags;
    func->SetReturnType("Vector3");
    cls.RegisterFunction(func);
}

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::PluginHandle aHandle, RED4ext::EMainReason aReason,
                                        const RED4ext::Sdk* aSdk)
{
    RED4EXT_UNUSED_PARAMETER(aHandle);
    RED4EXT_UNUSED_PARAMETER(aSdk);

    switch (aReason)
    {
    case RED4ext::EMainReason::Load:
    {
        RED4ext::RTTIRegistrator::Add(RegisterFlyTankSystem, PostRegisterAddLinelyVelocity);
        RED4ext::RTTIRegistrator::Add(RegisterFlyTankSystem, PostRegisterChangeLinelyVelocity);
        RED4ext::RTTIRegistrator::Add(RegisterFlyTankSystem, PostRegisterGetVelocity);
        RED4ext::RTTIRegistrator::Add(RegisterFlyTankSystem, PostRegisterGetAngularVelocity);
        break;
    }
    case RED4ext::EMainReason::Unload:
    {
        break;
    }
    }

    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::PluginInfo* aInfo)
{
    aInfo->name = L"Flying Tank API";
    aInfo->author = L"tidus";
    aInfo->version = RED4EXT_SEMVER(1, 0, 0);
    aInfo->runtime = RED4EXT_RUNTIME_LATEST;
    aInfo->sdk = RED4EXT_SDK_LATEST;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports()
{
    return RED4EXT_API_VERSION_LATEST;
}

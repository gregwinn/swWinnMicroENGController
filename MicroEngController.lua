--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("IdleRPS", 4)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- Incoming data from start/key
        simulator:setInputBool(1, simulator:getIsToggled(1))

        -- Incoming ENG RPS, should be a whole number only
        --simulator:setInputNumber(2, simulator:getSlider(1) * 20)
        simulator:setInputNumber(2, simulator:getSlider(1) * 10)

        -- Incoming Idle RPS (Proporty value 5 to 10) hardset to 6 for testing
        simulator:setInputNumber(3, 6)

        -- Incoming Throttle
        simulator:setInputNumber(4, simulator:getSlider(3))

        -- Engine Air Volume
        simulator:setInputNumber(5, 0)
        -- Engine Fuel Volume
        simulator:setInputNumber(6, 0)
        -- Engine Temp
        simulator:setInputNumber(7, 0)

        -- Incoming Proporty AFR (Proporty value 12 to 15)
        simulator:setInputNumber(8, 14.2)
        -- Proporty: Start Colling at Temp
        simulator:setInputNumber(9, 70)
        -- Battery
        simulator:setInputNumber(10, simulator:getSlider(4))

        -- NEW! button/slider options from the UI
        --simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        --simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        --simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        --simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require("Helpers.counter")
require("Helpers.numbercollector")
require("Helpers.base")
require("Helpers.engine")
require("Helpers.afr")
require("Helpers.throttle")

local ticks = 0
local fuelFlowOutput = 0
local airFlowOutput = 0
local throttleOutput = 0.01
local maxThrottleValue = 1
local minIdleThrottle = 0.1
local maxRPS = 20
local Stabilize = stabilizeIdleRPS()
local engTemp = 0

local CC_drive_ready = false

function onTick()
    -- Outputs
    -- 1: ENG Starter (boolean)
    -- 2: ENG Started (boolean)
    -- 3: Fuel Flow (number)
    -- 4: Air Flow (number)
    -- 6: To Cooling Pumps/Fan (boolean)
    -- 8: To Clutch Controller
        -- 30: ENG RPS (number)
        -- 31: ENG Temp (number)
        -- 32: Drive Clutch ready (boolean)
    -- 9: Fuel Warning (boolean)
    -- 10: Tank Level  (number)
    -- 11: Testing block (number)

    -- Inputs
    -- 1: ENG Start/Key
    keyOn = input.getBool(1)
    -- 2: ENG RPS
    engRPS = input.getNumber(2)
    -- 3: Proparty: Idle RPS (5 to 10)
    idleRPS = input.getNumber(3)
    -- 4: Throttle
    throttle = input.getNumber(4)
    -- 5: Air Volume
    airVolume = input.getNumber(5)
    -- 6: Fuel Volume
    fuelVolume = input.getNumber(6)
    engAFR = getEngineAFR(airVolume, fuelVolume)
    -- 7: ENG Temp
    engTemp = input.getNumber(7)
    propAFR = input.getNumber(8)
    -- 9: Engine Temp to start cooling
    startCoolingTemp = input.getNumber(9)
    -- 30: Reserved for Clutch Info
    -- 31: Reserved for Clutch Info

    ticks = ticks + 1

    -- Determine if the engine is running
    engOn = isEngineRunning(engRPS, keyOn)
    output.setBool(2, engOn)

    if keyOn then
        engineStarterEngaged = actionStartEngine(engRPS)
        output.setBool(1, engineStarterEngaged)
    
        if throttle == 0 then
            -- Use stabilizeIdleRPS only when user throttle is 0
            throttleData = Stabilize.stabilizeIdle(engRPS, idleRPS)
            throttleOutput = throttleData.throttle
            minIdleThrottle = throttleData.minIdleThrottle
            output.setNumber(11, throttleData.rpsAVG)
            
        else
            throttleData = throttleController(minIdleThrottle, engRPS, maxRPS, throttle, maxThrottleValue)
            throttleOutput = throttleData.throttleOutput
            maxThrottleValue = throttleData.maxThrottleValue
        end

        -- Fuel and Air Flow Adjustment
        fuelFlowOutput = updateAFRControl(propAFR, airFlowOutput)
        airFlowOutput = throttleOutput
    
        -- Output Values
        output.setNumber(3, fuelFlowOutput)
        output.setNumber(4, airFlowOutput)

        -- Cooling Logic
        if engTemp > startCoolingTemp then
            output.setBool(6, true)
        else
            output.setBool(6, false)
        end

        -- Clutch
        output.setNumber(30, engRPS)
        output.setNumber(31, engTemp)
        output.setBool(32, CC_drive_ready)
    else
        -- Engine Off Logic
        fuelFlowOutput, airFlowOutput = 0, 0
        throttleOutput = 0.01
        CC_drive_ready = false
        output.setNumber(3, 0)
        output.setNumber(4, 0)
    end
    
end


function onDraw()
    
end
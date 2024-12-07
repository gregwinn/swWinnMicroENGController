-- RPS Controls
local adjustedThrottle = 0
local RPS_microAdjustment1 = 0.000008
local RPS_microAdjustment2 = 0.000005
local RPS_microAdjustment3 = 0.000002
local RPS_deadband1 = 1
local RPS_deadband2 = 0.4
local RPS_deadband3 = 0.1
local RPS_Values = newNumberCollector(20)
local Throttle_Values = newNumberCollector(10)
local RPS_to_Throttle_values = { 
    [5] = 0.185, 
    [6] = 0.186, 
    [7] = 0.187, 
    [8] = 0.189, 
    [9] = 0.191, 
    [10] = 0.193 
}
RPS_to_Throttle_boost = 1.10
local RPS_to_Throttle_setup_count = 0

local Throttle_ticks = 0

-- Electric Engine Boost Logic
local electricEngine = 0

-- Update Fuel Flow for AFR Control
--- Adjusts fuel flow to maintain the target AFR using a PI controller.
---@param targetAFR number Desired AFR
---@param airFlow number Measured air intake volume
---@return number Adjusted fuel flow factor
function updateAFRControl(targetAFR, airFlow)
    local ratio = targetAFR / 7.05
    local targetFuelFlow = airFlow / ratio
    
    return targetFuelFlow
end

-- Stabilize Idle RPS
---@return table: Adjusted throttle value and electric engine boost, and minimumIdleThrottle
function stabilizeIdleRPS()
    return {
        init = function(idleRPS)
            if RPS_to_Throttle_setup_count == 0 then
                RPS_to_Throttle_setup_count = 1
                adjustedThrottleCounter = newUpDownCounter(RPS_to_Throttle_values[idleRPS] * RPS_to_Throttle_boost,  0.0000001, 1, 0.00004)
            end
        end,
        stabilizeIdle = function(currentRPS, targetRPS)
            local stabilizationFactor = 0.05
            Throttle_ticks = Throttle_ticks + 1
            local deadbandLevels = {
                {range = RPS_deadband3, adjustment = RPS_microAdjustment3, name = "deadband3"},
                {range = RPS_deadband2, adjustment = RPS_microAdjustment2, name = "deadband2"},
                {range = RPS_deadband1, adjustment = RPS_microAdjustment1, name = "deadband1"}
            }
        
            -- Check which deadband the current RPS falls into
            for _, level in ipairs(deadbandLevels) do
                local deltaRPS = math.abs(currentRPS - targetRPS)
                if deltaRPS <= level.range then
                    -- Avoid oscillation within the stabilization factor
                    if deltaRPS > stabilizationFactor then
                        if currentRPS < targetRPS then
                            adjustedThrottleCounter.microAdjustmentUp(adjustedThrottleCounter, level.adjustment)
                        elseif currentRPS > targetRPS then
                            adjustedThrottleCounter.microAdjustmentDown(adjustedThrottleCounter, level.adjustment)
                        end
                    end
        
                    -- Record RPS and Throttle Values for trends
                    RPS_Values.addNumber(RPS_Values, currentRPS)
                    Throttle_Values.addNumber(Throttle_Values, adjustedThrottleCounter.getValue(adjustedThrottleCounter))
        
                    -- Set adjusted throttle based on average or fallback
                    adjustedThrottleCounter.setValue(adjustedThrottleCounter, Throttle_Values.getAverage(Throttle_Values) or RPS_to_Throttle_values[idleRPS])
                    adjustedThrottle = adjustedThrottleCounter.getValue(adjustedThrottleCounter)
                    break -- Exit loop after finding the applicable deadband
                end
            end
            
            -- Give the ENG time to start up given the preset throttle value
            -- Handle cases outside the deadbands
            if Throttle_ticks > 240 then
                if currentRPS > targetRPS then
                    adjustedThrottleCounter.decrement(adjustedThrottleCounter)
                elseif currentRPS < targetRPS then
                    adjustedThrottleCounter.increment(adjustedThrottleCounter)
                end
            end
            
        
            adjustedThrottle = adjustedThrottleCounter.getValue(adjustedThrottleCounter)
        
            return {
                throttle = adjustedThrottle,
                electricEngine = electricEngine,
                minIdleThrottle = Throttle_Values.getAverage(Throttle_Values),
                rpsAVG = RPS_Values.getAverage(RPS_Values)
            }
        end
    }
end


-- Is AFR Within Range
--- Checks if the current AFR is within a specified tolerance of the target AFR.
---@param engineAFR number Current measured AFR
---@param targetAFR number Desired AFR
---@param tolerance number Allowed tolerance for the AFR
---@return boolean True if AFR is within the range, otherwise false
function isAFRWithinRange(engineAFR, targetAFR, tolerance)
    return math.abs(engineAFR - targetAFR) <= tolerance
end

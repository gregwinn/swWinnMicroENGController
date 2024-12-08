-- RPS Controls

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
        stabilizeIdle = function(currentRPS, targetRPS)
            local setPidTable = {
                Kp = 0.2,
                Ki = 0,
                Kd = 0
            }
            local adjustedThrottle = pidController(targetRPS, currentRPS, 0, setPidTable)
            adjustedThrottle = clamp(adjustedThrottle, 0, 1)
            Throttle_Values.addNumber(Throttle_Values, adjustedThrottle)
            RPS_Values.addNumber(RPS_Values, currentRPS)
        
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

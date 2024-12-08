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

function throttleController(currentRPS, targetRPS, allowIdle)
    targetRPS = targetRPS + 1
    local setPidTable = {
        Kp = 0.2,
        Ki = 0,
        Kd = 0
    }
    local adjustedThrottle = pidController(targetRPS, currentRPS, 0, setPidTable)
    adjustedThrottle = clamp(adjustedThrottle, 0, 1)

    if allowIdle then
        -- For idle only
        Throttle_Values.addNumber(Throttle_Values, adjustedThrottle)
        RPS_Values.addNumber(RPS_Values, currentRPS)
    end

    return {
        throttle = adjustedThrottle,
        minIdleThrottle = Throttle_Values.getAverage(Throttle_Values) or 0,
        rpsAVG = RPS_Values.getAverage(RPS_Values) or 0
    }
end
local adjustedThrottle = 0
local Throttle_maxValue = newNumberCollector(10)
local Throttle_counter = newUpDownCounter(0.01, 0.0000001, 1, 0.01)
--Throttle_maxValue.setInitalValues(Throttle_maxValue, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1})

function throttleController(minIdleThrottle, engRPS, maxRPS, throttle, maxThrottleValue)
    local Throttle_adjustment_trigger = false
    Throttle_counter.minValue = minIdleThrottle
    local deadbandLevels = {
        {range = 0.5, adjustment = 0.000001},
        {range = 1, adjustment = 0.00001},
        {range = 5, adjustment = 0.0001}
    }
    if throttle < minIdleThrottle then
        -- If throttle is below the minimum idle throttle, set it to the minimum idle throttle
        throttleOutput = minIdleThrottle
    else
        for _, level in ipairs(deadbandLevels) do
            if math.abs(engRPS - maxRPS) <= level.range then
                if engRPS < maxRPS then
                    Throttle_counter.microAdjustmentUp(Throttle_counter, level.adjustment)
                    --throttleOutput = throttleOutput + level.adjustment
                elseif engRPS > maxRPS then
                    Throttle_counter.microAdjustmentDown(Throttle_counter, level.adjustment)
                    --throttleOutput = throttleOutput - level.adjustment
                end
            end

            Throttle_maxValue.addNumber(Throttle_maxValue, Throttle_counter.getValue(Throttle_counter))
            Throttle_counter.setValue(Throttle_counter, Throttle_maxValue.getAverage(Throttle_maxValue))
            adjustedThrottle = Throttle_counter.getValue(Throttle_counter)
            Throttle_adjustment_trigger = true
            break
        end
        
        -- Out of deadband range
        if not Throttle_adjustment_trigger then
            if engRPS > maxRPS then
                Throttle_counter.decrement(Throttle_counter)
                --throttleOutput = minIdleThrottle
            else
                Throttle_counter.increment(Throttle_counter)
                --throttleOutput = throttle
            end
            adjustedThrottle = Throttle_counter.getValue(Throttle_counter)
        end
    end

    return {
        throttleOutput = throttleOutput,
        maxThrottleValue = Throttle_maxValue.getAverage(Throttle_maxValue)
    }
end
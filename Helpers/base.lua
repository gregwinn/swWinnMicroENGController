-- PID Controller
-- @param setPoint number: The target value we want to achieve (e.g., target RPS)
-- @param processVariable number: The current value of the system (e.g., current RPS)
-- @param dt number: Time elapsed since the last update (in seconds)
-- @param pidTable table: Table containing PID parameters and state (Kp, Ki, Kd, integral, prevError)
-- @return number: The output value to adjust the system (e.g., throttle adjustment)
function pidController(setPoint, processVariable, dt, pidTable)
    -- Extract PID parameters
    local Kp = pidTable.Kp or 0
    local Ki = pidTable.Ki or 0
    local Kd = pidTable.Kd or 0

    -- Initialize state if not already done
    pidTable.integral = pidTable.integral or 0
    pidTable.prevError = pidTable.prevError or 0

    -- Calculate error
    local error = setPoint - processVariable

    -- Proportional term
    local proportional = Kp * error

    -- Integral term
    pidTable.integral = pidTable.integral + error * dt
    local integral = Ki * pidTable.integral

    -- Derivative term
    local derivative = 0
    if dt > 0 then
        derivative = Kd * (error - pidTable.prevError) / dt
    end

    -- Update previous error
    pidTable.prevError = error

    -- Combine terms to produce output
    return proportional + integral + derivative
end

function round(num, decimalPlaces)
    local multiplier = 10^(decimalPlaces or 0)
    return math.floor(num * multiplier + 0.5) / multiplier
end

-- Up-Down Counter function with min, max values and reset
function createAFRCounter(start, step, min, max)
    local count = start or 0
    local increment = step or 1
    local minValue = min or -math.huge  -- Default to negative infinity if min is not provided
    local maxValue = max or math.huge   -- Default to positive infinity if max is not provided

    return {
        up = function()
            count = count + increment
            if count > maxValue then
                count = maxValue
            end
            return count
        end,
        down = function()
            count = count - increment
            if count < minValue then
                count = minValue
            end
            return count
        end,
        reset = function(newStart)
            count = newStart or 0
        end,
        get = function()
            return count
        end
    }
end

-- Min-Max function
---@param value number
---@param min_value number
---@param max_value number
---@return number
function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    elseif value > max_value then
        return max_value
    else
        return value
    end
end

-- Adjusts clutch engagement using a PID controller.
---@param currentClutch number: The current clutch engagement value (0 to 1).
---@param dt number: Time elapsed since the last update (in seconds).
---@param pidClutch table: Table containing PID parameters and state for the clutch (Kp, Ki, Kd, integral, prevError).
---@return number: The new clutch engagement value (0 to 1).
function actionClutch(currentClutch, dt, pidClutch)
    -- Target clutch engagement is always 1 (fully engaged)
    -- Calculate the PID output for clutch engagement
    local clutchAdjustment = pidController(1, currentClutch, dt, pidClutch)

    -- Clamp the clutch value between 0 (not engaged) and 1 (fully engaged)
    return math.max(0, math.min(1, currentClutch + clutchAdjustment))
end

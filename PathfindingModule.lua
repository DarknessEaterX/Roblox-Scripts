local PathfindingModule = {
    PathfindingService = game:GetService("PathfindingService"),
    ActivePath = nil,
    RecalculationThreshold = 0.5, -- meters deviation before recalculating
    LastCalculationTime = 0,
    CalculationCooldown = 0.2 -- seconds between recalculations
}

function PathfindingModule:ComputePath(start, goal, agentParams)
    -- Apply dynamic agent parameters based on character capabilities
    local agentParameters = {
        AgentRadius = agentParams.Radius or 2,
        AgentHeight = agentParams.Height or 5,
        AgentCanJump = agentParams.CanJump or true,
        AgentCanClimb = agentParams.CanClimb or true,
        WaypointSpacing = agentParams.WaypointSpacing or 4,
        Costs = {
            Water = agentParams.WaterCost or 10,
            Lava = math.huge -- Always avoid deadly terrain
        }
    }
    
    -- Special handling for moving platforms
    if self:IsPositionOnMovingPlatform(goal) then
        -- Extend path beyond platform to account for movement
        local platformVelocity = self:GetPlatformVelocityAtPosition(goal)
        local projectedGoal = goal + platformVelocity * 0.5 -- Project 0.5 seconds ahead
        goal = projectedGoal
    end
    
    local success, path = pcall(function()
        return self.PathfindingService:CreatePath(agentParameters)
    end)
    
    if not success then
        warn("Path creation failed:", path)
        return nil
    end
    
    success, err = pcall(function()
        path:ComputeAsync(start, goal)
    end)
    
    if not success then
        warn("Path computation failed:", err)
        return nil
    end
    
    if path.Status ~= Enum.PathStatus.Success then
        warn("Path status:", path.Status)
        return nil
    end
    
    self.ActivePath = path
    self.LastCalculationTime = os.clock()
    return path
end

function PathfindingModule:ShouldRecalculate(currentPosition, goalPosition)
    if not self.ActivePath then return true end
    
    -- Check if we've deviated significantly from the path
    local closestWaypoint = self:GetClosestWaypoint(currentPosition)
    if (currentPosition - closestWaypoint.Position).Magnitude > self.RecalculationThreshold then
        return true
    end
    
    -- Check if goal has moved significantly
    if (goalPosition - self.ActivePath.EndPosition).Magnitude > self.RecalculationThreshold then
        return true
    end
    
    -- Enforce cooldown between recalculations
    if os.clock() - self.LastCalculationTime < self.CalculationCooldown then
        return false
    end
    
    return false
end
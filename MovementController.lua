local MovementController = {
    MoveToTimeout = 1, -- seconds before considering a move command failed
    LastMoveToTime = 0,
    StuckDetectionThreshold = 0.2, -- meters movement in this time to consider stuck
    StuckTimeWindow = 0.5 -- seconds to check for stuck condition
}

function MovementController:MoveToWaypoint(character, waypoint, agentParams)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    -- Check if we need to jump
    local currentPos = character:GetPivot().Position
    local heightDifference = waypoint.Position.Y - currentPos.Y
    
    if heightDifference > agentParams.JumpThreshold then
        humanoid.Jump = true
    end
    
    -- Special handling for moving platforms
    if self:IsPositionOnMovingPlatform(waypoint.Position) then
        local platform = self:GetPlatformAtPosition(waypoint.Position)
        local platformVelocity = platform:GetVelocity()
        local adjustedPosition = waypoint.Position + platformVelocity * 0.3 -- Lead the platform
        humanoid:MoveTo(adjustedPosition)
    else
        humanoid:MoveTo(waypoint.Position)
    end
    
    self.LastMoveToTime = os.clock()
    return true
end

function MovementController:IsCharacterStuck(character)
    local currentPos = character:GetPivot().Position
    local positions = self:GetRecentPositions(character) -- Would track last few positions
    
    -- Check if we've moved significantly in the last time window
    local totalMovement = 0
    for i = 1, #positions - 1 do
        totalMovement += (positions[i+1] - positions[i]).Magnitude
    end
    
    return totalMovement < self.StuckDetectionThreshold
end

function MovementController:HandleStuckSituation(character, waypoint)
    -- Try jumping if not already
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    humanoid.Jump = true
    
    -- Attempt to path around obstacle
    return "RecalculateNeeded"
end
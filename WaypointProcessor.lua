local WaypointProcessor = {
    MinWaypointDistance = 1.5, -- meters
    HeightTolerance = 0.3, -- meters for considering waypoints at same height
    LookaheadDistance = 3 -- how many waypoints ahead to consider
}

function WaypointProcessor:SimplifyWaypoints(originalWaypoints)
    local simplified = {}
    local prevWaypoint = originalWaypoints[1]
    table.insert(simplified, prevWaypoint)
    
    for i = 2, #originalWaypoints - 1 do
        local current = originalWaypoints[i]
        local next = originalWaypoints[i+1]
        
        -- Check if we can skip this waypoint
        local isStraightPath = self:IsStraightPath(prevWaypoint.Position, next.Position)
        local isSimilarHeight = math.abs(current.Position.Y - prevWaypoint.Position.Y) < self.HeightTolerance
        
        if not isStraightPath or not isSimilarHeight then
            table.insert(simplified, current)
            prevWaypoint = current
        end
    end
    
    -- Always include the final waypoint
    table.insert(simplified, originalWaypoints[#originalWaypoints])
    return simplified
end

function WaypointProcessor:IsStraightPath(start, finish)
    -- Raycast to check for obstacles in a straight line
    local direction = (finish - start).Unit
    local distance = (finish - start).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(start, direction * distance, raycastParams)
    return not raycastResult -- No hit means straight path
end

function WaypointProcessor:GetNextTargetWaypoint(currentPosition, waypoints)
    -- Find the furthest visible waypoint we can path to directly
    for i = math.min(#waypoints, self.LookaheadDistance), 1, -1 do
        if self:IsStraightPath(currentPosition, waypoints[i].Position) then
            return waypoints[i], i
        end
    end
    return waypoints[1], 1 -- Fallback to first waypoint
end
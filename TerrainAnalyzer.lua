local TerrainAnalyzer = {
    AnalysisRadius = 8, -- meters around character to analyze
    HazardTag = "Deadly", -- CollectionService tag for deadly surfaces
    SlopeThreshold = math.rad(45) -- max walkable slope in radians
}

function TerrainAnalyzer:AnalyzeSurroundings(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return {} end
    
    local position = rootPart.Position
    local results = {
        Hazards = {},
        MovingPlatforms = {},
        SteepSlopes = {},
        JumpObstacles = {}
    }
    
    -- Check for hazards in area
    local region = Region3.new(
        position - Vector3.new(self.AnalysisRadius, self.AnalysisRadius, self.AnalysisRadius),
        position + Vector3.new(self.AnalysisRadius, self.AnalysisRadius, self.AnalysisRadius)
    )
    
    local parts = workspace:FindPartsInRegion3(region, character, 100)
    
    for _, part in ipairs(parts) do
        -- Hazard detection
        if part:GetAttribute(self.HazardTag) or part:FindFirstChild(self.HazardTag) then
            table.insert(results.Hazards, part)
        end
        
        -- Moving platform detection
        if part:GetAttribute("IsMovingPlatform") or part:FindFirstChild("MovingPlatformScript") then
            local velocity = part.AssemblyLinearVelocity
            if velocity.Magnitude > 0.1 then
                results.MovingPlatforms[part] = velocity
            end
        end
        
        -- Slope analysis
        local normal = part.CFrame.UpVector
        local angle = math.acos(normal:Dot(Vector3.new(0, 1, 0)))
        if angle > self.SlopeThreshold then
            table.insert(results.SteepSlopes, {
                Part = part,
                Angle = angle
            })
        end
    end
    
    -- Jump obstacle detection (raycast upwards)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(
        position,
        Vector3.new(0, 10, 0), -- Check 10m up
        raycastParams
    )
    
    if raycastResult then
        results.OverheadObstacle = raycastResult.Position.Y - position.Y
    end
    
    return results
end

function TerrainAnalyzer:IsPositionSafe(position)
    -- Check for hazards at specific position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(
        position + Vector3.new(0, 3, 0), -- Start slightly above
        Vector3.new(0, -5, 0), -- Look 5m down
        raycastParams
    )
    
    if raycastResult then
        local part = raycastResult.Instance
        return not (part:GetAttribute(self.HazardTag) or part:FindFirstChild(self.HazardTag))
    end
    
    return false -- No ground is also unsafe
end
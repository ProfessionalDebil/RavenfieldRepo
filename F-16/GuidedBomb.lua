behaviour("GuidedBomb") --v1.1.0

function GuidedBomb:Init(guidanceTarget, turnRate, isLaserGuided, laserTrackerManager)
    self.projectile = self.gameObject.GetComponent(Projectile)
    self.transform = self.gameObject.transform
    self.turnRate = turnRate
    self.isLaserGuided = isLaserGuided

    if self.isLaserGuided then
        self.code = guidanceTarget
    else
        self.target = guidanceTarget
    end

    self.laserTrackerManager = laserTrackerManager
end

function GuidedBomb:Update()
    local target = nil

    if self.isLaserGuided and self.laserTrackerManager then
        target = self.laserTrackerManager:Get(self.code)
    elseif self.isLaserGuided then
        target = self.target.transform.position
    else
        target = self.target
    end

    if self.projectile == nil or not (target) then
        return
    end

    local range = (target - self.transform.position).sqrMagnitude

    if range <= 120000 then
        local velocity = self.projectile.velocity.magnitude

        self.projectile.velocity = Vector3.RotateTowards(self.projectile.velocity / velocity, (target - self.transform.position).normalized, self.turnRate * Time.deltaTime, 0) * velocity
    end
end

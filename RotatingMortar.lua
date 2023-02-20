behaviour("RotatingMortar")

function RotatingMortar:Start()
    self.indicator = self.targets.indicator.transform
    self.bearing = self.targets.bearing.transform
    self.pitch = self.targets.pitch.transform

    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.minAngle = self.dataContainer.GetFloat("minAngle")
    self.maxAngle = self.dataContainer.GetFloat("maxAngle")
    self.minRange = self.dataContainer.GetFloat("minRange")
    self.maxRange = self.dataContainer.GetFloat("maxRange")
    self.rangeDelta = self.maxRange - self.minRange
    self.angleDelta = self.maxAngle - self.minAngle
end

function RotatingMortar:Update()
    -- calculate bearing rotation
    local bearingTarget = self.indicator.position
    bearingTarget.y = self.bearing.position.y

    self.bearing.LookAt(bearingTarget)

    local range = Vector3.Distance(self.bearing.position, bearingTarget) - self.minRange
    local ratio = range / self.rangeDelta
    local angle = ratio * self.angleDelta + self.minAngle

    self.pitch.localEulerAngles = Vector3(angle, 0, 0)
end
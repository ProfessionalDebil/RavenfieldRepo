behaviour("LookAtCCIP") --v1.1.1

function LookAtCCIP:Start()
    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    if self.targets.gun ~= nil then
        self.gun = self.targets.gun.GetComponent(Weapon)
    end
    self.ballisticCalculator = self.targets.ballisticCalculator.GetComponent(ScriptedBehaviour).self
    if self.targets.fcr then
        self.fcr = self.targets.fcr.GetComponent(ScriptedBehaviour).self
    end
    self.avionics = self.targets.avionics.GetComponent(ScriptedBehaviour).self
    self.heightChecker = self.targets.heightChecker.GetComponent(ScriptedBehaviour).self
    self.ring = self.targets.ring.transform
    if self.targets.line ~= nil then
        self.line = self.targets.line.GetComponent(LineRenderer)
        self.origin = self.targets.origin.transform
        self.lineRange = self.dataContainer.GetFloat("lineRange")
    end

    self.muzzle = self.targets.muzzle.transform
    self.projectileSpeed = self.dataContainer.GetFloat("projectileSpeed")

    self.skip = true
    self.targetPoint = Vector3.zero
end

function LookAtCCIP:Update()
    if self.line then
        self.line.SetPosition(0, self.origin.position)
        self.line.SetPosition(1, self.ring.position + self.ring.forward * self.lineRange)
    end

    if self.gun then
        if not (self.gun.activeSightModeIndex == 1) then
            self.ring.localRotation = Quaternion.identity
            if self.line then
                self.line.SetPosition(0, self.ring.position + self.ring.forward * self.lineRange)
            end
            return
        end
    end

    self.skip = not self.skip

    if self.skip then
        return
    end

    if self.fcr then
        if self.fcr.hasTarget then
            self.targetPoint = self.ballisticCalculator:GetCCIPPosition(self.muzzle.position, self.fcr.lockedTargetTransform.position, self.avionics.rigidbody.velocity + self.muzzle.forward * self.projectileSpeed, false)
        elseif self.fcr.hasTargetPoint then
            self.targetPoint = self.ballisticCalculator:GetCCIPPosition(self.muzzle.position, self.fcr.lockedPoint, self.avionics.rigidbody.velocity + self.muzzle.forward * self.projectileSpeed, false)
        end
    else
        self.targetPoint = self.ballisticCalculator:GetCCIPPosition(self.muzzle.position, self.heightChecker.height, self.avionics.rigidbody.velocity + self.muzzle.forward * self.projectileSpeed, true)
    end

    self.ring.LookAt(self.targetPoint, self.muzzle.up)
end

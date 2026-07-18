behaviour("SimpleGuidedBombMaster") --v1.1.0

function SimpleGuidedBombMaster:Start()
    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.lookAtCCIP = self.targets.lookAtCCIP.GetComponent(ScriptedBehaviour).self

    self.searchRange = self.dataContainer.GetFloat("searchRange")
    self.turnRate = Mathf.Pow(self.dataContainer.GetFloat("turnRate"), 2)

    self.weapon = self.gameObject.GetComponent(Weapon)
    self.weapon.onSpawnProjectiles.AddListener(self, "OnFire")

    if self.targets.ring then
        self.ring = self.targets.ring.transform
    end

    if self.targets.lookAtCCIPRing then
        self.lookAtCCIPRing = self.targets.lookAtCCIPRing.transform
    end

    self.target = nil
    self.transform = self.gameObject.transform
    self.noTargetRotation = Quaternion.Euler(90, 0, 0)
end

function SimpleGuidedBombMaster:Update()
    self.target = nil

    for i, vehicle in pairs(ActorManager.vehicles) do
        local sqrDistance = (vehicle.transform.position - self.lookAtCCIP.targetPoint).sqrMagnitude

        if sqrDistance <= self.searchRange then
            self.target = vehicle
            break
        end
    end

    if self.target then
        self.ring.LookAt(self.target.transform.position, self.transform.up)

        if self.targets.lookAtCCIPRing then
            self.lookAtCCIPRing.localRotation = self.noTargetRotation
        end
    else
        self.ring.localRotation = self.noTargetRotation
    end
end

function SimpleGuidedBombMaster:OnFire(projectile)
    if self.target == nil then
        return
    end

    local projScript = projectile[1].gameObject.GetComponent(ScriptedBehaviour).self

    projScript:Init(self.target, self.turnRate, true, nil)
end

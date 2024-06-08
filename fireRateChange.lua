behaviour("fireRateChange")

function fireRateChange:Start()
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    self.fireRateChange = self.dataContainer.GetFloat("fireRateChange")
    self.fireRateRestoreSpeed = self.dataContainer.GetFloat("fireRateRestoreSpeed")
    self.fireRateCap = self.dataContainer.GetFloat("fireRateCap")

    self.wpn = self.targets.weapon.GetComponent(Weapon)
    self.wpn.onSpawnProjectiles.AddListener(self, "OnFire")
    self.originalCooldown = self.wpn.cooldown

    self.lowestCooldown = Mathf.Min(self.fireRateCap, self.originalCooldown)
    self.highestCooldown = Mathf.Max(self.fireRateCap, self.originalCooldown)
end

function fireRateChange:OnFire()
    self.wpn.cooldown = self.wpn.cooldown - self.fireRateChange

    self.wpn.cooldown = Mathf.Clamp(self.wpn.cooldown, self.lowestCooldown, self.highestCooldown)
end

function fireRateChange:Update()
    if not Input.GetKeyBindButton(KeyBinds.Fire) then
        self.wpn.cooldown = Mathf.MoveTowards(self.wpn.cooldown, self.originalCooldown, self.fireRateRestoreSpeed * Time.deltaTime)
    end
end
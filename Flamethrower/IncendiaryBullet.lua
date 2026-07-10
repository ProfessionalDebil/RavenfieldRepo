behaviour("IncendiaryBullet") --v1.0.0

function IncendiaryBullet:Init(vehicle, projectile)
    self.dataContainer = self.targets.dataContainer

    self.projectile = projectile
    self.target = vehicle

    self.damagePerSecond = self.dataContainer.GetFloat("damagePerSecond")

    self.init = true
end

function IncendiaryBullet:Update()
    if self.init then
        self.target:Damage(self.projectile.killCredit, self.damagePerSecond * Time.deltaTime)
    end
end

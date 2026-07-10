behaviour("StickyProjectile") -- v1.1.1

function StickyProjectile:Start()
    self.dataContainer = self.targets.dataContainer
    self.projectile = self.targets.projectile
    self.incendiaryBullet = self.targets.incendiaryBullet

    self.radius = self.dataContainer.GetFloat("radius")

    self.hit = false

    self.position = Vector3.zero
    self.rotation = Quaternion.identity
end

function StickyProjectile:Update()
    if ((self.projectile.velocity.sqrMagnitude <= 0.001) or ((not self.projectile.isActive) and (not self.projectile.isGrenadeProjectile))) and not self.hit then
        local colliders = Physics.OverlapSphere(self.projectile.transform.position, self.radius, 4353)

        self.position = self.projectile.transform.localPosition
        self.rotation = self.projectile.transform.localRotation

        if colliders[1] then
            self.projectile.transform.parent = colliders[1].transform
            self.position = self.projectile.transform.localPosition
            self.rotation = self.projectile.transform.localRotation

            if self.incendiaryBullet then
                local vehicleScript = colliders[1].transform.root.gameObject.GetComponent(Vehicle)
    
                if vehicleScript then
                    if vehicleScript.armorDamagedBy == ArmorRating.SmallArms then
                        self.incendiaryBullet.self:Init(vehicleScript, self.projectile)
                    end
                end
            end
        end

        self.hit = true
    end

    if self.hit then
        self.projectile.transform.localPosition = self.position
        self.projectile.transform.localRotation = self.rotation
        self.projectile.velocity = Vector3.zero
    end
end

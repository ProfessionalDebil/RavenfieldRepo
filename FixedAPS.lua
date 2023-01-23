behaviour("FixedAPS")

function FixedAPS:Start()
    self.vehicle = self.targets.vehicleObject.GetComponent(Vehicle)
    self.vehicleTransform = self.vehicle.transform
    self.accelComponent = self.vehicle.gameObject.GetComponent(Car)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    for i, actor in pairs(ActorManager.actors) do
        self:onActorSpawn(actor)
    end

    for i, vehicle in pairs(ActorManager.vehicles) do
        self:onVehicleSpawn(vehicle)
    end

    GameEvents.onActorSpawn.AddListener(self, "onActorSpawn")
    GameEvents.onVehicleSpawn.AddListener(self, "onVehicleSpawn")
    self.projectilesWatched = {}

    self.isLoading = false

    -- values
    -- load duration per ammo
    self.loadDuration = self.dataContainer.GetFloat("loadDuration")
    -- load keybind
    self.loadKeybind = self.dataContainer.GetString("loadKeybind")
    -- APS cone radius
    self.arcRadius = self.dataContainer.GetFloat("apsCone")
    -- APS range
    self.range = self.dataContainer.GetFloat("apsRange")

    self.allAps = {}
    self.apsIndex = {}
    self.apsParticle = {}
    self.apsTransform = {}

    for i, aps in pairs(self.dataContainer.GetGameObjectArray("aps")) do
        self.allAps[i] = aps
        self.apsIndex[aps] = i
        self.apsParticle[i] = aps.GetComponentInChildren(ParticleSystem)
        self.apsTransform[i] = aps.transform
    end

    self.availableAps = self.allAps

    self.apsReloadImmobilize = false
    if self.dataContainer.HasBool("reloadImmobilize") then
        self.apsReloadImmobilize = self.dataContainer.GetBool("reloadImmobilize")
    end

    self.full = Color(0, 255, 0)
    self.empty = Color(255, 0, 0)

    self.imageIndicators = {}
    
    for i, indicator in pairs(self.dataContainer.GetGameObjectArray("indicator")) do
        self.imageIndicators[i] = indicator.GetComponent(Image)
    end

    self.accel = self.accelComponent.acceleration
    self.turnTorque = self.accelComponent.baseTurnTorque

    self.teams = {}
    self.teams[-1] = Team.Neutral
    self.teams[0] = Team.Blue
    self.teams[1] = Team.Red
end

function FixedAPS:onStartLoad()
    if self.isLoading then
        return
    end
    self.script.StartCoroutine("LoadAPS")
end

function FixedAPS:LoadAPS()
    self.isLoading = true

    local ammoDelta = 0

    for i, aps in pairs(self.availableAps) do
        if aps == 0 then
            ammoDelta = ammoDelta + 1
        end
    end

    if ammoDelta == 0 then
        return
    end

    local loadDuration = self.loadDuration * ammoDelta

    local timePassed = 0

    if self.apsReloadImmobilize then
        self.accelComponent.acceleration = 0
        self.accelComponent.baseTurnTorque = 0
    end

    coroutine.yield(WaitForSeconds(loadDuration))

    for i, indicator in pairs(self.imageIndicators) do
        indicator.color = self.full
    end
        
    self.availableAps = self.allAps
    self.accelComponent.acceleration = self.accel
    self.accelComponent.baseTurnTorque = self.turnTorque
    self.isLoading = false
end

function FixedAPS:onActorSpawn(actor)
    for i, weapon in pairs(actor.weaponSlots) do
        if tostring(weapon) == "SQUAD LEADER KIT (SquadLeaderKit)" then
            return
        end
        local weaponRole = weapon.GenerateWeaponRoleFromStats()
        if weaponRole == WeaponRole.RocketLauncher or weaponRole == WeaponRole.MissileLauncher then
            weapon.onSpawnProjectiles.AddListener(self, "onProjectileSpawned")
        end
    end
end

function FixedAPS:onVehicleSpawn(vehicle)
    for i, seat in pairs(vehicle.seats) do
        for l, weapon in pairs(seat.weapons) do
            if weapon == nil then
                return
            end
            local weaponRole = weapon.GenerateWeaponRoleFromStats()
            if weaponRole == WeaponRole.RocketLauncher or weaponRole == WeaponRole.MissileLauncher then
                weapon.onSpawnProjectiles.AddListener(self, "onProjectileSpawned")
            end
        end
    end
end

function FixedAPS:onProjectileSpawned(proj)
    for i, projectile in pairs(proj) do
        if projectile.source.team ~= self.teams[self.vehicle.team] then
            table.insert(self.projectilesWatched, projectile)
        end
    end
end

function FixedAPS:Update()
    if Input.GetKeyDown(self.loadKeybind) then
        self:onStartLoad()
    end

    for i = 1, #self.projectilesWatched do
        local proj = self.projectilesWatched[i]
        if proj ~= nil then
            if not proj.gameObject.activeSelf then
                table.remove(self.projectilesWatched, i)
            end
            if proj == self.counterProj then
                counterProj = nil
            end
        else 
            table.remove(self.projectilesWatched, i)
        end
    end

    if #self.availableAps > 0 then
        local projInRange = {}
        local projIndex = {}
        for i, proj in pairs(self.projectilesWatched) do -- get all projectile in range
            local projectileDistance = Vector3.Distance(self.vehicle.transform.position, proj.transform.position)
            if projectileDistance <= self.range then
                projInRange[#projInRange + 1] = proj-- put all the projectile in range in list
                projIndex[#projIndex + 1] = i
            end
        end

        for i, proj in pairs(projInRange) do
            local projTransform = proj.transform
            local projDestroyed = false

            for j, apsTransform in pairs(self.apsTransform) do
                local apsGO = apsTransform.gameObject
                local apsIndex = self.apsIndex[apsGO]
                if self.availableAps[apsIndex] ~= 0 and not projDestroyed then
                    local direction = apsTransform.forward
                    local positionDelta = projTransform.position - apsTransform.position
                    local angleToProjectile = Vector3.Angle(positionDelta, direction)

                    if angleToProjectile <= self.arcRadius then
                        proj.Stop(false)
                        projDestroyed = true
                        self.apsParticle[apsIndex].Play(true)
                        self.availableAps[apsIndex] = 0

                        if self.imageIndicators[apsIndex] ~= nil then
                            self.imageIndicators[apsIndex].color = self.empty
                        end

                        table.remove(self.projectilesWatched, projIndex[i])
                        break
                    end
                end
            end
        end
    end
end

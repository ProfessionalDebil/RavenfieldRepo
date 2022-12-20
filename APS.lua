behaviour("APS")

function APS:Start()
    self.vehicle = self.targets.vehicleObject.GetComponent(Vehicle)
    self.accelComponent = self.vehicle.gameObject.GetComponent(Car)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    for i, actor in pairs(ActorManager.actors) do
        for i, weapon in pairs(actor.weaponSlots) do
            local weaponRole = weapon.GenerateWeaponRoleFromStats()
            if weaponRole == WeaponRole.RocketLauncher or weaponRole == WeaponRole.MissileLauncher then
                weapon.onSpawnProjectiles.AddListener(self, "onProjectileSpawned")
            end
        end
    end

    for i, vehicle in pairs(ActorManager.vehicles) do
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

    GameEvents.onActorSpawn.AddListener(self, "onActorSpawn")
    GameEvents.onVehicleSpawn.AddListener(self, "onVehicleSpawn")
    self.projectilesWatched = {}
    self.countering = false
    self.counterProj = nil
    self.launchEffect = self.targets.launch.GetComponent(ParticleSystem)

    self.ammoDisplayText = self.targets.ammoDisplay.GetComponent(Text)

    self.isLoading = false

    -- values
    -- load duration per ammo
    self.loadDuration = self.dataContainer.GetFloat("loadDuration")
    -- load keybind
    self.loadKeybind = self.dataContainer.GetString("loadKeybind")
    -- APS ammo
    self.apsAmmo = self.dataContainer.GetInt("apsAmmo")
    self.maxAmmo = self.apsAmmo
    -- APS rotate speed
    self.rotateSpeed = self.dataContainer.GetFloat("apsRotate")
    -- APS range
    self.range = self.dataContainer.GetFloat("apsRange")

    self.apsReloadImmobilize = false
    if self.dataContainer.HasBool("reloadImmobilize") then
        self.apsReloadImmobilize = self.dataContainer.GetBool("reloadImmobilize")
    end

    self.accel = self.accelComponent.acceleration
    self.turnTorque = self.accelComponent.baseTurnTorque
end

function APS:onStartLoad()
    if self.isLoading or (self.apsAmmo == self.maxAmmo) then
        return
    end
    self.script.StartCoroutine("LoadAPS")
end

function APS:LoadAPS()
    self.isLoading = true

    local ammoDelta = self.maxAmmo - self.apsAmmo
    local loadDuration = self.loadDuration * ammoDelta
    local timePassed = 0

    if self.apsReloadImmobilize then
        self.accelComponent.acceleration = 0
        self.accelComponent.baseTurnTorque = 0
    end

    coroutine.yield(WaitForSeconds(loadDuration))
    
    self.apsAmmo = self.apsAmmo + ammoDelta
    self.accelComponent.acceleration = self.accel
    self.accelComponent.baseTurnTorque = self.turnTorque
    self.isLoading = false
end

function APS:onActorSpawn(actor)
    for i, weapon in pairs(actor.weaponSlots) do
        local weaponRole = weapon.GenerateWeaponRoleFromStats()
        if weaponRole == WeaponRole.RocketLauncher or weaponRole == WeaponRole.MissileLauncher then
            weapon.onSpawnProjectiles.AddListener(self, "onProjectileSpawned")
        end
    end
end

function APS:onVehicleSpawn(vehicle)
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

function APS:onProjectileSpawned(proj)
    for i, projectile in pairs(proj) do
        table.insert(self.projectilesWatched, projectile)
    end
end

function APS:Update()
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
        end
    end
    
    if self.apsAmmo > 0 then
        self.ammoDisplayText.text = tostring(self.apsAmmo)
        if self.countering then
            local projPosition = self.counterProj.transform.position

            local axisPosition = self.targets.axis.transform.position
            local axisForward = self.targets.axis.transform.forward
            local axisRotation = self.targets.axis.transform.rotation

            local akkorRot = Quaternion.LookRotation(projPosition - axisPosition, self.vehicle.transform.up)
            local rot = Quaternion.RotateTowards(axisRotation, akkorRot, self.rotateSpeed * Time.deltaTime)
            local angleToUse = self.targets.axis.transform.position
            local forwardToUse = self.targets.axis.transform.forward
            self.targets.axis.transform.rotation = rot
            
            if Vector3.Angle(projPosition - angleToUse, forwardToUse) <= 4 then
                self.counterProj.Stop(false)
                self.counterProj = nil
                self.countering = false
                self.apsAmmo = self.apsAmmo - 1
                self.launchEffect.Play(true)
            end
        else
            local projInRange = {}
            for i, proj in pairs(self.projectilesWatched) do -- get all projectile in range
                local projectileDistance = Vector3.Distance(self.vehicle.transform.position, proj.transform.position)
                if projectileDistance <= self.range then
                    table.insert(projInRange, proj) -- put all the projectile in range in list
                end
            end

            for i, proj in pairs(projInRange) do
                if Vector3.Angle(self.vehicle.transform.position - proj.transform.position, proj.transform.forward) <= 7 then
                    self.counterProj = proj
                    self.countering = true
                    break
                end
            end
        end
    end
end

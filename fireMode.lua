behaviour("fireMode")

function fireMode:Start()
    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    
    self.availableModes = self:Split(self.dataContainer.GetString("FIREMODE_MODES"), " ") -- available modes: SEMI, TWO, THREE, FIVE, TEN, FIFTY, HUNDRED, AUTO
    
    if modeIndex == nil then
        modeIndex = 0
    end
    self.fireModeValues = self:Split(self.dataContainer.GetString("FIREMODE_VALUES"), " ")
    self.fireModeValues = self:Zip(self.availableModes, self.fireModeValues)

    self.shotsFired = 0
    self.wpn = self.gameObject.GetComponent(Weapon)
    self.animator = self.gameObject.GetComponent(Animator)
    self.wpn.onSpawnProjectiles.AddListener(self, "onFire")
    self.muzzleAudio = self.gameObject.GetComponent(AudioSource)

    self.firemodeAuto = self.dataContainer.HasAudioClip("FIREMODE_AUTO") and self.dataContainer.GetAudioClip("FIREMODE_AUTO") or nil
    self.firemodeSingle = self.dataContainer.HasAudioClip("FIREMODE_SINGLE") and self.dataContainer.GetAudioClip("FIREMODE_SINGLE") or nil
    self.firemodeAutoS = self.dataContainer.HasAudioClip("FIREMODE_AUTO_S") and self.dataContainer.GetAudioClip("FIREMODE_AUTO_S") or nil
    self.firemodeSingleS = self.dataContainer.HasAudioClip("FIREMODE_SINGLE_S") and self.dataContainer.GetAudioClip("FIREMODE_SINGLE_S") or nil
    if self.dataContainer.GetString("FIREMODE_SELECTORVALUES") ~= nil then
        self.selectorValues = self:Split(self.dataContainer.GetString("FIREMODE_SELECTORVALUES"), " ")
    end

    self.changeCooldown = self.dataContainer.HasString("FIREMODE_COOLDOWNS")
    if self.changeCooldown then
        self.cooldowns = {}
        for match in (self.dataContainer.GetString("FIREMODE_COOLDOWNS").." "):gmatch("(.-) ") do
            table.insert(self.cooldowns, tonumber(match))
        end
    end

    self.useTrigger = false
    if self.dataContainer.HasBool("FIREMODE_USE_TRIGGER") then
        self.useTrigger = self.dataContainer.GetBool("FIREMODE_USE_TRIGGER")
    end

    self.updateParam = false
    if self.dataContainer.HasBool("FIREMODE_UPDATE_PARAM") then
        self.updateParam = self.dataContainer.GetBool("FIREMODE_UPDATE_PARAM")
    end
    self.currentCache = modeIndex % #self.availableModes

    self.nonAutoLoopAudio = false
    if self.dataContainer.HasBool("FIREMODE_NON_AUTO_LOOP_AUDIO") then
        self.nonAutoLoopAudio = self.dataContainer.GetBool("FIREMODE_NON_AUTO_LOOP_AUDIO")
    end

    self.autoResetting = self.dataContainer.GetBool("FIREMODE_AUTORESETTING")

    self.suppressed = self.dataContainer.GetBool("FIREMODE_SUPPRESSED")
    self.forceSemi = self.dataContainer.GetBool("FIREMODE_FORCE_SEMI")

    self.animator.SetInteger("FIREMODE_SELECTORVALUES", tonumber(self.selectorValues[(modeIndex % #self.availableModes) + 1]))

    -- load keybind
    if self.dataContainer.HasString("FIREMODE_KEYBIND") then
        self.keybind = self.dataContainer.GetString("FIREMODE_KEYBIND")
    else
        self.keybind = self.dataContainer.GetString("keybind")
    end

    self.thisScriptLock = false
    self.waitUnlock = false
end

function fireMode:onFire()
    self.shotsFired = self.shotsFired + 1

    if self.shotsFired == self:hitCap() then
        self.wpn.LockWeapon()
        self.thisScriptLock = true
        --self.muzzleAudio.enabled = false
    end
end

function fireMode:UpdateAudio(isSuppressed)
    self.suppressed = isSuppressed
    if self:hitCap() ~= 1 then
        self.muzzleAudio.clip = self.firemodeAuto
        if self.suppressed then
            self.muzzleAudio.clip = self.firemodeAutoS
        end
        self.wpn.isAuto = true
        self.muzzleAudio.loop = (self:hitCap() == -1 or self.nonAutoLoopAudio)
    else
        self.muzzleAudio.clip = self.firemodeSingle
        if self.suppressed then
            self.muzzleAudio.clip = self.firemodeSingleS
        end
        self.wpn.isAuto = false
        self.muzzleAudio.loop = false
    end
end

function fireMode:changeFireMode()
    modeIndex = modeIndex + 1
    --print(tonumber(self.selectorValues[(modeIndex % #self.availableModes) + 1]))
    self.currentCache = (modeIndex % #self.availableModes) + 1
    self.animator.SetInteger("FIREMODE_SELECTORVALUES", tonumber(self.selectorValues[self.currentCache]))
    if self.useTrigger then
        self.animator.SetTrigger("FIREMODE_CHANGE")
    end
    if self.changeCooldown then
        self.wpn.cooldown = self.cooldowns[self.currentCache]
    end

    self:UpdateAudio(self.suppressed)
end

function fireMode:hitCap()
    if self.forceSemi then
        return 1
    end
    local index = modeIndex % #self.availableModes
    index = index + 1
    local fireMode = self.availableModes[index]
    return self.fireModeValues[fireMode]
end

function fireMode:OnEnable()
    if self.animator == nil then
        return
    end

    self.animator.SetInteger("FIREMODE_SELECTORVALUES", tonumber(self.selectorValues[self.currentCache]))
end

function fireMode:Update()
    local flag = self.autoResetting or self.shotsFired == self:hitCap()

    if not self.thisScriptLock and self.wpn.isLocked then
        self.waitUnlock = true
        self.wpn.LockWeapon()
    end
    
    if self.waitUnlock and not self.wpn.isLocked then
        self.waitUnlock = false
    end

    if not Input.GetKeyBindButton(KeyBinds.Fire) and flag and not self.waitUnlock then
        self.wpn.UnlockWeapon()
        self.thisScriptLock = false
        self.shotsFired = 0
    end

    if Input.GetKeyDown(self.keybind) then
        self:changeFireMode()
    end

    --if self.updateParam then
    --end
end

function fireMode:Split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function fireMode:Zip(keyArray, valueArray)
    result = {}

    if #keyArray ~= #valueArray then
        return error("Array length not the same!")
    end
    for i=1, #keyArray, 1 do
        result[keyArray[i]] = tonumber(valueArray[i])
    end
    return result
end

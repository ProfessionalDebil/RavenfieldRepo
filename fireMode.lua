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

    self.useTrigger = false
    if self.dataContainer.HasBool("FIREMODE_USE_TRIGGER") ~= nil then
        self.useTrigger = self.dataContainer.GetBool("FIREMODE_USE_TRIGGER")
    end

    self.autoResetting = self.dataContainer.GetBool("FIREMODE_AUTORESETTING")

    self.suppressed = self.dataContainer.GetBool("FIREMODE_SUPPRESSED")
    self.forceSemi = self.dataContainer.GetBool("FIREMODE_FORCE_SEMI")

    self.animator.SetInteger("FIREMODE_SELECTORVALUES", tonumber(self.selectorValues[(modeIndex % #self.availableModes) + 1]))

    -- load keybind
    self.keybind = self.dataContainer.GetString("keybind")
end

function fireMode:onFire()
    self.shotsFired = self.shotsFired + 1

    if self.shotsFired == self:hitCap() then
        self.wpn.LockWeapon()
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
    else
        self.muzzleAudio.clip = self.firemodeSingle
        if self.suppressed then
            self.muzzleAudio.clip = self.firemodeSingleS
        end
        self.wpn.isAuto = false
    end
end

function fireMode:changeFireMode()
    modeIndex = modeIndex + 1
    self.animator.SetInteger("FIREMODE_SELECTORVALUES", tonumber(self.selectorValues[(modeIndex % #self.availableModes) + 1]))
    if self.useTrigger then
        self.animator.SetTrigger("FIREMODE_CHANGE")
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

function fireMode:Update()
    local flag = self.autoResetting or self.shotsFired == self:hitCap()
    
    if not Input.GetKeyBindButton(KeyBinds.Fire) and flag then
        self.wpn.UnlockWeapon()
        self.shotsFired = 0
    end

    if Input.GetKeyDown(self.keybind) then
        self:changeFireMode()
    end
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

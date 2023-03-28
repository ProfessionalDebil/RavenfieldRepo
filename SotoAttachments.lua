behaviour("SotoAttachments")

function SotoAttachments:Start()
    self.weapon = self.targets.weaponObject.GetComponent(Weapon)
    self.animator = self.weapon.gameObject.GetComponent(Animator)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.fireMode = self.weapon.gameObject.GetComponent(ScriptedBehaviour)
    self.oneInChamber = nil
    if self.targets.oneInChamber ~= nil then
        self.oneInChamber = self.targets.oneInChamber.GetComponent(ScriptedBehaviour)
    end
    if self.fireMode == nil then
        print("Fire Mode Script not found!")
    end
    if self.oneInChamber == nil then
        print("One in Chamber Script not found!")
    end

    self.optionGrids = self:GetOptionGrids()
    self.optionImages = self:GetOptionGridImages(self.optionGrids)
    for i, button in pairs(self.optionGrids) do
        button.onClick.AddListener(self, "onGridButtonClick", i)
    end

    self.canvasEnabled = false
    self.canvasOpenTime = 2

    self.ammoPoint = nil
    self.barrelPoint = nil
    self.muzzle = nil
    self.particle = nil
    self.lasers = {}

    if pastAttachments == nil then
        pastAttachments = {}
    end

    if pastAttachments[self.weapon.weaponEntry.name] == nil then
        pastAttachments[self.weapon.weaponEntry.name] = {}
    end

    self.points = self.dataContainer.GetGameObjectArray("point")
    self.pointDatas = self:GetPointData(self.points)
    self.buttons = self.dataContainer.GetGameObjectArray("button")
    self.pointButtons = self:GetPoints(self.buttons)

    for i, button in pairs(self.pointButtons) do
        button.onClick.AddListener(self, "onPointButtonClick", i)
    end

    self.pointIcons = self:GetPointIcons(self.pointButtons)
    self.pointCaptions = self:GetPointCaptions(self.pointButtons)

    self.attachments = self:GetAttachments(self.pointDatas)

    self.effects = self:GetEffects(self.attachments)
    self.effectDatas = self:GetEffectDatas(self.effects)

    self:InitiatePoints(self.pointDatas)

    self.currentPoint = 0

    self.pointIndicator = self.targets.pointIndicator.GetComponent(Text)

    self.dualRenderCamera = nil
    if self.targets.DRCamera ~= nil then
        self.dualRenderCamera = self.targets.DRCamera.GetComponent(Camera)
    end
    self.sightIndex = 0

    self.spreadAttachment = {}
    self.baseSpread = self.weapon.baseSpread
    self.baseProneSpreadGain = self.weapon.recoilKickbackProneMultiplier

    self.script.AddValueMonitor("monitorNVG", "onUpdateNVG")

    if pastAttachments[self.weapon.weaponEntry.name] ~= {} then
        self:EquipPastAttachments()
    end

    self.keybindMutator = GameObject.Find("Soto Settings(Clone)")
    self.menuKey = "y"
    self.slow = true
    self.originalTimeScale = Time.timeScale
    if self.keybindMutator ~= nil then
        local keybindScript = self.keybindMutator.GetComponent(ScriptedBehaviour)
        self.slow = keybindScript.self.slowMo
        self.keybindMutator = string.lower(keybindScript.self.open)
        if type(self.keybindMutator) == "string" then
            self.length = #self.keybindMutator
        end
        if self.length == 1 or type(self.keybindMutator) == "userdata" then
            self.menuKey = self.keybindMutator
        end
    end
end

function SotoAttachments:monitorNVG()
    return Player.nighvisionEnabled
end

function SotoAttachments:onUpdateNVG(enabled)
    for i, laser in pairs(self.lasers) do
        laser.SetActive(enabled)
    end
end

function SotoAttachments:Update()
    if Input.GetKeyDown(self.menuKey) and not self.weapon.isReloading then
        self.canvasEnabled = not self.canvasEnabled
        self.targets.canvas.SetActive(self.canvasEnabled)

        self.animator.SetBool("customize", self.canvasEnabled)

        if self.canvasEnabled then
            self.weapon.LockWeapon()
            Screen.UnlockCursor()
            self.canvasOpenTime = Time.time
            if self.slow then
                Time.timeScale = 0.4
            end
        else
            self.weapon.UnlockWeapon()
            Screen.LockCursor()
            if self.slow then
                Time.timeScale = self.originalTimeScale
            end
        end
    end

    self.animator.SetInteger("sight", self.sightIndex)
end

function SotoAttachments:onGridButtonClick(attachmentIndex, pointIndex)
    if pointIndex == nil then
        if self.currentPoint == 0 or self.currentPoint == nil then
            return
        end

        pointIndex = self.currentPoint
    end

    if attachmentIndex == nil then
        attachmentIndex = CurrentEvent.listenerData
    end

    local attachment = self.attachments[pointIndex][attachmentIndex]
    local attachmentType = string.lower(attachment.GetString("type"))

    -- type specific edits
    if attachmentType == "sight" then
        self.animator.SetInteger("sight", attachment.GetInt("animatorValue"))

        if self.dualRenderCamera ~= nil and attachment.HasFloat("fov") then
            self.dualRenderCamera.fieldOfView = attachment.GetFloat("fov")
        end
        self.sightIndex = attachment.GetInt("animatorValue")
    elseif attachmentType == "magazine" then
        local capacity = attachment.GetInt("capacity")

        self.weapon.maxAmmo = capacity

        if self.weapon.ammo > self.weapon.maxAmmo then
            local delta = self.weapon.ammo - self.weapon.maxAmmo
            self.weapon.ammo = self.weapon.maxAmmo
            self.weapon.spareAmmo = self.weapon.spareAmmo + delta
        end

        if self.oneInChamber ~= nil then
            self.oneInChamber.self:UpdateValues(capacity)
        end

        self.animator.SetInteger("magazineType", attachment.GetInt("animatorValue"))
    elseif attachmentType == "ammo" then
        local barrelLength = "normal"
        if type(self.barrelPoint) == "userdata" then
            barrelLength = self.attachments[self.barrelPoint.x][self.barrelPoint.y].GetString("length")
        end
        self.weapon.SetProjectilePrefab(attachment.GetGameObject(barrelLength))
        self.weapon.projectilesPerShot = attachment.GetInt("projectilePerShot")

        self.ammoPoint = Vector2(pointIndex, attachmentIndex)

        if self.fireMode ~= nil then
            self.fireMode.self.forceSemi = attachment.GetBool("forceSemi")
            self.fireMode.self:UpdateAudio(self.fireMode.self.suppressed)
        end
    elseif attachmentType == "muzzle" then
        self.fireMode.self:UpdateAudio(attachment.GetBool("isSuppressed"))
        self.weapon.isLoud = attachment.GetBool("isSuppressed")

        local barrelLength = "normal"
        if type(self.barrelPoint) == "userdata" then
            barrelLength = self.attachments[self.barrelPoint.x][self.barrelPoint.y].GetString("length")
        end
        
        for i = 0, self.muzzle.transform.childCount - 1 do
            self.muzzle.transform.GetChild(i).gameObject.SetActive(false)
        end
        self.muzzle = attachment

        local variableMuzzle = self.muzzle.HasObject(barrelLength)
            
        if variableMuzzle then
            self.muzzle.GetGameObject(barrelLength).SetActive(true)
        end

        if self.particle ~= nil then
            self.particle.SetActive(false)
        end
        self.particle = attachment.GetGameObject("particle")
        if self.particle ~= nil then
            self.particle.SetActive(true)
        end
    elseif attachmentType == "barrel" then
        self.barrelPoint = Vector2(pointIndex, attachmentIndex)
        local barrelLength = attachment.GetString("length")

        if self.muzzle ~= nil then
            for i = 0, self.muzzle.transform.childCount - 1 do
                self.muzzle.transform.GetChild(i).gameObject.SetActive(false)
            end

            local variableMuzzle = self.muzzle.HasObject(barrelLength)
            
            if variableMuzzle then
                self.muzzle.GetGameObject(barrelLength).SetActive(true)
            end
        end

        self.weapon.SetProjectilePrefab(self.attachments[self.ammoPoint.x][self.ammoPoint.y].GetGameObject(barrelLength))
    elseif attachmentType == "skin" then
        attachment.GetMaterial("material").mainTexture = attachment.GetTexture("texture")
    end

    -- general edits
    if attachmentType ~= "skin" or attachmentType ~= "muzzle" then
        --i = 1, #self.attachments[self.currentPoint]
        for i, attachment in pairs(self.attachments[pointIndex]) do
            local enable = i == attachmentIndex

            attachment.gameObject.SetActive(enable)
        end
    end

    pastAttachments[self.weapon.weaponEntry.name][pointIndex] = attachmentIndex

    local hasSpread = attachment.HasFloat("spreadGain")

    if hasSpread or self.spreadAttachment[pointIndex] ~= nil then
        self.spreadAttachment[pointIndex] = hasSpread and attachment or nil

        local spread = self.baseSpread

        for i, attach in pairs(self.spreadAttachment) do
            local hasSpreadGain = attach.HasFloat("spreadGain")
            local spreadGain = hasSpreadGain and attach.GetFloat("spreadGain") or 0

            spread = spread + spreadGain
        end

        self.weapon.baseSpread = spread
    end

    if attachment.HasFloat("proneSpreadGain") then
        self.weapon.recoilKickbackProneMultiplier = self.baseProneSpreadGain + attachment.GetFloat("proneSpreadGain")
    end

    if attachment.HasString("parameterName") then
        self.animator.SetInteger(attachment.GetString("parameterName"), attachment.GetInt("parameterValue"))
    end

    self.pointIcons[pointIndex].sprite = attachment.GetSprite("icon")
    self.pointCaptions[pointIndex].text = attachment.GetString("displayName"):gsub("<br>", "\n")
end

function SotoAttachments:onPointButtonClick()
    local pointIndex = CurrentEvent.listenerData

    self.currentPoint = pointIndex

    self.pointIndicator.text = self.pointDatas[self.currentPoint].GetString("displayName"):gsub("<br>", "\n")

    local attachmentsAvailable = self.attachments[pointIndex]

    for i, grid in pairs(self.optionGrids) do
        if i > #attachmentsAvailable then
            grid.gameObject.SetActive(false)
        else
            grid.gameObject.SetActive(true)
            self.optionImages[i].sprite = attachmentsAvailable[i].GetSprite("icon")
        end
    end
end

function SotoAttachments:GetOptionGrids()
    local childCount = self.targets.optionGridContainer.transform.childCount

    local resultArray = {}

    for i = 0, childCount - 1 do
        local go = self.targets.optionGridContainer.transform.GetChild(i).gameObject.GetComponent(Button)
        if go ~= nil then
            resultArray[#resultArray + 1] = go
        end
    end

    return resultArray
end

function SotoAttachments:GetOptionGridImages(optionGrids)
    local resultArray = {}

    for i, button in pairs(optionGrids) do
        resultArray[#resultArray + 1] = button.gameObject.GetComponent(Image)
    end

    return resultArray
end

function SotoAttachments:GetPointData(points)
    resultArray = {}

    for i, point in pairs(points) do
        resultArray[#resultArray + 1] = point.GetComponent(DataContainer)
    end

    return resultArray
end

function SotoAttachments:GetPoints(buttons)
    resultArray = {}

    for i, button in pairs(buttons) do
        resultArray[#resultArray + 1] = button.GetComponent(Button)
    end

    return resultArray
end

function SotoAttachments:GetPointIcons(points)
    resultArray = {}

    for i, point in pairs(points) do
        local icon = point.transform.Find("Icon").gameObject.GetComponent(Image)
        resultArray[#resultArray + 1] = icon
    end

    return resultArray
end

function SotoAttachments:GetPointCaptions(points)
    resultArray = {}

    for i, point in pairs(points) do
        local caption = point.transform.Find("Name Display").gameObject.GetComponent(Text)
        resultArray[#resultArray + 1] = caption
    end
    
    return resultArray
end

function SotoAttachments:GetAttachments(points)
    resultArray = {}

    for i, point in pairs(points) do
        attachments = {}

        availableAttachments = point.GetGameObjectArray("attachment")

        for j, attachment in pairs(availableAttachments) do
            local data = attachment.GetComponent(DataContainer)
            attachments[#attachments + 1] = data

            local type = string.lower(data.GetString("type"))
            if type == "laser" then
                self.lasers[#self.lasers + 1] = data.GetGameObject("laser")
            end
        end

        resultArray[#resultArray + 1] = attachments
    end

    return resultArray
end

function SotoAttachments:GetEffects(attachments)
    resultArray = {}

    for i, point in pairs(attachments) do
        resultArray[i] = {}
        for j, attachment in pairs(point) do
            if attachment.HasObject("effect1") then
                resultArray[i][j] = attachment.GetGameObjectArray("effect")
            end
        end
    end

    return resultArray
end

function SotoAttachments:GetEffectDatas(effects)
    resultArray = {}

    for i, point in pairs(effects) do
        resultArray[i] = {}
        for j, attachment in pairs(point) do
            resultArray[i][j] = {}
            for k, effect in pairs(attachment) do
                
                resultArray[i][j][k] = effect.GetComponent(DataContainer)
            end
        end
    end

    return resultArray
end

function SotoAttachments:InitiatePoints(points)
    for i, point in pairs(points) do
        local icon = self.pointIcons[i]
        local pointDisplay = self.pointButtons[i].transform.Find("Segment Display").gameObject.GetComponent(Text)
        local caption = self.pointCaptions[i]

        local attachmentIndex = point.GetInt("startAttachment")
        local equippedAttachment = self.attachments[i][attachmentIndex]

        local type = string.lower(equippedAttachment.GetString("type"))

        if pastAttachments[self.weapon.weaponEntry.name][i] == nil then
            pastAttachments[self.weapon.weaponEntry.name][i] = attachmentIndex
        end

        if type == "ammo" then
            self.ammoPoint = Vector2(i, attachmentIndex)
        elseif type == "barrel" then
            self.barrelPoint = Vector2(i, attachmentIndex)
        elseif type == "muzzle" then
            self.muzzle = equippedAttachment
            self.particle = equippedAttachment.GetGameObject("particle")
        elseif type == "sight" then
            self.animator.SetInteger("sight", equippedAttachment.GetInt("animatorValue"))
        end

        icon.sprite = equippedAttachment.GetSprite("icon")
        pointDisplay.text = point.GetString("displayName"):gsub("<br>", "\n")
        caption.text = equippedAttachment.GetString("displayName"):gsub("<br>", "\n")
    end
end

function SotoAttachments:EquipPastAttachments()
    for point, index in pairs(pastAttachments[self.weapon.weaponEntry.name]) do
        self:onGridButtonClick(index, point)
    end
end

function SotoAttachments:ParseAttachmentInfo()
    result = {}

    for i, point in pairs(self.pointDatas) do
        local temp = {}
        temp[1] = point.GetString("displayName")
        local attachment = self.attachments[i][pastAttachments[self.weapon.weaponEntry.name][i]]
        temp[2] = attachment.GetString("displayName")
        temp[3] = attachment.GetSprite("icon")

        -- temp = {point name, attachment name, attachment icon}

        result[i] = temp
    end

    return result

    -- local sotoScript = Player.actor.weapon.transform.Find("Customization").gameObject.GetComponent(ScriptedBehaviour)
    -- local result = sotoScript.self:ParseAttachmentInfo()
    -- for i, point in pairs(result) do
    --     print("Attachment point " .. result[i][1] .. " has " .. result[i][2] .. " attached")
    --     icon.sprite = result[3]
end
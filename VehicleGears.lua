behaviour("VehicleGears")

function VehicleGears:Start()
    self.vehicle = self.targets.vehicleObject.GetComponent(Car)
    self.vehicleTransform = self.targets.vehicleObject.transform
    self.vehicleRigidbody = self.targets.vehicleObject.GetComponent(Rigidbody)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    self.fwdDragValues = self:Split(self.dataContainer.GetString("forwardDragValues"), " ")
    self.fwdAccValues = self:Split(self.dataContainer.GetString("forwardAccValues"), " ")
    self.fwdSpeedLimit = self:Split(self.dataContainer.GetString("forwardSpeedLimit"), " ") -- HAS to be in descending order
    self.revDragValues = self:Split(self.dataContainer.GetString("reverseDragValues"), " ")
    self.revAccValues = self:Split(self.dataContainer.GetString("reverseAccValues"), " ")
    self.revSpeedLimit = self:Split(self.dataContainer.GetString("reverseSpeedLimit"), " ") -- HAS to be in descending order

    self.forwardPrefix = self.dataContainer.GetString("forwardPrefix")
    self.reversePrefix = self.dataContainer.GetString("reversePrefix")
    self.forwardSuffix = self.dataContainer.GetString("forwardSuffix")
    self.reverseSuffix = self.dataContainer.GetString("reverseSuffix")

    self.fwdGearCount = #self.fwdSpeedLimit + 1
    
    self.revGearCount = #self.revSpeedLimit + 1

    self.gearText = self.targets.gearText.GetComponent(Text)

    self.hitchSoundBank = self.targets.soundBank.GetComponent(SoundBank)
    self.lastDrag = -1
    self.lastAcc = -1

    self.hitchDrag = self.dataContainer.GetFloat("hitchDrag")
    self.hitchAcc = self.dataContainer.GetFloat("hitchAcc")
    self.hitchDuration = self.dataContainer.GetFloat("hitchDuration")
    self.controlGainDelay = self.dataContainer.GetFloat("controlDelay")

    self.durationLeft = 0
    self.dragLeft = 0
    --self.minDrag = 0
    self.baseDrag = 0
    self.baseAcc= 0
    self.unlocked = 0

    --self.gearZip = self:Zip(self.availableModes, self.fireModeValues)
end

function VehicleGears:Update()
    local reverse = self.vehicle.inReverseGear
    local velocity = self.vehicleTransform.worldToLocalMatrix.MultiplyVector(self.vehicleRigidbody.velocity).z * 3.6

    local tableToUse = reverse and self.revSpeedLimit or self.fwdSpeedLimit

    for i, speed in pairs(tableToUse) do
        if math.abs(velocity) >= speed and Time.time > self.unlocked then
            local dragForSpeed = (reverse and self.revDragValues or self.fwdDragValues)[i]
            local accForSpeed = (reverse and self.revAccValues or self.fwdAccValues)[i]
            
            if dragForSpeed ~= self.lastDrag or accForSpeed ~= self.lastAcc then

                self:OnHitchChange()
                self.lastDrag = dragForSpeed
                self.baseDrag = dragForSpeed

                self.lastAcc = accForSpeed
                self.baseAcc = accForSpeed
            end

            local prefix = reverse and self.reversePrefix or self.forwardPrefix
            local suffix = reverse and self.reverseSuffix or self.forwardSuffix
            local gearNum = reverse and self.revGearCount or self.fwdGearCount

            self.gearText.text = prefix .. (gearNum - i) .. suffix
            break
        end
    end

    local left = self.durationLeft / self.hitchDuration

    self.vehicle.groundDrag = self.baseDrag + self.hitchDrag * left
    self.vehicle.acceleration = self.baseAcc + self.hitchAcc * left

    if self.durationLeft > 0 then
        self.durationLeft = self.durationLeft - Time.deltaTime
    else
        self.durationLeft = 0
    end
end

function VehicleGears:OnHitchChange()
    self.hitchSoundBank.PlayRandom()
    
    self.durationLeft = self.hitchDuration
    self.unlocked = Time.time + self.hitchDuration + self.controlGainDelay
    self.dragLeft = 0
end

function VehicleGears:Split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, tonumber(match))
    end
    return result
end

function VehicleGears:Zip(keyArray, valueArray)
    result = {}

    if #keyArray ~= #valueArray then
        return error("Array length not the same!")
    end
    for i=1, #keyArray, 1 do
        result[keyArray[i]] = tonumber(valueArray[i])
    end
    return result
end

behaviour("TurretAudio")

function TurretAudio:Start()
    self.vehicleTransform = self.targets.vehicleObject.transform
    self.seat = self.targets.vehicleObject.GetComponent(Vehicle).seats[1]
    self.audio = self.targets.audio.GetComponent(AudioSource)

    self.last = self.vehicleTransform.rotation
end

function TurretAudio:Update()
    local val1 = Input.GetAxis("Mouse X") ~= 0
    local val2 = Input.GetAxis("Mouse Y") ~= 0

    local flag1 = val1 or val2
    local flag2 = self.seat.occupant == Player.actor
    local flag3 = self.audio.isPlaying

    if flag2 then -- player is inside vehicle
        local rotate = Mathf.round(self:FromToRotation(self.last, self.vehicleTransform.rotation).eulerAngles.y / Time.deltaTime)
        local flag4 = math.abs(rotate) > 0.1
        self.last = self.vehicleTransform.rotation

        if (flag1 or flag4) and not flag3 then -- player moves mouse but audio is not playing
            self.audio.Play()
        elseif (not flag1 and not flag4) and flag3 then -- player doesn't moves mouse and audio is playing
            self.audio.Stop()
        end
    elseif not flag2 and flag3 then -- player gets out of vehicle when audio is playing
        self.audio.Stop()
    end
end

function TurretAudio:FromToRotation(last, now)
    return Quaternion.Inverse(last) * now
end
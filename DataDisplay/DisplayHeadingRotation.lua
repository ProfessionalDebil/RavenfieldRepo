behaviour("DisplayHeadingRotation") --v1.1.0

function DisplayHeadingRotation:Start()
    self.dataCon = self.gameObject.GetComponent(DataContainer)

    self.vehicleObject = self.targets.vehicleObject.transform
    self.transform = self.gameObject.transform

    self.multiplier = Vector3.zero
    if self.dataCon then
        if self.dataCon.HasVector("multiplier") then
            self.multiplier = self.dataCon.GetVector("multiplier")
        end
    end

    self.display = false
end

function DisplayHeadingRotation:Update()
    self.display = not self.display

    if not self.display then
        return
    end

    self.transform.localEulerAngles = self.vehicleObject.eulerAngles.y * self.multiplier
end

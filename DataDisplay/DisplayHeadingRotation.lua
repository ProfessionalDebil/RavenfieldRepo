behaviour("DisplayHeadingRotation") --v1.0.0

function DisplayHeadingRotation:Start()
    self.vehicleObject = self.targets.vehicleObject.transform
    self.transform = self.gameObject.transform

    self.display = false
end

function DisplayHeadingRotation:Update()
    self.display = not self.display

    if not self.display then
        return
    end

    self.transform.localEulerAngles = Vector3(0, 0, self.vehicleObject.eulerAngles.y)
end

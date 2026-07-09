behaviour("FalconCamera") --v1.0.0

function FalconCamera:Start()
    self.camera = self.targets.camera.GetComponent(Camera)
    self.cameraTransform = self.targets.camera.transform
    self.cameraParent = self.targets.camera.transform.parent

    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.hmcs = self.targets.hmcs.GetComponent(ScriptedBehaviour).self

    self.offset = self.dataContainer.GetFloat("offset") / 180
    self.fovMin = self.dataContainer.GetFloat("fovMin")
    self.fovMax = self.dataContainer.GetFloat("fovMax")
    self.step = self.dataContainer.GetFloat("step")

    self.states = (self.fovMax - self.fovMin) / self.step + 1
    self.currentState = self.dataContainer.GetInt("currentState")

    self.fovs = {}

    for i=1, self.states, 1 do
        local ratio = (i-1) / (self.states-1)

        self.fovs[i] = Mathf.Lerp(self.fovMin, self.fovMax, ratio)
    end

    self.normalRotation = Vector3(3, 0, 0)
    self.leftRotation = Vector3(19.3, -9.85, 0)
    self.rightRotation = Vector3(19.3, 9.85, 0)
    self.seeingLeft = false
    self.seeingRight = false
    self.mfdZoomFov = 6.9
    self.usedRotation = self.normalRotation

    if DebilFalconConfig_ConfigLoaded then
        self.up = DebilFalconConfig_ZoomIn
        self.down = DebilFalconConfig_ZoomOut
    end
    if self.up == nil then
        self.up = KeyCode.LeftShift
    end
    if self.down == nil then
        self.down = KeyCode.LeftControl
    end

    self.leftAlt = KeyCode.LeftAlt
    self.rightAlt = KeyCode.RightAlt

    self:RefreshFOV()
end

function FalconCamera:Update()
    local altPressed = Input.GetKey(self.leftAlt) or Input.GetKey(self.rightAlt)

    if Input.GetKeyDown(self.up) and not self.seeingLeft and not self.seeingRight then
        self:Zoom(-1)
    end
    if Input.GetKeyDown(self.down) and not self.seeingLeft and not self.seeingRight then
        self:Zoom(1)
    end

    local parentPos = self.cameraParent.localPosition

    parentPos.x = ((self.cameraTransform.localEulerAngles.y + 540) % 360 - 180) * self.offset

    self.cameraParent.localPosition = parentPos

    self.cameraTransform.localEulerAngles = self.cameraTransform.localEulerAngles - self.usedRotation

end

function FalconCamera:LateUpdate()
    self.cameraTransform.localEulerAngles = self.cameraTransform.localEulerAngles + self.usedRotation
    self.hmcs:Refresh()
end

function FalconCamera:Zoom(input)
    self.currentState = Mathf.Clamp(self.currentState + input, 1, self.states)

    self:RefreshFOV()
end

function FalconCamera:RefreshFOV()
    self.camera.fieldOfView = self.fovs[self.currentState]
end

function FalconCamera:See(input)
    if input == -1 and not self.seeingLeft then
        self.seeingLeft = true
        self.seeingRight = false
        self.usedRotation = self.leftRotation
        self.camera.fieldOfView = self.mfdZoomFov
    elseif input == 1 and not self.seeingRight then
        self.seeingLeft = false
        self.seeingRight = true
        self.usedRotation = self.rightRotation
        self.camera.fieldOfView = self.mfdZoomFov
    else
        self.seeingLeft = false
        self.seeingRight = false
        self.usedRotation = self.normalRotation
        self:RefreshFOV()
    end
end
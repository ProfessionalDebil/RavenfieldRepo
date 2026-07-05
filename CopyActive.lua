behaviour("CopyActive") --v1.0.0

function CopyActive:Start()
    self.a = self.targets.a
    self.b = self.targets.b
end

function CopyActive:Update()
    self.a.SetActive(self.b.activeSelf)
end
behaviour("NVGAim")

function NVGAim:Start()
    self.animator = self.targets.animator.GetComponent(Animator)

    self.name = self.animator.StringToHash("nvg")
end

function NVGAim:Update()
    self.animator.SetBool(self.name, Player.nighvisionEnabled)
end
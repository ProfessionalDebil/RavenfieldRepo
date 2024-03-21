behaviour("AnimatedCamera")

function AnimatedCamera:Start()
	self.transform = self.gameObject.transform
end
function AnimatedCamera:OnDisable()
	PlayerCamera.fpCameraLocalRotation = Quaternion.identity
end
function AnimatedCamera:LateUpdate()
	PlayerCamera.fpCameraLocalRotation = self.transform.localRotation
end

behaviour("WeaponMeleeSequence")

function WeaponMeleeSequence:Start()
    self.keybind = KeyCode.LeftAlt

    self.keybindMutator = GameObject.Find("BMW Keybinds(Clone)")
    if self.keybindMutator ~= nil then
        self.keybindMutator = self.keybindMutator.GetComponent(ScriptedBehaviour).self
        self.keybind = self.keybindMutator.melee
    end

    self.animator = self.targets.animator.GetComponent(Animator)
    self.weapon = self.targets.weapon.GetComponent(Weapon)

    self.dataContainer = self.gameObject.GetComponent(DataContainer)
    self.meleeAnimationsCount = self.dataContainer.GetInt("meleeAnimationsCount")
    self.durations = self.dataContainer.GetFloatArray("meleeWait")

    self.meleeDamage = self.dataContainer.GetFloat("meleeDamage")
    self.meleeBalance = self.dataContainer.GetFloat("meleeBalance")
    self.meleeKnockback = self.dataContainer.GetFloat("meleeKnockback")
    self.cooldown = self.dataContainer.GetFloat("cooldown")

    self.animInt = 0
end

function WeaponMeleeSequence:Update()
    if Input.GetKeyDown(self.keybind) and not self.isDoingMelee then
        self.script.StartCoroutine("Melee")
    end
end

function WeaponMeleeSequence:Melee()
    if self.isDoingMelee then
        return
    end
    
    self.isDoingMelee = true
    local ray = Ray(PlayerCamera.fpCamera.transform.position, PlayerCamera.fpCamera.transform.forward)
    local sphereRaycast = Physics.Spherecast(ray, 0.6, 1.9, 16848129)
    self.animInt = (self.animInt + 1) % self.meleeAnimationsCount
    self.animator.SetInteger("meleeInt", self.animInt)
    self.animator.SetTrigger("melee")
    self.weapon.LockWeapon()

    coroutine.yield(WaitForSeconds(self.durations[self.animInt + 1]))

    if(sphereRaycast ~= nil) then
        local hitActor = self:GetActorTroughBone(sphereRaycast.transform)
        if(hitActor ~= Player.actor and hitActor ~= nil) then -- How does this even happen?
            if(not hitActor.isDead) then
                local hit = hitActor.Damage(Player.actor, self.meleeDamage, self.meleeBalance, false, false, sphereRaycast.point, PlayerCamera.fpCamera.transform.forward, PlayerCamera.fpCamera.transform.forward * self.meleeKnockback)
            else
                sphereRaycast.collider.attachedRigidbody.AddForceAtPosition(PlayerCamera.fpCamera.transform.forward * 250, sphereRaycast.point, ForceMode.Impulse);
            end
        end
    end

    coroutine.yield(WaitForSeconds(self.cooldown))
    self.isDoingMelee = false
    self.weapon.UnlockWeapon()
end

function WeaponMelee:GetActorTroughBone(boneTransform)
	local gameObject = boneTransform.gameObject
	while (gameObject.transform.parent ~= nil and gameObject.transform.parent.name ~= "Armature") do
		gameObject = gameObject.transform.parent.gameObject;
	end
	if(gameObject.transform.parent ~= nil) then
		local actor = gameObject.transform.parent.gameObject.GetComponentInParent(Actor)
		if(actor ~= nil) then
			return actor
		else
			return nil
		end
	end
end

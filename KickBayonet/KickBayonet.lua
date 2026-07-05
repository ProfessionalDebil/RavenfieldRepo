behaviour("KickBayonet") --v2.2.1

function KickBayonet:Start()
    if self.weapon == nil then
        self.weapon = self.targets.weapon.GetComponent(Weapon)
    end

    if self.weapon.user ~= Player.actor then
        return
    end

    self.animator = self.targets.weapon.GetComponent(Animator)
    self.audioSource = self.targets.audioSource.GetComponent(AudioSource)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    self.kickParameter = self.animator.StringToHash("kick")
    self.allowWhenProne = self.dataContainer.GetBool("allowWhenProne")
    self.allowWhenAim = self.dataContainer.GetBool("allowWhenAim")
    self.kickRadius = self.dataContainer.GetFloat("kickRadius")
    self.kickRange = self.dataContainer.GetFloat("kickRange")
    self.damage = self.dataContainer.GetFloat("damage")
    self.balanceDamage = self.dataContainer.GetFloat("balanceDamage")
    self.force = self.dataContainer.GetFloat("force")
    self.cooldown = self.dataContainer.GetFloat("cooldown")
    self.delay = self.dataContainer.GetFloat("delay")
    self.swing = self.dataContainer.GetAudioClip("swing")
    self.hit = self.dataContainer.GetAudioClip("hit")

    self.requiresEquip = false
    if self.isEquipped == nil then
        self.isEquipped = true
    end

    if self.dataContainer.HasBool("requiresEquip") then
        self.requiresEquip = self.dataContainer.GetBool("requiresEquip")

        if self.requiresEquip then
            self.equipKeybind = self.dataContainer.GetString("equipKeybind")
            self.equipDuration = -1
            if self.dataContainer.HasFloat("equipDuration") then
                self.equipDuration = self.dataContainer.GetFloat("equipDuration")
            end
            self.animatorParameter = self.animator.StringToHash(self.dataContainer.GetString("isEquippedParameterName"))
            self.switchParameter = self.animator.StringToHash(self.dataContainer.GetString("switchParameterName"))

            self.isEquipped = self.dataContainer.GetBool("isEquipped")
            self.animator.SetBool(self.animatorParameter, self.isEquipped)
        end
    end
    
    Player.allowKick = not self.isEquipped

    self.nextKick = Time.time
    self.kickTime = 0
    self.finishEquipTime = -1
end

function KickBayonet:Update()
    if self.weapon.user ~= Player.actor then
        return
    end

    if self.requiresEquip then
        if Input.GetKeyDown(self.equipKeybind) then
            self.isEquipped = not self.isEquipped
            self.animator.SetBool(self.animatorParameter, self.isEquipped)
            self.animator.SetTrigger(self.switchParameter)

            Player.allowKick = not self.isEquipped

            if self.equipDuration > 0 then
                self.finishEquipTime = Time.time + self.equipDuration
            end
        end
    end

    if self.finishEquipTime > 0 then
        self.weapon:LockWeapon()
    end
    if Time.time >= self.finishEquipTime then
        self.weapon:UnlockWeapon()
        self.finishEquipTime = -1
    end

    if self.isEquipped and Input.GetKeyBindButtonDown(KeyBinds.Kick) and not self.weapon.isReloading and self.weapon.isUnholstered and Time.time >= self.nextKick and (self.allowWhenAim or not self.weapon.isAiming) and (self.allowWhenProne or not (Player.actor.stance == Stance.Prone)) then
        self.animator.SetTrigger(self.kickParameter)

        if self.swing ~= nil then
            self.audioSource.PlayOneShot(self.swing)
        end

        self.kickTime = Time.time + self.delay
        self.nextKick = Time.time + self.cooldown
    end

    if self.kickTime ~= 0 then
        if Time.time >= self.kickTime then
            local ray = Ray(PlayerCamera.fpCamera.transform.position + PlayerCamera.fpCamera.transform.forward * 0.55, PlayerCamera.fpCamera.transform.forward)
            local raycast = Physics.Spherecast(ray, self.kickRadius, self.kickRange, RaycastTarget.ProjectileHit)
            if raycast ~= nil then
                if raycast.transform.gameObject.layer == 8 then
                    local actorComponent = raycast.transform.gameObject.GetComponentInParent(Actor)

                    actorComponent.Damage(self.weapon.user, self.damage, self.balanceDamage, false, false, raycast.point, PlayerCamera.fpCamera.transform.forward, PlayerCamera.fpCamera.transform.forward * self.force)
                    if self.hit ~= nil then
                        self.audioSource.PlayOneShot(self.hit)
                    end
                end
            end

            self.kickTime = 0
        end
    end
end

function KickBayonet:OnEnable()
    if self.weapon == nil then
        self.weapon = self.targets.weapon.GetComponent(Weapon)
    end

    if self.weapon.user ~= Player.actor then
        return
    end

    if self.isEquipped == nil then
        self.isEquipped = true
    end

    Player.allowKick = not self.isEquipped
    self.animator.SetBool(self.animatorParameter, self.isEquipped)
end

function KickBayonet:OnDisable()
    if self.weapon == nil then
        self.weapon = self.targets.weapon.GetComponent(Weapon)
    end

    if self.weapon.user ~= Player.actor then
        return
    end

    Player.allowKick = true
end

function KickBayonet:OnDestroy()
    if self.weapon == nil then
        self.weapon = self.targets.weapon.GetComponent(Weapon)
    end

    if self.weapon.user ~= Player.actor then
        return
    end

    Player.allowKick = true
end

using System;
using System.Collections.Generic;
using UnityEngine;

// Token: 0x0200008C RID: 140
public class RemoteDetonatorWeapon : ThrowableWeapon
{
	// Token: 0x06000627 RID: 1575 RVA: 0x00026ED0 File Offset: 0x000250D0
	
	public static readonly int DETONATE_PARAMETER_HASH = Animator.StringToHash("detonate");

	// Token: 0x040005CF RID: 1487
	public float detonateDelay = 0.3f;

	// Token: 0x040005D0 RID: 1488
	private List<RemoteDetonatedProjectile> registeredProjectiles = new List<RemoteDetonatedProjectile>();

	// Token: 0x040005D1 RID: 1489
	private bool detonationTriggered;

	// Token: 0x040005D2 RID: 1490
	//private TimedAction detonationDelayAction;
}

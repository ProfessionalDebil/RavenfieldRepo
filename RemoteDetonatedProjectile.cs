using System;
using UnityEngine;

public class RemoteDetonatedProjectile : ExplodingProjectile
{
		// Token: 0x040005C8 RID: 1480
	public const int STICK_HIT_MASK = -12947205;

	// Token: 0x040005C9 RID: 1481
	public Vector3 stickRotationOffset;

	// Token: 0x040005CA RID: 1482
	private bool isDetonated;

	// Token: 0x040005CB RID: 1483
	private Vehicle attachedVehicle;

	// Token: 0x040005CC RID: 1484
	private Destructible attachedDestructible;

	// Token: 0x040005CD RID: 1485
	private Vector3 explosionPoint;
}

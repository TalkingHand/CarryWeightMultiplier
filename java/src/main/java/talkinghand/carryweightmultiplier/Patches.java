package talkinghand.carryweightmultiplier;

import me.zed_0xff.zombie_buddy.Patch;

/** Only the weights summed for carry and capacity checks change; getWeight and getActualWeight stay vanilla. */
public final class Patches {
    private Patches() {}

    @Patch(className = "zombie.inventory.InventoryItem", methodName = "getUnequippedWeight")
    public static class Unequipped {
        @Patch.OnExit
        public static void exit(@Patch.This Object self, @Patch.Return(readOnly = false) float ret) {
            ret = Load.unequipped(self, ret);
        }
    }

    @Patch(className = "zombie.inventory.InventoryItem", methodName = "getEquippedWeight")
    public static class Equipped {
        @Patch.OnExit
        public static void exit(@Patch.Return(readOnly = false) float ret) {
            ret = Load.equipped(ret);
        }
    }

    @Patch(className = "zombie.inventory.types.InventoryContainer", methodName = "getEquippedWeight")
    public static class EquippedBag {
        @Patch.OnExit
        public static void exit(@Patch.This Object self, @Patch.Return(readOnly = false) float ret) {
            ret = Load.equippedBag(self, ret);
        }
    }

    @Patch(className = "zombie.inventory.InventoryItem", methodName = "getHotbarEquippedWeight")
    public static class Hotbar {
        @Patch.OnExit
        public static void exit(@Patch.This Object self, @Patch.Return(readOnly = false) float ret) {
            ret = Load.hotbar(self, ret);
        }
    }
}

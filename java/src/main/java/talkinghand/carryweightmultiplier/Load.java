package talkinghand.carryweightmultiplier;

import zombie.SandboxOptions;
import zombie.inventory.InventoryItem;
import zombie.inventory.types.InventoryContainer;

/**
 * The weight an item counts for in carry and capacity checks: its vanilla value times the sandbox multiplier.
 * A bag's contents are summed from getUnequippedWeight, so they already are multiplied: only the rest is.
 */
public final class Load {
    public static final float DEFAULT_MULTIPLIER = 0.1F;

    private Load() {}

    public static float multiplier() {
        return SandboxOptions.instance.getOptionByName("CarryWeightMultiplier.Multiplier") instanceof SandboxOptions.DoubleSandboxOption option
            ? (float) option.getValue()
            : DEFAULT_MULTIPLIER;
    }

    private static float children(Object item) {
        return item instanceof InventoryContainer bag ? bag.getInventory().getContentsWeight() : 0.0F;
    }

    private static float counted(float vanilla, float alreadyScaled) {
        return alreadyScaled + (vanilla - alreadyScaled) * multiplier();
    }

    public static float unequipped(Object item, float vanilla) {
        return counted(vanilla, children(item));
    }

    /** Base getEquippedWeight; InventoryContainer overrides it, see {@link #equippedBag}. */
    public static float equipped(float vanilla) {
        return vanilla * multiplier();
    }

    /** InventoryContainer.getEquippedWeight: contents count through the bag's weight reduction. */
    public static float equippedBag(Object item, float vanilla) {
        InventoryContainer bag = (InventoryContainer) item;
        float reduction = bag.getWeightReduction() > 0 ? 1.0F - bag.getWeightReduction() / 100.0F : 1.0F;
        return counted(vanilla, children(bag) * reduction);
    }

    /** getHotbarEquippedWeight: (weight + contents) * a factor that depends on the item's tags. */
    public static float hotbar(Object item, float vanilla) {
        InventoryItem it = (InventoryItem) item;
        float base = it.getActualWeight() + it.getContentsWeight();
        return base > 0.0F ? counted(vanilla, children(item) * vanilla / base) : vanilla;
    }
}

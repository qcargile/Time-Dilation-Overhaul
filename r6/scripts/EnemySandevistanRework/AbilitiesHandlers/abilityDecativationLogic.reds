@wrapMethod(NPCPuppet)
protected cb func OnStatusEffectRemoved(evt: ref<RemoveStatusEffect>) -> Bool {
    let originalResult = wrappedMethod(evt);
    let gmplTags = evt.staticData.GameplayTags();

    if(ArrayContains(gmplTags, n"ESR_Sandi_Buff") && !StatusEffectSystem.ObjectHasStatusEffectWithTag(this, n"ESR_Sandi_Buff")) {
        AISubActionApplyTimeDilation_Record_Implementation.ForceDeactivateSandevistan(this, true); 
    }

    return originalResult;
}


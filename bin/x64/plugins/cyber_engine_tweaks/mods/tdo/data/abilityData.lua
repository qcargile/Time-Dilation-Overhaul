return {
    statModifiers = {
        dur = {
                findLocation = ".statType",
                find = TweakDBID.new("BaseStats.TimeDilationSandevistanDuration"),
                valueLocation = ".value",
                existingUI = {
                    [92102] = 7,
                    [53584] = 4,
                    [92123] = 5,
                    [92103] = 7,
                    [91021] = 7
                },
                existingUILocation = ".floatValues",
                UIModifier = "None",
                valueModifier = "None"
        },
        ts = {
            findLocation = ".statType",
            find = TweakDBID.new("BaseStats.TimeDilationSandevistanTimeScale"),
            valueLocation = ".value",
            existingUI = {
                [92102] = 1,
                [53584] = 1,
                [92123] = 1,
                [92103] = 1,
                [91021] = 1
            },
            existingUILocation = ".floatValues",
            UIModifier = "Percent",
            valueModifier = "MinusOne_Percent",
        },
        rchrg = {
            findLocation = ".statType",
            find = TweakDBID.new("BaseStats.TimeDilationSandevistanRechargeDuration"),
            valueLocation = ".value",
            existingUI = {
                [93182] = 1,
            },
            existingUILocation = ".floatValues",
            UIModifier = "None",
            valueModifier = "None"
        },
    },
    OnEquip = {
        critCh = {
            effectorClass = CName.new("ApplyStatGroupEffector"),
            findLocation = ".statType",
            find = TweakDBID.new("BaseStats.CritChance"),
            valueLocation = ".value",
            prereqFind = CName.new("TimeDilationPSMPrereq"),
            existingUI = {
                [53584] = 2,
                [92103] = 3,
                [91021] = 3
            },
            existingUILocation = ".floatValues",
            UIModifier = "None",
            valueModifier = "None",
        },
        critDmg = {
            effectorClass = CName.new("ApplyStatGroupEffector"),
            findLocation = ".statType",
            find = TweakDBID.new("BaseStats.CritDamage"),
            valueLocation = ".value",
            prereqFind = CName.new("TimeDilationPSMPrereq"),
            existingUI = {
                [53584] = 3,
                [92103] = 4,
                [91021] = 4
            },
            existingUILocation = ".floatValues",
            UIModifier = "None",
            valueModifier = "None",
        },
    },
    metaStats = {}
}

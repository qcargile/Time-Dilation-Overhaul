return {
    ts = {
        type = "Int",
        min = 5,
        max = 100,
        inc = 1
    },
    dur = {
        type = "Float",
        min = 0.5,
        max = 60,
        inc = 0.1,
        precision = "%.1f"
    },
    rchrg = {
        type = "Int",
        min = 0,
        max = 60,
        inc = 1
    },
    critCh = {
        type = "Int",
        min = 0,
        max = 50,
        inc = 1
    },
    critDmg = {
        type = "Int",
        min = 0,
        max = 50,
        inc = 1
    },
    menuOrder = {
        [1] = "ts",
        [2] = "dur",
        [3] = "rchrg",
        [4] = "critCh",
        [5] = "critDmg",
    },
}
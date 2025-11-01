data = {
    entities = {
        
        -- player
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        [16] = {
            class = "player",
        },


        -- pets
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        [17] = {
            class = "pet",
            name = "cat",
        },

        [18] = {
            class = "pet",
            name = "dog",
        },


        -- npcs
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        [19] = {
            class = "npc",
            name = "dinosaur",
        },

        [20] = {
            class = "npc",
            name = "mushroom man",
        },

        [21] = {
            class = "npc",
            name = "green guy",
        },

        [22] = {
            class = "npc",
            name = "man",
        },

        [23] = {
            class = "npc",
            name = "guy",
        },


        -- enemies
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        [24] = {
            class = "npc",
            name = "blob",
        },

        [25] = {
            class = "npc",
            name = "hobgoblin",
        },

        [26] = {
            class = "enemy",
            name = "skull",
        },

        [27] = {
            class = "npc",
            name = "ghoul",
        },

        [28] = {
            class = "npc",
            name = "bat",
        },

        [29] = {
            class = "npc",
            name = "vampire",
        },

        [30] = {
            class = "npc",
            name = "demon",
        },


        -- interactables
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
        [3] = {
            class = "sign",
            name = "grave",
            message = "rip in peace",
            bg=13,
            fg=6,
        },

        [4] = {
            class = "sign",
        },

        [5] = {
            class = "stairs",

        },

        [6] = {
            class = "stairs",

        },

        [7] = {
            class = "stairs",
        },

        [8] = {
            class = "stairs",
        },

        [51] = {
            class = "chest",
            name = "chest",
        },

        [52] = {
            class = "door",
            name = "locked door",
            locked = 1,
        },

        [53] = {
            class = "door",
            name = "locked door",
            locked = 2,
        },

        [81] = {
            class = "door",
            collision = false,
        },

        [82] = {
            class = "door",
        },


        -- items
        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        [54] = {
            class = "item",
            name = "key",
        },

        [55] = {
            class = "item",
            name = "gold key",
        },

        [56] = {
            class = "item",
            name = "dagger",
        },

        [57] = {
            class = "item",
            name = "sword",
        },

        [58] = {
            class = "item",
            name = "bow",
        },

        [59] = {
            class = "item",
            name = "potion",
        },

        [60] = {
            class = "item",
            name = "potion",
        },

        [61] = {
            class = "item",
            name = "scroll",
        },

        [62] = {
            class = "item",
            name = "ring",
        },

    },
    signs = {
        {
            x=6,
            y=22,
            message="hello there.\nthis is a sign\nwith multiple\nlines.\nfive actually.\noh wait,\nit is\neight lines.\nor actually,\nthat is not correct\nat all.\nit is\n13 lines i believe."
        },
        {
            x=5,
            y=1,
            message="this is a sign."
        },
        {
            x=6,
            y=1,
            message="this is a grave."
        },
    }
}

--TODO:
-- Add a + meters - for setting local distance radius
-- Add a checkmark box to use local radius for item counts
-- Add a refresh button

--Table defining the data and functionality for the food menu

local foodMenuTable = {
    menuTitle = "Food",
    parentView = foodButton,
    mainMenu = {
        menuItems = {
                menuItemText = "Available Food Units:",
                menuItemIcon = nil,
                menuItemInfoFunction = function() 
                    return getAvailableFoodUnits() 
                end
            }
        }
    }

-- Define all possible categories
foodMenu.categoryNames = {
    "flatBread", 
    "cookedFoods",
    "rawFoods",
    "naturalFoods",
    "otherFoods",
}

-- Define the order of categories for display
foodMenu.categoryOrder = {
    "flatBread",  
    "cookedFoods",
    "rawFoods",
    "naturalFoods",
    "otherFoods",
}

-- Define food items with their categories
foodMenu.foods = {
    -- Food items
    ["apple"] = { category = "naturalFoods" },
    ["banana"] = { category = "naturalFoods" },
    ["beetroot"] = { category = "rawFoods" },
    ["coconut"] = { category = "naturalFoods" },
    ["alpacaMeatCooked"] = { category = "cookedFoods" },
    ["chickenMeatCooked"] = { category = "cookedFoods" },
    ["fishCooked"] = { category = "cookedFoods" },
    ["mammothMeatCooked"] = { category = "cookedFoods" },
    ["elderberry"] = { category = "naturalFoods" },
    ["flatbread"] = { category = "flatBread" },
    ["flaxSeed"] = { category = "naturalFoods" },
    ["garlic"] = { category = "naturalFoods" },
    ["gingerRoot"] = { category = "naturalFoods" },
    ["gooseberry"] = { category = "naturalFoods" },
    ["orange"] = { category = "naturalFoods" },
    ["peach"] = { category = "naturalFoods" },
    ["pumpkin"] = { category = "rawFoods" },
    ["raspberry"] = { category = "naturalFoods" },
    ["alpacaMeat"] = { category = "rawFoods" },
    ["chickenMeat"] = { category = "rawFoods" },
    ["fish"] = { category = "rawFoods" },
    ["mammothMeat"] = { category = "rawFoods" },
    ["beetrootCooked"] = { category = "cookedFoods" },
    ["pumpkinCooked"] = { category = "cookedFoods" },
    ["sunflowerSeed"] = { category = "naturalFoods" },
    ["turmericRoot"] = { category = "naturalFoods" },

    -- Non-food items related to flatbread production
    ["firedUrnHulledWheat"] = { category = "flatBread" },
    ["firedUrnFlour"] = { category = "flatBread" },
    ["unfiredUrnHulledWheat"] = { category = "flatBread" },
    ["unfiredUrnFlour"] = { category = "flatBread" },
    ["firedUrn"] = { category = "flatBread" },
    ["unfiredUrnDry"] = { category = "flatBread" },
    ["unfiredUrnWet"] = { category = "flatBread" },
    ["quernstone"] = { category = "flatBread" },
}

-- Helper function to get the category of a food item by its key
function foodMenu:getCategory(foodKey)
    local foodInfo = self.foods[foodKey]
    return foodInfo and foodInfo.category or "otherFoods"
end

return foodMenu

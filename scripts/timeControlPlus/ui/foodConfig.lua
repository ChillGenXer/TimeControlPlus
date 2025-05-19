local foodConfig = {}

-- Define all possible categories
foodConfig.categoryNames = {
    "flatBread", 
    "cookedFoods",
    "rawFoods",
    "naturalFoods",
    "otherFoods",
}

-- Define the order of categories for display
foodConfig.categoryOrder = {
    "flatBread",  
    "cookedFoods",
    "rawFoods",
    "naturalFoods",
    "otherFoods",
}

-- Define food items with their categories
foodConfig.foods = {
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
function foodConfig:getCategory(foodKey)
    local foodInfo = self.foods[foodKey]
    return foodInfo and foodInfo.category or "otherFoods"
end

return foodConfig
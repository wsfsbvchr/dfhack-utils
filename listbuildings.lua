-- List buildings or find a building by searching
local help = [====[

listbuildings
=============
Lists active buildings and their positions, optionally by filter.


Example usage:

`listbuildings` lists all active buildings
`listbuildings mason` lists alĺ mason's workshops
]====]

---------
-- access the list of active buildings, and print according to searchstring
---------
function ListBuildings(searchstring)
    -- variables
    local tmp_name	-- temporary variable for the initial name string
    local building_type	-- building type
    local nickname	-- building's name
    local visible_name	-- the name for printing
    local id		-- building's id
    local index1	-- string.find's return value
    local index2	-- string.find's return value
    local do_search	-- operation mode, list all or search
    local matches = 0	-- counter for matches
    local building_total = #(df.global.world.buildings.all)	-- total number of active buildings

    -- check whether a search string was provided, and set the search mode accordingly
    if searchstring and searchstring ~= nil and searchstring ~= "" then
        do_search = true
    end

    for key,building in ipairs(df.global.world.buildings.all) do
        tmp_name = tostring(building)

        _, _, building_type = string.find(tmp_name, "<building_(%a+_?%a*)st")

        -- if the building is named, use the name
        if building.name and building.name ~= nil and building.name ~= "" then
            nickname = " "..building.name
        else
            nickname = ""
        end

        -- if the building has subtypes, show them
        if building_type == "workshop" then
            visible_name = dfhack.df2utf(building_type..", type "..tonumber(building.type).." "..tostring(df.workshop_type[tonumber(building.type)])..nickname)
        elseif building_type == "civzone" then
            visible_name = dfhack.df2utf(building_type..", type "..tonumber(building.type).." "..tostring(df.civzone_type[tonumber(building.type)])..nickname)
        elseif building_type == "furnace" then
            visible_name = dfhack.df2utf(building_type..", type "..tonumber(building.type).." "..tostring(df.furnace_type[tonumber(building.type)])..nickname)
        else
            visible_name = dfhack.df2utf(building_type..nickname)
        end

        id = building.id

        if do_search then
            -- lua's string.find() is case sensitive, so for a reasonably functional search we'll use lower case only...
            -- ...unless the search string contains capital letters, in which case we don't transform letter case to make use of the extra matching power
            if string.match(searchstring, "[A-Z]") ~= nil then
                index1, index2 = string.find(visible_name, searchstring)
            else
                index1, index2 = string.find(string.lower(visible_name), string.lower(searchstring))
            end

            if index1 ~= nil then
                matches = matches + 1
                print(dfhack.df2console("The building "..visible_name.." (id "..id..") matches: at coords: "..building.x1..","..building.y1..","..building.z))
            end
        else
            print(dfhack.df2console("Found "..visible_name.." (id "..id..") at coords: "..building.x1..","..building.y1..","..building.z..""))
        end
    end

    -- print totals regarding the search/listing operation
    if do_search then
        if matches == 1 then
            print("Found "..matches.." match out of "..building_total.." total active buildings.")
        else
            print("Found "..matches.." matches out of "..building_total.." total active buildings.")
        end
    else
        print("Total active buildings: "..building_total)
    end
end

---------
-- if a search string was provided, use it
-- otherwise we'll just list everything
---------
local opt = {...}
if opt ~= nil then
    ListBuildings(table.concat(opt, ' '))
else
    ListBuildings(false)
end

-- List active units or find a unit by searching
local help = [====[

listunits
=========
Lists active units and their positions, optionally by filter. Filtering is done against unit's full name, translated name, race, caste and profession. Regex is supported - if you're unfamiliar, search for lua regex or lua pattern matching for more info on that.

Accented characters are matched by their base ASCII versions in most cases.

Example usage:

`listunits` lists all active units
`listunits urist` lists all active units that match "urist"
`listunits goat` lists all active units that match "goat"

Fine-tuning with letter case:
`listunits iss` matches Issha Mudungarli, and also any units whose profession is fish dissector
`listunits Iss` matches Issha Mudungarli, but not the fish dissector profession

Fine-tuning with regular expressions:
`listunits man` matches both Cave Swallow Man and Cave Swallow Woman
`listunits [%s^]man` matches only Cave Swallow Man
`listunits ^urist` matches only units whose first name starts exactly with urist, ie., "urist" appearing in last name doesn't match, and also, eg., urîst doesn't match because of the accent
`listunits gen` matches both Or Ágengencesh and Bosa Gengutes
`listunits %sgen` matches Bosa Gengutes but not Or Ágengencesh
]====]

---------
-- convert accented characters to their ASCII versions, for more convenient searching
-- copied from the interwebs
-- knowing these conversions might be useful with searching in some cases, but probably not necessary so I won't include that in help
---------
function stripChars(str)
  local tableAccents = {}
    tableAccents["À"] = "A"
    tableAccents["Á"] = "A"
    tableAccents["Â"] = "A"
    tableAccents["Ã"] = "A"
    tableAccents["Ä"] = "A"
    tableAccents["Å"] = "A"
    tableAccents["Æ"] = "AE"
    tableAccents["Ç"] = "C"
    tableAccents["È"] = "E"
    tableAccents["É"] = "E"
    tableAccents["Ê"] = "E"
    tableAccents["Ë"] = "E"
    tableAccents["Ì"] = "I"
    tableAccents["Í"] = "I"
    tableAccents["Î"] = "I"
    tableAccents["Ï"] = "I"
    tableAccents["Ð"] = "D"
    tableAccents["Ñ"] = "N"
    tableAccents["Ò"] = "O"
    tableAccents["Ó"] = "O"
    tableAccents["Ô"] = "O"
    tableAccents["Õ"] = "O"
    tableAccents["Ö"] = "O"
    tableAccents["Ø"] = "O"
    tableAccents["Ù"] = "U"
    tableAccents["Ú"] = "U"
    tableAccents["Û"] = "U"
    tableAccents["Ü"] = "U"
    tableAccents["Ý"] = "Y"
    tableAccents["Þ"] = "P"
    tableAccents["ß"] = "s"
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["å"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ð"] = "eth"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ø"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["þ"] = "p"
    tableAccents["ÿ"] = "y"

    local normalisedString = str:gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)

    return normalisedString
end

---------
-- access the list of active units, and print according to searchstring
---------
function ListUnits(searchstring)
    -- variables
    local tmp_name	-- temporary variable for the initial name string
    local unit_name	-- the name for printing
    local search_name	-- the name for searching, containing 
    local id		-- unit's id
    local index1	-- string.find's return value
    local index2	-- string.find's return value
    local do_search	-- operation mode, list all or search
    local matches = 0	-- counter for matches
    local unit_total = #(df.global.world.units.active)	-- total number of active units

    -- check whether a search string was provided, and set the search mode accordingly
    if searchstring and searchstring ~= nil and searchstring ~= "" then
        do_search = true
    end

    for key,unit in ipairs(df.global.world.units.active) do
        tmp_name = dfhack.TranslateName(dfhack.units.getVisibleName(unit))
        if not tmp_name or tmp_name == nil or tmp_name == "" then
            -- if the unit doesn't have a name, set caste as its name
            unit_name = dfhack.units.getCasteProfessionName(unit.race, unit.caste, unit.profession)

            -- if we're in search mode, ensure we're working in UTF
            if do_search then
                search_name = dfhack.df2utf(unit_name)
            end
        else
            -- if the unit has a name, we'll add translated name too, and the unit's profession data
            -- this seems to be incomplete - for example, prisoners aren't shown as prisoners
            unit_name = tmp_name.." ("..dfhack.TranslateName(dfhack.units.getVisibleName(unit), true).."), "..dfhack.units.getCasteProfessionName(unit.race, unit.caste, unit.profession)

            -- if we're in search mode, include a non-accented version of the name + use UTF
            if do_search then
                search_name = dfhack.df2utf(tmp_name).." "..stripChars(dfhack.df2utf(tmp_name)).." "..dfhack.df2utf(dfhack.TranslateName(dfhack.units.getVisibleName(unit), true, true)).." "..dfhack.df2utf(dfhack.units.getCasteProfessionName(unit.race, unit.caste, unit.profession))
            end
        end
        id = unit.id

        if do_search then
            -- lua's string.find() is case sensitive, so for a reasonably functional search we'll use lower case only...
            -- ...unless the search string contains capital letters, in which case we don't transform letter case to make use of the extra matching power
            if string.match(searchstring, "[A-Z]") ~= nil then
                index1, index2 = string.find(search_name, searchstring)
            else
                index1, index2 = string.find(string.lower(search_name), string.lower(searchstring))
            end

            if index1 ~= nil then
                matches = matches + 1
                print(dfhack.df2console("The unit "..unit_name.." (id "..id..") matches: at coords: "..unit.pos.x..","..unit.pos.y..","..unit.pos.z))
            end
        else
            print(dfhack.df2console("Found "..unit_name.." (id "..id..") at coords: "..unit.pos.x..","..unit.pos.y..","..unit.pos.z..""))
        end
    end

    -- print totals regarding the search/listing operation
    if do_search then
        if matches == 1 then
            print("Found "..matches.." match out of "..unit_total.." total active units.")
        else
            print("Found "..matches.." matches out of "..unit_total.." total active units.")
        end
    else
        print("Total active units: "..#(df.global.world.units.active))
    end
end

---------
-- if a search string was provided, use it
-- otherwise we'll just list everything
---------
local opt = {...}
if opt ~= nil then
    ListUnits(table.concat(opt, ' '))
else
    ListUnits(false)
end

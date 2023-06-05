--Allow stressed dwarves to emigrate from the fortress
-- Updated for 0.47.05 by wsfsbvchr
-- For 34.11 by IndigoFenix; update and cleanup by PeridexisErrant
-- old version:  http://dffd.bay12games.com/file.php?id=8404
--[====[
emigration
==========
Allows dwarves to emigrate from the fortress when stressed,
in proportion to how badly stressed they are and adjusted
for who they would have to leave with - a dwarven merchant
being more attractive than leaving alone (or with an elf).
The check is made monthly.

A happy dwarf (ie with negative stress) will never emigrate.

Usage::

    emigration enable|disable

]====]

enabled = enabled or false

local args = {...}
if args[1] == "enable" then
    enabled = true
elseif args[1] == "disable" then
    enabled = false
end

function getname(unit)
	local tmp_name = dfhack.TranslateName(dfhack.units.getVisibleName(unit))

	if not tmp_name or tmp_name == nil or tmp_name == "" then
		-- if the unit doesn't have a name, set caste as its name
		unit_name = dfhack.units.getCasteProfessionName(unit.race, unit.caste, unit.profession)
	else
		-- if the unit has a name, we'll add translated name too, and the unit's profession data
		-- this seems to be incomplete - for example, prisoners aren't shown as prisoners
		unit_name = tmp_name.." ("..dfhack.TranslateName(dfhack.units.getVisibleName(unit), true).."), "..dfhack.units.getCasteProfessionName(unit.race, unit.caste, unit.profession)
	end
	return dfhack.df2console(unit_name)
end
            
function desireToStay(unit,method,civ_id)
    -- on a percentage scale
    local value = 100 - unit.status.current_soul.personality.stress_level / 5000
    print("unit "..getname(unit).."\nstress:\t"..unit.status.current_soul.personality.stress_level.."\nvalue:\t"..value.."")
    if method == 'merchant' or method == 'diplomat' then
        if civ_id ~= unit.civ_id then value = value*2 end end
    if method == 'wild' then
        value = value*5 end
    return value
end

function desert(u,method,civ)
	u.following = nil
	local line = dfhack.df2console(dfhack.TranslateName(dfhack.units.getVisibleName(u))) .. " has "
	if method == 'merchant' then
		line = line.."joined the merchants"
		u.flags1.merchant = true
		u.civ_id = civ
	else
		line = line.."abandoned the settlement in search of a better life."
		u.civ_id = civ
		u.flags1.forest = true
		u.flags2.visitor = true
		u.animal.leave_countdown = 2
	end
	
	local hf_id = u.hist_figure_id
	local hf = df.historical_figure.find(u.hist_figure_id)
	local fort_ent = df.global.ui.main.fortress_entity
	local civ_ent = df.historical_entity.find(hf.civ_id)
	
	local newent_id = -1
	local newsite_id = -1
	
	---------------------------------------------
	-- erase the unit from the fortress entity --
	---------------------------------------------
	for k,v in pairs(fort_ent.histfig_ids) do
		if tonumber(v) == hf_id then
			print("Removing histfig_id: "..tostring(v))
			df.global.ui.main.fortress_entity.histfig_ids:erase(k)
			break
		end
	end
	for k,v in pairs(fort_ent.hist_figures) do
		if v.id == hf_id then
			print("Removing hist_figure: "..tostring(v))
			df.global.ui.main.fortress_entity.hist_figures:erase(k)
			break
		end
	end
	for k,v in pairs(fort_ent.nemesis) do
		if v.figure.id == hf_id then
			print("Removing nemesis: "..tostring(v))
			df.global.ui.main.fortress_entity.nemesis:erase(k)
			df.global.ui.main.fortress_entity.nemesis_ids:erase(k)
			break
		end
	end
	
	-- remove the old entity link and create new one to indicate former membership
	hf.entity_links:insert("#", {new = df.histfig_entity_link_former_memberst, entity_id = fort_ent.id, link_strength = 100})
	for k,v in pairs(hf.entity_links) do
		if v._type == df.histfig_entity_link_memberst and v.entity_id == fort_ent.id then
			print("Removing membership_link: "..tostring(v))
			hf.entity_links:erase(k)
			break
		end
	end
	
	---------------------------------------------------
	-- try to find a new entity for the unit to join --
	---------------------------------------------------
	for k,v in pairs(civ_ent.entity_links) do
		if v.type == 1 and v.target ~= fort_ent.id then
			print("newent_id found: "..v.target)
			newent_id = v.target
			break
		end
	end

	if newent_id > -1 then
		hf.entity_links:insert("#", {new = df.histfig_entity_link_memberst, entity_id = newent_id, link_strength = 100})
		
		-------------------------------------------------
		-- try to find a new site for the unit to join --
		-------------------------------------------------
		for k,v in pairs(df.global.world.entities.all[hf.civ_id].site_links) do
			if v.type == 0 and v.target ~= site_id then
				print("newsite_id found: "..v.target)
				newsite_id = v.target
				break
			end
		end
		
		local newent = df.historical_entity.find(newent_id)
		newent.histfig_ids:insert('#', hf_id)
		newent.hist_figures:insert('#', hf)
		
		local hf_event_id = df.global.hist_event_next_id
		df.global.hist_event_next_id = df.global.hist_event_next_id+1
		df.global.world.history.events:insert("#", {new = df.history_event_add_hf_entity_linkst, year = df.global.cur_year, seconds = df.global.cur_year_tick, id = hf_event_id, civ = newent_id, histfig = hf_id, link_type = 0})
		if newsite_id > -1 then
			local hf_event_id = df.global.hist_event_next_id
			df.global.hist_event_next_id = df.global.hist_event_next_id+1
			df.global.world.history.events:insert("#", {new = df.history_event_change_hf_statest, year = df.global.cur_year, seconds = df.global.cur_year_tick, id = hf_event_id, hfid = hf_id, state = 1, reason = -1, site = newsite_id})
		end
	end
	print()
	print(line)
	print()
	dfhack.gui.showAnnouncement(line, COLOR_WHITE)
end

function canLeave(unit)
    if not unit.status.current_soul then
        return false
    end

    return dfhack.units.isCitizen(unit) and
           dfhack.units.isActive(unit) and
           not dfhack.units.isOpposedToLife(unit) and
           not unit.flags1.merchant and
           not unit.flags1.diplomat and
           not unit.flags1.chained and
           dfhack.units.getNoblePositions(unit) == nil and
           unit.military.squad_id == -1 and
           dfhack.units.isSane(unit) and
           not dfhack.units.isBaby(unit) and
           not dfhack.units.isChild(unit)
end

function checkForDeserters(method,civ_id)
    local allUnits = df.global.world.units.active
    for i=#allUnits-1,0,-1 do   -- search list in reverse
        local u = allUnits[i]
        if canLeave(u) then
		local rand = math.random(100)
		local desire = desireToStay(u,method,civ_id)
        	--print("unit "..getname(u).."\nrand:\t"..rand.."\ndesire:\t"..desire.."\n")
        	print("rand:\t"..rand.."\ndesire:\t"..desire.."\n")
        	if rand > desire then
           		desert(u,method,civ_id)
           	end
        end
    end
end

function checkmigrationnow()
    local merchant_civ_ids = {} --as:number[]
    local diplomat_civ_ids = {} --as:number[]
    local allUnits = df.global.world.units.active
    for i=0, #allUnits-1 do
        local unit = allUnits[i]
        if dfhack.units.isSane(unit)
        and dfhack.units.isActive(unit)
        and not dfhack.units.isOpposedToLife(unit)
        and not unit.flags1.tame
        then
            if unit.flags1.merchant then table.insert(merchant_civ_ids, unit.civ_id) end
            if unit.flags1.diplomat then table.insert(diplomat_civ_ids, unit.civ_id) end
        end
    end

    if #merchant_civ_ids == 0 and #diplomat_civ_ids == 0 then
        checkForDeserters('wild', df.global.ui.main.fortress_entity.entity_links[0].target)
    end
    for _, civ_id in pairs(merchant_civ_ids) do checkForDeserters('merchant', civ_id) end
    for _, civ_id in pairs(diplomat_civ_ids) do checkForDeserters('diplomat', civ_id) end
end

local function event_loop()
    if enabled then
        checkmigrationnow()
        dfhack.timeout(1, 'months', event_loop)
    end
end

dfhack.onStateChange.loadEmigration = function(code)
    if code==SC_MAP_LOADED then
        if enabled then
            print("Emigration enabled.")
            event_loop()
        else
            print("Emigration disabled.")
        end
    end
end

if dfhack.isMapLoaded() then
    dfhack.onStateChange.loadEmigration(SC_MAP_LOADED)
end

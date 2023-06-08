-- testing emigration.lua
local help = [====[

stress-tests
================
With this tool you can test emigration.lua

By default, it increases stress levels of all citizens by a step. If a unit is selected, the increase is applied only to that unit.

Each step increases stress levels by 1000-2000 points. The step can be increased by an argument.

arguments:

q/quick			increases the step of stress increase.

These arguments set the stress level straight to numbers that are interesting and fun:

			stress
s/stress/stressed	25000
b/break/breakdown	50000
o/own/ownciv		250000
f/foreign/foreignciv	375000
w/wild/wilderness	450000

]====]
local opt = ...
local args = {...}

local stress_target = -1
local stress_step = 1000
local stress_factor = 1

function stressunit(unit)
	if dfhack.units.isCitizen(unit) then
		if stress_target > -1 then
			unit.status.current_soul.personality.stress = stress_target
		else
			local temp = unit.status.current_soul.personality.stress
			if stress_factor ~= 0 then
				unit.status.current_soul.personality.stress = temp + math.floor(stress_factor*stress_step) + math.random(0, math.floor(stress_factor*stress_step))
			else
				unit.status.current_soul.personality.stress = temp + stress_step + math.random(0, stress_step)
			end
		end
	end
end
function setstresslevels()
	local unit = dfhack.gui.getSelectedUnit(true)
	if unit ~= nil then
		stressunit(unit)
	else
		for key,unit in ipairs(df.global.world.units.active) do
			stressunit(unit)
		end
	end
end

-- main script

if opt and opt ~= "" then
    if opt=="ownciv" or opt=="own" or opt=="o" then
        stress_target = 250000
    elseif opt=="foreignciv" or opt=="foreign" or opt=="f" then
        stress_target = 375000
    elseif opt=="wilderness" or opt=="wild" or opt=="w" then
        stress_target = 450000
    elseif opt=="breakdown" or opt=="break" or opt=="b" then
        stress_target = 50000
    elseif opt=="stressed" or opt=="stress" or opt=="s" then
        stress_target = 25000
    elseif opt=="quick" or opt=="q" then
        stress_factor = 10
    else
        print(help)
    end
end
setstresslevels()
--uncomment these to automate things
--dfhack.run_script('emigration-debug', 'enable')
--dfhack.run_script('emigration-debug', 'disable')

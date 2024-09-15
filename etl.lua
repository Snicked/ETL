ETL_xp_gains = {}
ETL_frame_coordinates = { x = 0, y = 0 }

local REFRESH_INTERVAL = 1

local update_display

local last_update = 0

SLASH_ETL1= "/etl"
SlashCmdList["ETL"] = function(message)
	local cmd = { }
	for c in string.gfind(message, "[^ ]+") do
		table.insert(cmd, string.lower(c))
	end

	if cmd[1] == "clear" then
		ETL_xp_gains = {}
		ETL_frame_coordinates = { x = 0, y = 0 }
	else
		DEFAULT_CHAT_FRAME:AddMessage("etl usage:")
		DEFAULT_CHAT_FRAME:AddMessage("/etl clear - clear saved data")
	end
end

function ETL_on_xp_gain()
	local _, _, xp_part = strfind(arg1, '(%d+)')
	local gained_xp = tonumber(xp_part)
	tinsert(ETL_xp_gains, { t=GetTime(), xp=gained_xp })
end

function ETL_on_load()
	local n = getn(ETL_xp_gains)
	if n > 0 then
		local t0 = ETL_xp_gains[n]
		for _, xp_gain in ETL_xp_gains do
			xp_gain.t = xp_gain.t - t0
		end
	end
	ETL_frame:SetBackdropColor(0,0,0,.8)
end

function ETL_on_update()
	if GetTime() - last_update > REFRESH_INTERVAL then
		last_update = GetTime()
		while ETL_xp_gains[1] and GetTime() - ETL_xp_gains[1].t > 3600 do
			tremove(ETL_xp_gains)
		end
		local xp_per_hour = 0
		local counter = 0
		local average = 0
		for _, xp_gain in ipairs(ETL_xp_gains) do
			xp_per_hour = xp_per_hour + xp_gain.xp
			counter = counter + 1
		end
		if counter > 0 then
			average = xp_per_hour / counter
		end
		if ETL_xp_gains[1] then
			local offset = GetTime() - ETL_xp_gains[1].t
			xp_per_hour = (xp_per_hour / offset) * 3600
		end
		local remaining_xp = UnitXPMax('player') - UnitXP('player')
		local etl =  remaining_xp / xp_per_hour *  60
		local etl_hours = math.floor(etl / 60)
		local etl_minutes = math.ceil(etl - 60 * etl_hours)
		local kills =	'N/A'
		if average > 0 then 
			kills = math.ceil(remaining_xp / average )
		end
		update_display(xp_per_hour, etl_hours, etl_minutes,kills)
	end
end

function update_display(xp_per_hour, etl_hours, etl_minutes, kills)
	ETL_frame_html:SetText(string.format(
			[[
			<html>
			<body>
				<h1 align="left">ETL %s</h1>
				<h2 align="left">XP/hour %i</h2>
				<h3 align="left">KTL %s</h3>
			</body>
			</html>
			]],
			xp_per_hour > 0 and string.format('%ih%im', etl_hours, etl_minutes) or 'N/A',
			xp_per_hour,
			kills
	))
end




q
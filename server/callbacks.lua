function RegisterCallbacks()
	plsr.Callbacks:RegisterServerCallback("Jail:SpawnJailed", function(source, data, cb)
		plsr.Routing:RoutePlayerToGlobalRoute(source)
		local char = plsr.Fetch:CharacterSource(source)
		TriggerClientEvent("Jail:Client:EnterJail", source)
		cb(true)
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:Validate", function(source, data, cb)
		if not plsr.Jail:IsJailed(source) then
			cb(false)
		else
			if data.type == "logout" then
				cb(true)
			else
				cb(false)
			end
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:RetreiveItems", function(source, data, cb)
		plsr.Inventory.Holding:Take(source)
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:Release", function(source, data, cb)
		cb(plsr.Jail:Release(source))
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:StartWork", function(source, data, cb)
		plsr.Labor.Duty:On("Prison", source, false)
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:QuitWork", function(source, data, cb)
		plsr.Labor.Duty:Off("Prison", source, false, false)
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:MakeItem", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if data == "food" or data == "drink" then
			plsr.Inventory:AddItem(char:GetData("SID"), string.format("prison_%s", data), 1, {}, 1)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:MakeJuice", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and data then
			plsr.Inventory:AddItem(char:GetData("SID"), data, 1, {}, 1)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Jail:Server:ExploitAttempt", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			if data == 1 then
				plsr.Logger:Info(
					"Jail",
					string.format(
						"%s %s (%s) attempted to exploit out of prison in a trunk",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID")
					),
					{
						console = true,
						file = true,
						database = true,
						discord = {
							embed = true,
							type = "info",
							webhook = GetConvar("discord_log_webhook", ""),
						},
					}
				)
			elseif data == 2 then
				plsr.Logger:Info(
					"Jail",
					string.format(
						"%s %s (%s) attempted to exploit out of prison by being escorted out",
						char:GetData("First"),
						char:GetData("Last"),
						char:GetData("SID")
					),
					{
						console = true,
						file = true,
						database = true,
						discord = {
							embed = true,
							type = "info",
							webhook = GetConvar("discord_log_webhook", ""),
						},
					}
				)
			end
		end
	end)
end

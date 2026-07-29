local CACHE_TIME = 60000 -- 1 Minute(s)
local cachedData = nil
local lastRefreshed = 0

CreateThread(function()
	RegisterCommands()
	RegisterCallbacks()
	RegisterMiddleware()
	RegisterPrisonSearchStartup()
	RegisterPrisonStashStartup()
	RegisterPrisonCraftingStartup()
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Jail", _JAIL)
end)

function RegisterCommands()
	plsr.Chat:RegisterCommand(
		"jail",
		function(source, args, rawCommand)
			if tonumber(args[1]) and tonumber(args[2]) then
				local char = plsr.Fetch:SID(tonumber(args[1]))
				if char ~= nil then
					plsr.Jail:Sentence(source, char:GetData("Source"), tonumber(args[2]))
					plsr.Chat.Send.System:Single(source, string.format("%s Has Been Jailed For %s Months", args[1], args[2]))
					plsr.Chat.Send.Services:DispatchDOC(
						string.format(
							"%s %s (%s) Has Been Jailed For %s Months",
							char:GetData("First"),
							char:GetData("Last"),
							args[1],
							args[2]
						)
					)
				else
					plsr.Chat.Send.System:Single(source, "State ID Not Logged In")
				end
			else
				plsr.Chat.Send.System:Single(source, "Invalid Arguments")
			end
		end,
		{
			help = "Jail Player",
			params = {
				{
					name = "Target",
					help = "State ID of target",
				},
				{
					name = "Length",
					help = "How long, in months (minutes), to jail player",
				},
			},
		},
		2,
		{
			{
				Id = "police",
			},
			{
				Id = "prison",
			},
		}
	)

	plsr.Chat:RegisterCommand(
		"unjail",
		function(source, args, rawCommand)
			if tonumber(args[1]) then
				local char = plsr.Fetch:SID(tonumber(args[1]))
				if char ~= nil then
					plsr.Jail:Release(char:GetData("Source"), true)
					plsr.Chat.Send.System:Single(source, string.format("%s Has Been Released from Jail", args[1]))
				else
					plsr.Chat.Send.System:Single(source, "State ID Not Logged In")
				end
			else
				plsr.Chat.Send.System:Single(source, "Invalid Arguments")
			end
		end,
		{
			help = "UnJail Player",
			params = {
				{
					name = "Target",
					help = "State ID of target",
				},
			},
		},
		1,
		{
			{
				Id = "police",
			},
			{
				Id = "prison",
			},
		}
	)
end

_JAIL = {
	IsJailed = function(self, source)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			local jailed = char:GetData("Jailed")
			if jailed and not jailed.Released then
				return true
			else
				return false
			end
		else
			return false
		end
	end,
	IsReleaseEligible = function(self, source)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			local jailed = char:GetData("Jailed")
			if not jailed or jailed and jailed.Duration < 9999 and os.time() >= (jailed.Release or 0) then
				return true
			else
				return false
			end
		else
			return false
		end
	end,
	Sentence = function(self, source, target, duration)
		local jailer = plsr.Fetch:CharacterSource(source)
		local jailerName = "LOS SANTOS POLICE DEPARTMENT"
		for k, v in ipairs(jailer:GetData("Jobs")) do
			if v.Id == plsr.State:Player(source).onDuty then
				if v.Workplace ~= nil then
					jailerName = v.Workplace.Name
				else
					jailerName = v.Name
				end
				break
			end
		end

		local char = plsr.Fetch:CharacterSource(target)
		if char ~= nil then
			if char:GetData("ICU") ~= nil and not char:GetData("ICU").Released then
				return false
			end

			plsr.Labor.Jail:Sentenced(target)

			char:SetData("Jailed", {
				Time = os.time(),
				Release = (os.time() + (60 * duration)),
				Duration = duration,
				Released = false,
			})

			CreateThread(function()
				plsr.Jobs.Duty:Off(target, plsr.State:Player(target).onDuty)
				plsr.Handcuffs:UncuffTarget(-1, target)
				plsr.Ped.Mask:UnequipNoItem(target)
				plsr.Inventory.Holding:Put(target)
			end)

			TriggerClientEvent("Jail:Client:Jailed", target)
			plsr.Pwnzor.Players:TempPosIgnore(target)
			plsr.Callbacks:ClientCallback(target, "Jail:DoMugshot", {
				jailer = jailerName,
				duration = duration,
				date = os.date("%c"),
			}, function()
				TriggerClientEvent("Jail:Client:EnterJail", target)

				plsr.EmergencyAlerts:Create("DOC", "New Inmate Arrival", "doc_alerts", {
					street1 = "Bolingbroke Penitentiary",
					x = 1852.444,
					y = 2585.973,
					z = 45.672,
				}, {
					details = "An inmate has just been sentenced.",
					icon = "info",
				}, false, false, nil, false)
			end)

			if duration >= 100 then
				plsr.Loans.Credit:Decrease(char:GetData("SID"), 10)
			end

			cachedData = nil
		else
			return false
		end
	end,
	Reduce = function(self, source, reduction)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil and reduction and type(reduction) == "number" and reduction > 0 and reduction <= 100 then
			local jailData = char:GetData("Jailed")
			if
				jailData
				and not jailData.Released
				and jailData.Release > os.time()
				and math.floor(jailData.Duration - reduction) > 0
			then
				jailData.Duration = math.floor(jailData.Duration - reduction)
				jailData.Release = (jailData.Time + (60 * jailData.Duration))

				if not jailData.Reduced then
					jailData.Reduced = reduction
				else
					jailData.Reduced = jailData.Reduced + reduction
				end

				char:SetData("Jailed", jailData)

				cachedData = nil
				return true
			end
		end
		return false
	end,
	Release = function(self, source)
		if plsr.Jail:IsReleaseEligible(source) then
			local char = plsr.Fetch:CharacterSource(source)
			if char ~= nil then
				plsr.Labor.Jail:Released(source)
				char:SetData("Jailed", false)

				cachedData = nil
				return true
			else
				return false
			end
		else
			plsr.Execute:Client(source, "Notification", "Error", "Not Eligible For Release")
			return false
		end
	end,
	GetPrisoners = function()
		FetchInmates()
		return cachedData
	end,
}

function FetchInmates()
	if cachedData == nil or (GetGameTimer() - lastRefreshed) >= CACHE_TIME then
		local _inmates = {}

		for k, v in pairs(plsr.Fetch:AllCharacters()) do
			local jailed = v:GetData("Jailed")
			if jailed and not jailed.Released then
				table.insert(_inmates, {
					SID = v:GetData("SID"),
					First = v:GetData("First"),
					Last = v:GetData("Last"),
					Jailed = v:GetData("Jailed"),
				})
			end
		end

		cachedData = _inmates
		lastRefreshed = GetGameTimer()
	end
end

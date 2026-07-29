_inPickup = false
_inLogout = false
_doingMugshot = false

CreateThread(function()
	plsr.Blips:Add("prison", "Bolingbroke Penitentiary", vector3(1852.444, 2585.973, 45.672), 188, 65, 0.8)

	plsr.Polyzone.Create:Poly("prison", Config.Prison.points, Config.Prison.options)
	plsr.Polyzone.Create:Poly("prison-logout", Config.Logout.points, Config.Logout.options)
	plsr.Polyzone.Create:Box(
		"prison-pickup",
		Config.Pickup.coords,
		Config.Pickup.length,
		Config.Pickup.width,
		Config.Pickup.options
	)

	plsr.Targeting.Zones:AddBox(
		string.format("bb-retreive", aptId),
		"hands-holding",
		Config.Retreival.coords,
		Config.Retreival.length,
		Config.Retreival.width,
		Config.Retreival.options,
		{
			{
				icon = "hand-holding",
				text = "Retrieve Items",
				event = "Jail:Client:RetreiveItems",
				isEnabled = function()
					return _inPickup
				end,
			},
		},
		3.0,
		true
	)

	plsr.Targeting.Zones:AddBox(
		string.format("prison-inmates-list"),
		"clipboard-list",
		Config.VisitorLog.coords,
		Config.VisitorLog.length,
		Config.VisitorLog.width,
		Config.VisitorLog.options,
		{
			{
				icon = "users-viewfinder",
				text = "View Inmates",
				event = "Jail:Client:ViewInmates",
			},
		},
		3.0,
		true
	)

	plsr.Targeting.Zones:AddBox(
		"prison-check",
		"police-box",
		Config.Payphone.coords,
		Config.Payphone.length,
		Config.Payphone.width,
		Config.Payphone.options,
		{
			{
				icon = "stopwatch",
				text = "Check Remaining Sentence",
				event = "Jail:Client:CheckSentence",
				isEnabled = function()
					return plsr.Jail:IsJailed()
				end,
			},
			{
				icon = "person-from-portal",
				text = "Process Release",
				event = "Jail:Client:Released",
				isEnabled = function()
					return plsr.Jail:IsJailed() and plsr.Jail:IsReleaseEligible()
				end,
			},
		},
		3.0,
		true
	)

	plsr.Targeting.Zones:AddBox(
		"prison-food",
		"bowl-food",
		Config.Cafeteria.Food.coords,
		Config.Cafeteria.Food.length,
		Config.Cafeteria.Food.width,
		Config.Cafeteria.Food.options,
		{
			{
				text = "Make Food",
				event = "Jail:Client:MakeFood",
			},
		},
		3.0,
		true
	)

	plsr.Targeting.Zones:AddBox(
		"prison-drink",
		"mug-hot",
		Config.Cafeteria.Drink.coords,
		Config.Cafeteria.Drink.length,
		Config.Cafeteria.Drink.width,
		Config.Cafeteria.Drink.options,
		{
			{
				text = "Make Drink",
				event = "Jail:Client:MakeDrink",
			},
		},
		3.0,
		true
	)

	plsr.Targeting.Zones:AddBox(
		"prison-juice",
		"droplet",
		Config.Cafeteria.Juice.coords,
		Config.Cafeteria.Juice.length,
		Config.Cafeteria.Juice.width,
		Config.Cafeteria.Juice.options,
		{
			{
				text = "Make Fruit Punch",
				event = "Jail:Client:MakeJuice",
				data = {
					name = "fruitpunchslushie",
				},
			},
			{
				text = "Make BerryRazz",
				event = "Jail:Client:MakeJuice",
				data = {
					name = "beatdownberryrazz",
				},
			},
		},
		3.0,
		true
	)

	plsr.Targeting.Zones:AddBox(
		"prison-payphone",
		"square-phone-flip",
		Config.Payphones.coords,
		Config.Payphones.length,
		Config.Payphones.width,
		Config.Payphones.options,
		{
			{
				text = "Use Payphone",
				event = "Phone:Client:OpenLimited",
			},
		},
		3.0,
		true
	)

	plsr.PedInteraction:Add("PrisonJobs", `csb_janitor`, Config.Foreman.coords, Config.Foreman.heading, 25.0, {
		{
			icon = "clipboard-list",
			text = "Start Work",
			event = "Jail:Client:StartWork",
			data = {},
			isEnabled = function()
				return plsr.State.character.TempJob == nil
			end,
		},
		{
			icon = "clipboard-list",
			text = "Quit Work",
			event = "Jail:Client:QuitWork",
			tempjob = "Prison",
			data = {},
		},
	}, "user-helmet-safety", "WORLD_HUMAN_JANITOR")

	plsr.Callbacks:RegisterClientCallback("Jail:DoMugshot", function(data, cb)
		_disabled = true
		_doingMugshot = true

		plsr.Phone:Close()
		plsr.Interaction:Hide()
		plsr.Inventory.Close:All()

		DoScreenFadeOut(1000)
		while not IsScreenFadedOut() do
			Wait(10)
		end

		plsr.Animations.Emotes:Play("mugshot", false, -1, true)

		DoBoardShit(data.jailer, data.duration, data.date)
		DisableControls()
		SetEntityCoords(
			PlayerPedId(),
			Config.Mugshot.coords.x,
			Config.Mugshot.coords.y,
			Config.Mugshot.coords.z,
			0,
			0,
			0,
			false
		)
		Wait(100)
		SetEntityHeading(PlayerPedId(), Config.Mugshot.headings[1])
		FreezeEntityPosition(PlayerPedId(), true)

		DoScreenFadeIn(1000)
		while not IsScreenFadedIn() do
			Wait(10)
		end

		plsr.Sounds.Play:One("mugshot.ogg", 0.2)
		Wait(2000)
		for i = 2, #Config.Mugshot.headings do
			if plsr.State.flags.loggedIn then
				SetEntityHeading(PlayerPedId(), Config.Mugshot.headings[i])
				Wait(1000)
				plsr.Sounds.Play:One("mugshot.ogg", 0.2)
				Wait(3000)
			end
		end

		SetEntityHeading(PlayerPedId(), Config.Mugshot.headings[1])
		plsr.Sounds.Play:One("mugshot.ogg", 0.2)
		Wait(2000)

		plsr.Animations.Emotes:ForceCancel()
		_doingMugshot = false

		DoScreenFadeOut(1000)
		while not IsScreenFadedOut() do
			Wait(10)
		end

		FreezeEntityPosition(PlayerPedId(), false)
		cb()
	end)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Jail", _JAIL)
end)

_JAIL = {
	IsJailed = function(self)
		if not plsr.State.flags.loggedIn then
			return false
		else
			local jailed = plsr.State.character.Jailed
			if jailed and not jailed.Released then
				return true
			else
				return false
			end
		end
	end,
	IsReleaseEligible = function(self)
		local jailed = plsr.State.character.Jailed
		if jailed and jailed.Duration < 9999 and GetCloudTimeAsInt() >= (jailed.Release or 0) then
			return true
		else
			return false
		end
	end,
}

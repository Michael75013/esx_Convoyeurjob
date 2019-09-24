ESX = nil
local PlayersVente = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'banker', _('bank_customer'), false, false)
TriggerEvent('esx_society:registerSociety', 'banker', 'Banquier', 'society_banker', 'society_banker', 'society_banker', {type = 'public'})

RegisterServerEvent('esx_convoyeurjob:customerDeposit')
AddEventHandler('esx_convoyeurjob:customerDeposit', function (target, amount)
	local xPlayer = ESX.GetPlayerFromId(target)

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_banker', function (account)
		if amount > 0 and account.money >= amount then
			account.removeMoney(amount)

			TriggerEvent('esx_addonaccount:getAccount', 'bank_savings', xPlayer.identifier, function (account)
				account.addMoney(amount)
			end)
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('invalid_amount'))
		end
	end)
end)

RegisterServerEvent('esx_convoyeurjob:customerWithdraw')
AddEventHandler('esx_convoyeurjob:customerWithdraw', function (target, amount)
	local xPlayer = ESX.GetPlayerFromId(target)

	TriggerEvent('esx_addonaccount:getAccount', 'bank_savings', xPlayer.identifier, function (account)
		if amount > 0 and account.money >= amount then
			account.removeMoney(amount)

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_banker', function (account)
				account.addMoney(amount)
			end)
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, _U('invalid_amount'))
		end
	end)
end)

ESX.RegisterServerCallback('esx_convoyeurjob:getCustomers', function (source, cb)
	local xPlayers  = ESX.GetPlayers()
	local customers = {}

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

		TriggerEvent('esx_addonaccount:getAccount', 'bank_savings', xPlayer.identifier, function(account)
			table.insert(customers, {
				source      = xPlayer.source,
				name        = xPlayer.name,
				bankSavings = account.money
			})
		end)
	end

	cb(customers)
end)

function CalculateBankSavings(d, h, m)
	local asyncTasks = {}

	MySQL.Async.fetchAll('SELECT * FROM addon_account_data WHERE account_name = @account_name', {
		['@account_name'] = 'bank_savings'
	}, function(result)
		local bankInterests = 0

		for i=1, #result, 1 do
			local xPlayer = ESX.GetPlayerFromIdentifier(result[i].owner)

			if xPlayer then
				TriggerEvent('esx_addonaccount:getAccount', 'bank_savings', xPlayer.identifier, function(account)
					local interests = math.floor(account.money / 100 * Config.BankSavingPercentage)
					bankInterests   = bankInterests + interests

					table.insert(asyncTasks, function(cb)
						account.addMoney(interests)
					end)
				end)
			else
				local interests = math.floor(result[i].money / 100 * Config.BankSavingPercentage)
				local newMoney  = result[i].money + interests
				bankInterests   = bankInterests + interests

				local scope = function(newMoney, owner)
					table.insert(asyncTasks, function(cb)
						MySQL.Async.execute('UPDATE addon_account_data SET money = @money WHERE owner = @owner AND account_name = @account_name',
						{
							['@money']        = newMoney,
							['@owner']        = owner,
							['@account_name'] = 'bank_savings',
						}, function(rowsChanged)
							cb()
						end)
					end)
				end

				scope(newMoney, result[i].owner)
			end
		end

		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_banker', function(account)
			account.addMoney(bankInterests)
		end)

		Async.parallelLimit(asyncTasks, 5, function(results)
			print('[BANK] Calculated interests')
		end)

	end)
end

TriggerEvent('cron:runAt', 05, 0, CalculateBankSavings)


RegisterServerEvent('esx_convoyeurjob:GiveItem')
AddEventHandler('esx_convoyeurjob:GiveItem', function()
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)

  local Quantity = xPlayer.getInventoryItem(Config.Zones.Vente.ItemRequires).count

  if Quantity >= 20 then
    TriggerClientEvent('esx:showNotification', _source, _U('stop_npc'))
    return
  else
    local amount = Config.Zones.Vente.ItemAdd
    local item = Config.Zones.Vente.ItemDb_name
    xPlayer.addInventoryItem(item, amount)
    TriggerClientEvent('esx:showNotification', _source, 'Vous avez vidé ~g~x' .. amount .. ' DAB')
  end

end)

local function Vente(source)

    SetTimeout(Config.Zones.Vente.ItemTime, function()

        if PlayersVente[source] == true then

            local _source = source
            local xPlayer = ESX.GetPlayerFromId(_source)
            local societyAccount = nil
            local Quantity = xPlayer.getInventoryItem(Config.Zones.Vente.ItemRequires).count

            if Quantity < Config.Zones.Vente.ItemRemove then
                TriggerClientEvent('esx:showNotification', _source, '~r~Vous n\'avez plus de '..Config.Zones.Vente.ItemRequires_name..' à déposer.')
                PlayersVente[_source] = false
            else
                local amount = Config.Zones.Vente.ItemRemove
                local item = Config.Zones.Vente.ItemRequires
                xPlayer.removeInventoryItem(item, amount)
                TriggerClientEvent('esx:showNotification', _source, 'Votre société à reçu ~g~$' .. Config.Zones.Vente.ItemPrice)
                TriggerEvent('esx_addonaccount:getSharedAccount', 'society_banker', function(account)
                    account.addMoney(1000)
                end)
                Vente(_source)
            end
        end
    end)
end

RegisterServerEvent('esx_convoyeurjob:startVente')
AddEventHandler('esx_convoyeurjob:startVente', function()

local _source = source

if PlayersVente[_source] == false then
  TriggerClientEvent('esx:showNotification', _source, '~r~Sortez et revenez dans la zone !')
  PlayersVente[_source] = false
else
  PlayersVente[_source] = true
  TriggerClientEvent('esx:showNotification', _source, '~g~Action ~w~en cours...')
  Vente(_source)
end
end)

RegisterServerEvent('esx_convoyeurjob:stopVente')
AddEventHandler('esx_convoyeurjob:stopVente', function()

local _source = source

if PlayersVente[_source] == true then
  PlayersVente[_source] = false
else
  PlayersVente[_source] = true
end
end)


RegisterServerEvent('esx_convoyeurjob:getStockItem')
AddEventHandler('esx_convoyeurjob:getStockItem', function(itemName, count)

  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_banker', function(inventory)

    local item = inventory.getItem(itemName)

    if item.count >= count then
      inventory.removeItem(itemName, count)
      xPlayer.addInventoryItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_removed') .. count .. ' ' .. item.label)

  end)

end)

ESX.RegisterServerCallback('esx_convoyeurjob:getStockItems', function(source, cb)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_banker', function(inventory)
    cb(inventory.items)
  end)

end)

RegisterServerEvent('esx_convoyeurjob:putStockItems')
AddEventHandler('esx_convoyeurjob:putStockItems', function(itemName, count)

  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)

  TriggerEvent('esx_addoninventory:getSharedInventory', 'society_banker', function(inventory)

    local item = inventory.getItem(itemName)
    local playerItemCount = xPlayer.getInventoryItem(itemName).count

    if item.count >= 0 and count <= playerItemCount then
      xPlayer.removeInventoryItem(itemName, count)
      inventory.addItem(itemName, count)
    else
      TriggerClientEvent('esx:showNotification', xPlayer.source, _U('invalid_quantity'))
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, _U('you_added') .. count .. ' ' .. item.label)

  end)

end)

ESX.RegisterServerCallback('esx_convoyeurjob:getVaultWeapons', function(source, cb)

  TriggerEvent('esx_datastore:getSharedDataStore', 'society_banker', function(store)

    local weapons = store.get('weapons')

    if weapons == nil then
      weapons = {}
    end

    cb(weapons)

  end)

end)

ESX.RegisterServerCallback('esx_convoyeurjob:addVaultWeapon', function(source, cb, weaponName)

  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)

  xPlayer.removeWeapon(weaponName)

  TriggerEvent('esx_datastore:getSharedDataStore', 'society_banker', function(store)

    local weapons = store.get('weapons')

    if weapons == nil then
      weapons = {}
    end

    local foundWeapon = false

    for i=1, #weapons, 1 do
      if weapons[i].name == weaponName then
        weapons[i].count = weapons[i].count + 1
        foundWeapon = true
      end
    end

    if not foundWeapon then
      table.insert(weapons, {
        name  = weaponName,
        count = 1
      })
    end

     store.set('weapons', weapons)

     cb()

  end)

end)

ESX.RegisterServerCallback('esx_convoyeurjob:removeVaultWeapon', function(source, cb, weaponName)

  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)

  xPlayer.addWeapon(weaponName, 1000)

  TriggerEvent('esx_datastore:getSharedDataStore', 'esx_convoyeurjob', function(store)

    local weapons = store.get('weapons')

    if weapons == nil then
      weapons = {}
    end

    local foundWeapon = false

    for i=1, #weapons, 1 do
      if weapons[i].name == weaponName then
        weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
        foundWeapon = true
      end
    end

    if not foundWeapon then
      table.insert(weapons, {
        name  = weaponName,
        count = 0
      })
    end

     store.set('weapons', weapons)

     cb()

  end)

end)

ESX.RegisterServerCallback('esx_convoyeurjob:getPlayerInventory', function(source, cb)

  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)
  local items      = xPlayer.inventory

  cb({
    items      = items
  })

end)

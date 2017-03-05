minetest.register_privilege("mayor",  {
	description="O jogador pode vai poder alterar os terrenos protegidos de outros jogadores!", 
	give_to_singleplayer=false,
})

minetest.register_entity("tradelands:showland",{
	on_activate = function(self, staticdata, dtime_s)
		if type(modTradeLands.time_showarea)~="number" or modTradeLands.time_showarea<=0 then modTradeLands.time_showarea=16	end
		minetest.after(modTradeLands.time_showarea,function()
			self.object:remove()
		end)
	end,
	initial_properties = {
		hp_max = 1,
		physical = true,
		weight = 0,
		collisionbox = {
			modTradeLands.areaSize.side/-2,
			modTradeLands.areaSize.side/-2,
			modTradeLands.areaSize.side/-2,
			modTradeLands.areaSize.side/2,
			modTradeLands.areaSize.side/2,
			modTradeLands.areaSize.side/2,
		},
		visual = "mesh",
		visual_size = {
        	x=modTradeLands.areaSize.side+0.1,
        	y=modTradeLands.areaSize.side+0.1
		},
		mesh = "showland.x",
		textures = {nil, nil, "showland.png", "showland.png", "showland.png", "showland.png"}, -- number of required textures depends on visual
		colors = {}, -- number of required colors depends on visual
		spritediv = {x=1, y=1},
		initial_sprite_basepos = {x=0, y=0},
		is_visible = true,
		makes_footstep_sound = false,
		automatic_rotate = false,
	}
})

modTradeLands.doSave = function()
	local file = io.open(modTradeLands.filedatabase, "w")
	if file then
		file:write(minetest.serialize(modTradeLands.lands))
		file:close()
		--minetest.log('action',"[TRADELANDS] Banco de dados salvo !")
	end
end

modTradeLands.doLoad = function()
	local file = io.open(modTradeLands.filedatabase, "r")
	if file then
		modTradeLands.lands = minetest.deserialize(file:read("*all"))
		file:close()
		if type(modTradeLands.lands)=="table" then
			minetest.log('action',"[TRADELANDS] modTradeLands.doLoad() ==> Abrindo arquivo '"..modTradeLands.filedatabase.."' !")
			return true --true = ok
		end
	end
	modTradeLands.lands = { }
	return false --false = erro/falha
end

modTradeLands.doSoundProtector = function()
	minetest.sound_play("sfx_protector", {gain=1.0}) --Executa um som global!
end

modTradeLands.getMaxDepth = function()
	return 0-(modTradeLands.areaSize.high/2)
end

modTradeLands.canInteract = function(pos, playername)
	if pos and pos.x and pos.y and pos.z then
		if type(playername)=="string" and playername~="" then
			local now = os.time()
			local ownername = modTradeLands.getOwnerName(pos)
			local validate = modTradeLands.getValidate(pos)
	
			--minetest.chat_send_player(playername, "modTradeLands.canInteract(pos, playername) ==> ownername="..dump(ownername).." validate="..dump(validate))
			--minetest.chat_send_player(playername, "modTradeLands.canInteract(pos, playername) ==>  minetest.get_node(pos).name="..dump(minetest.get_node(pos).name))
	
			if 
				ownername=="" --<== Se não existe dono!
				or ownername==playername --<== Se o dono eh o player
				or validate < now --<== Se a protecao esta vencida!
				or minetest.get_player_privs(playername).mayor --<== Verifica se o jogador tem privilegio especial de mayor(prefeito)
				or minetest.get_node(pos).name=="bones:bones"
				or modTradeLands.isGuest(pos, playername)
			then 
				return true
			end
		else
			minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.canInteract(pos, playernames="..dump(playernames)..") A variável 'playername' precisa ser do tipo 'string' não vazia!")
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.canInteract(pos="..dump(pos)..", playername) A variável 'pos' precisa ser do tipo 'position'")
	end
	return false
end

modTradeLands.getOwnerName = function(pos)
	if pos and pos.x and pos.y and pos.z then
		local landname = modTradeLands.getLandName(pos) -- Retorna o Nome do proprietario do territorio.
		local land = modTradeLands.getLand(landname)
		if land and land.owner~=""	then
			return land.owner
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getOwnerName(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'")
	end
	return ""
end

modTradeLands.getDamageInteract = function(pos)
	if pos and pos.x and pos.y and pos.z then
		local landname = modTradeLands.getLandName(pos) -- Retorn o valor do dano que o jogador resceberá se forçar interagir com o terreno.
		local land = modTradeLands.getLand(landname)
		if land and land.damage_interact==true	then
			return modTradeLands.damage_interact
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getDamageInteract(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'")
	end
	return 0
end

modTradeLands.getIfDamageString = function(pos) --Para ser retornada num formato aceitavel para formspec
	if pos and pos.x and pos.y and pos.z then
		local damage = modTradeLands.getDamageInteract(pos)
		if damage>0 then return "true" end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getIfDamageString(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'")
	end
	return "false"
end

modTradeLands.ifMobCanAttack = function(pos)
	if pos and pos.x and pos.y and pos.z then
		local now = os.time()
		local ownername = modTradeLands.getOwnerName(pos)
		local validate = modTradeLands.getValidate(pos)
	
		if ownername~="" and validate >= now	then 
			return false
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.ifMobCanAttack(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'")
	end
	return true
end

modTradeLands.getPvpType = function(pos) -- Retorn a configuracao de Pvp no formato string que o jogador escolheu para seu territorio. Se não for um terreno protegido voltara o valor 'default_pvp' do arquivo 'config.lua'.
	if pos and pos.x and pos.y and pos.z then
		local landname = modTradeLands.getLandName(pos)
		local land = modTradeLands.getLand(landname)
		if land and type(land.pvp_type)=="string" and land.pvp_type~="" then
			return land.pvp_type
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getPvpType(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'")
	end
	return modTradeLands.default_pvp
end

modTradeLands.getPvpStrings = function()
	local pvpTypes = modTradeLands.pvp_types --Inserido no arquivo 'config.lua'
	local pvpStrings = ""
	for i, myType in ipairs(pvpTypes) do
		pvpStrings=pvpStrings..minetest.formspec_escape(myType)
		if i < #pvpTypes then
			pvpStrings=pvpStrings..","
		end
	end
	return pvpStrings
end

modTradeLands.getPvpTypeIndex = function(pos) -- Retorn a configuracao de Pvp no formato number(para Index) que o jogador escolheu para seu territorio
	if pos and pos.x and pos.y and pos.z then
		local pvpTypes = modTradeLands.pvp_types --Inserido no arquivo 'config.lua'
		local pvpType = modTradeLands.getPvpType(pos)
		for i, myType in ipairs(pvpTypes) do
			if myType==pvpType then
				return i
			end
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getPvpTypeIndex(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'")
	end
	return 0
end

modTradeLands.ifCanPvp = function(pos, hittername)
	if pos and pos.x and pos.y and pos.z then
		if type(hittername)=="string" and hittername~="" then
			local ownername = modTradeLands.getOwnerName(pos)
			local strPvpType = modTradeLands.getPvpType(pos)
			--minetest.chat_send_all("strPvpType="..strPvpType)
			if strPvpType==modTradeLands.pvp_types[1] then
				return false --true = Cancela o PVP
			elseif strPvpType==modTradeLands.pvp_types[2] and ownername~="" and hittername~=ownername then
				return false --true = Cancela o PVP
			elseif strPvpType==modTradeLands.pvp_types[3] and not modTradeLands.canInteract(pos, hittername) then
				return false --true = Cancela o PVP
			end
		else
			minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.ifCanPvp(pos, hittername="..dump(hittername)..") A variável 'hittername' precisa ser do tipo 'string' não vazia!")
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.ifCanPvp(pos="..dump(pos)..", hittername) A variável 'pos' precisa ser do tipo 'position'!")
	end
	return true
end

modTradeLands.getGuests = function(pos) --Retorna uma tabela contendo o nomes dos convidados do terreno
	if pos and pos.x and pos.y and pos.z then
		local landname = modTradeLands.getLandName(pos)
		local land = modTradeLands.getLand(landname)
		if land and type(land.guests)=="table" and #land.guests >=1	then
			return land.guests
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getGuests(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	return {}
end

modTradeLands.getGuestsTextList = function(pos)  --Retorna uma linha (para formspecs) contendo o nomes separados por virgula dos convidados do terreno.
	if pos and pos.x and pos.y and pos.z then
		local guests = modTradeLands.getGuests(pos)
		if #guests>=1 then
			local listGuests = ""
			for i, guest in ipairs(guests) do
				listGuests = listGuests .. guest
				if i < #guests then
					listGuests = minetest.formspec_escape(listGuests) .. ","
				end
			end
			return listGuests
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getGuestsTextList(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	return ""
end

modTradeLands.isGuest = function(pos, playername) --Verifica se um nome especifico é um dos convidados para alterar o terreno.
	if pos and pos.x and pos.y and pos.z then
		if type(playername)=="string" and playername~="" then
			local guests = modTradeLands.getGuests(pos)
			for i, guest in pairs(guests) do 
				if guest==playername then
					return true
				end
			end
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.isGuest(pos, playername) A variavel 'playername' precisa ser um nome de jogador!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.isGuest(pos="..dump(pos)..", playername) A variavel 'pos' precisa ser do tipo 'position'!")
	end
	return false
end

modTradeLands.getPermanentValidate = function(pos)
	if pos and pos.x and pos.y and pos.z then
		local now = os.time()
		if type(modTradeLands.protected_days)~="number" or modTradeLands.protected_days==0 then 
			return true 
		end
	
		local landname = modTradeLands.getLandName(pos) -- Retorn o valor do dano que o jogador resceberá se forçar interagir com o terreno.
		local land = modTradeLands.getLand(landname)
		if land and type(land.permanent_validate)=="boolean" then
			return land.permanent_validate
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getPermanentValidate(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	return false
end

modTradeLands.getValidate = function(pos) -- Retorna a 'datetime' de validade da proteção do terreno no formato number
	if pos and pos.x and pos.y and pos.z then
		local now = os.time()

		if modTradeLands.getPermanentValidate(pos) then
			return now+(60*60*24*365.25*100) --Retorna uma validade de 100 anos
		end

		local landname = modTradeLands.getLandName(pos) -- Area selecionada
		local land = modTradeLands.getLand(landname)
		if land and type(land.validate)=="number" and land.validate>0 then
			return land.validate
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getValidate(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	return 0
end

modTradeLands.getValidateRest = function(pos)
	local rest = 0
	if pos and pos.x and pos.y and pos.z then
		local validate = modTradeLands.getValidate(pos)
		local now = os.time()
		rest = validate - now
		if rest<0 then rest=0 end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getValidateRest(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	return rest
end

modTradeLands.getDaysRest = function(pos)
	local dayRest = 0
	if pos and pos.x and pos.y and pos.z then
		dayRest = modTradeLands.getValidateRest(pos) / (60*60*24)
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getDaysRest(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	if dayRest < 0 then dayRest = 0 end
	return dayRest
end

modTradeLands.getValidateString = function(timeMoment) --Converte uma 'datetime' em formato string de facil entendimento para humanos. (^_^)
	local valString = ""
	if type(timeMoment)=="number" then
		valString = os.date("%Y-%m-%d %Hh:%Mm:%Ss", timeMoment)
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getValidateString(timeMoment="..dump(timeMoment)..") A variável 'timeMoment' precisa ser do tipo 'number' de datetime!")
	end
	return valString
end

modTradeLands.getNewValidate = function(pos) -- Retorna uma nova 'datetime' de vencimento no formato 'number' de acordo com a configuração 'protected_days' do arquivo 'config.lua'
	local now = os.time()
	local newValidate = now + (60*60*24*365.25*100) --Validade de (100 anos).
	if pos and pos.x and pos.y and pos.z then
		if type(modTradeLands.protected_days)=="number" and modTradeLands.protected_days>0 then
			local restValidate = modTradeLands.getValidateRest(pos)
			newValidate = now + (60*60*24*modTradeLands.protected_days) + restValidate --Validade de 2.592.000 segundos (30 dias).
		end
	else
		minetest.log('error',"[TRADELANDS:ERRO] modTradeLands.getNewValidate(pos="..dump(pos)..") A variável 'pos' precisa ser do tipo 'position'!")
	end
	return newValidate
end


modTradeLands.getLandName = function(pos) -- Retorna o endereço do lote do terreno no formato string
	if pos and pos.x and pos.y and pos.z then
		local p = {}
		local side = modTradeLands.areaSize.side
		local high = modTradeLands.areaSize.high
		p.x = math.floor(pos.x/side)
		p.y = math.floor((pos.y+(high/2))/high)
		p.z = math.floor(pos.z/side)
		return "x"..p.x..",y"..p.y..",z"..p.z
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.getLandName(pos="..dump(pos)..") A variavel 'pos' não é uma posição valida!")
	end
	return "x0,y0,z0"
end

modTradeLands.getPosShowLand = function(pos) -- retorna a posição central para a instancia que mostrará os limites do terreno.
	local p = {}
	if pos and pos.x and pos.y and pos.z then
		local side = modTradeLands.areaSize.side
		local high = modTradeLands.areaSize.high
		p.x = (math.floor(pos.x/side)*side)+(side/2)-0.5
		--p.y = math.floor(pos.y/high)+(side/2)
		p.y = pos.y+0.5
		p.z = (math.floor(pos.z/side)*side)+(side/2)-0.5
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.getPosShowLand(pos="..dump(pos)..") A variavel 'pos' não é uma posição valida!")
	end
	return p
end

modTradeLands.doShowLand = function(playername) --Cria uma instancia no mapa mostrando os limites do terreno por tempo limitado de acordo com a configuração 'time_showarea' do arquivo config.lua
	if type(playername)=="string" and playername~="" then
		local player = minetest.get_player_by_name(playername) 
		if player and player:is_player() then --Verifica se o player ainda esta online. (verificacao por motivo de lag)
			local pos = player:getpos()	
			local entpos = modTradeLands.getPosShowLand(pos)
			entpos.y = (pos.y-1)
			minetest.env:add_entity(entpos, "tradelands:showland")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.doShowLand(playername) A variavel 'playername' nao estah do tipo 'string'!")
	end
end

modTradeLands.doGiveUpLand = function(pos) --Impões se o terreno vai haver dano.
	if pos and pos.x and pos.y and pos.z then
		local landname = modTradeLands.getLandName(pos)
		if type(modTradeLands.lands)=="table" and type(modTradeLands.lands[landname])=="table" then
			modTradeLands.lands[landname] = nil --Isso apaga o terreno!
			return true
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.doGiveUpLand(pos="..dump(pos)..") A variavel 'pos' nao eh do tipo 'position'!")
	end
	return false
end

modTradeLands.getLand = function(landname) --Retorna uma tabela do tipo 'Land' contendo as informações do terreno.
	if
		type(modTradeLands.lands)=="table" 
		and type(modTradeLands.lands[landname])=="table"
	then
		return modTradeLands.lands[landname]
	end
end

modTradeLands.setOwnerName = function(pos, playername) --Insere o nome do proprietario do terreno.
	if pos and pos.x and pos.y and pos.z then
		if type(playername)=="string" then
			local landname = modTradeLands.getLandName(pos)
			if type(modTradeLands.lands)~="table" then modTradeLands.lands={}	end
			if type(modTradeLands.lands[landname])~="table" then modTradeLands.lands[landname]={}	end
			modTradeLands.lands[landname].owner=playername
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.setOwnerName(pos, playername) A variavel 'playername' nao estah do tipo 'string'!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.setOwnerName(pos, playername) A variavel 'pos' nao estah do tipo 'position'!")
	end
end

modTradeLands.setIfDamageInteract = function(pos, ifDamage) --Impões se o terreno vai haver dano.
	if pos and pos.x and pos.y and pos.z then
		if type(ifDamage)=="boolean" then
			local landname = modTradeLands.getLandName(pos)
			if type(modTradeLands.lands)~="table" then modTradeLands.lands={}	end
			if type(modTradeLands.lands[landname])~="table" then modTradeLands.lands[landname]={}	end
			modTradeLands.lands[landname].damage_interact = ifDamage
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.setIfDamageInteract(pos, ifDamage) A variavel 'ifDamage' precisa ser uma variável 'boolean'!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.setIfDamageInteract(pos, ifDamage) A variavel 'pos' precisa ser uma variável 'position'!")
	end
end

modTradeLands.setPvpType = function(pos, newType) --Insere o tipo de pvp permitido no terreno
	if pos and pos.x and pos.y and pos.z then
		local pvpTypes = modTradeLands.pvp_types
		local selPvpType = 0
		if type(newType)=="string" and newType~="" then
			for i, myType in ipairs(pvpTypes) do
				if myType == newType then
					selPvpType = i
					break
				end
			end
		end

		if type(newType)=="string" and newType~="" and selPvpType>=1 then
			local landname = modTradeLands.getLandName(pos)
			if type(modTradeLands.lands)~="table" then modTradeLands.lands={}	end
			if type(modTradeLands.lands[landname])~="table" then modTradeLands.lands[landname]={}	end
			modTradeLands.lands[landname].pvp_type = newType
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.setPvpType(pos, newType) A variavel 'newType' precisa ser uma variável 'string' de tipo de pvp!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.setPvpType(pos, newType) A variavel 'pos' precisa ser uma variável 'position'!")
	end
end

modTradeLands.setGuests = function(pos, tblGuests) --Insere na configuração do territorio uma tabela contendo os nomes dos convidados.
	if pos and pos.x and pos.y and pos.z then
		if type(tblGuests)=="table" then
			local landname = modTradeLands.getLandName(pos)
			if type(modTradeLands.lands)~="table" then modTradeLands.lands={}	end
			if type(modTradeLands.lands[landname])~="table" then modTradeLands.lands[landname]={}	end
			modTradeLands.lands[landname].guests = tblGuests
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.setGuests(pos, tblGuests) A variavel 'tblGuests' precisa ser uma variável 'table'!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.setGuests(pos, tblGuests) A variavel 'pos' precisa ser uma variável 'position'!")
	end
end

modTradeLands.addGuest = function(pos, playername) --Adiciona um convidado no formato 'string' junto lista de convidados do terreno.
	if pos and pos.x and pos.y and pos.z then
		if type(playername)=="string" and playername~="" then
			local guests = modTradeLands.getGuests(pos)
			table.insert(guests, minetest.formspec_escape(playername))
			modTradeLands.setGuests(pos, guests)
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.addGuest(pos, playername) A variavel 'playername' precisa ser o nome de um jogador!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.addGuest(pos, playername) A variavel 'pos' precisa ser uma variável 'position'!")
	end	
end

modTradeLands.delGuest = function(pos, nameOrIndex) -- Remove um convidado da lista de convidados do terreno através de um nome de jogador, ou atraves de um número de índice.
	if pos and pos.x and pos.y and pos.z then
		local guests = modTradeLands.getGuests(pos)
		if type(nameOrIndex)=="number" and nameOrIndex >=1 and nameOrIndex <= #guests then
			table.remove(guests, nameOrIndex)
			modTradeLands.setGuests(pos, guests)
		elseif type(nameOrIndex)=="string" and nameOrIndex~="" then
			for i, guest in pairs(guests) do 
				if guest==nameOrIndex then
					table.remove(guests, i)
					break
				end
			end
			modTradeLands.setGuests(pos, guests)
		else
			minetest.log('error',"[TRADELANDS] modTradeLands.delGuest(pos, nameOrIndex) A variavel 'nameOrIndex' precisa ser um nome de jogador, ou o número do convidado na lista!")
		end
	else
		minetest.log('error',"[TRADELANDS] modTradeLands.delGuest(pos, nameOrIndex) A variavel 'pos' precisa ser uma variável 'position'!")
	end
end

modTradeLands.setPermanentValidate = function(pos, ifPernanete)
	if pos and pos.x and pos.y and pos.z then
		if type(ifPernanete)=="boolean" then
			local landname = modTradeLands.getLandName(pos) -- Retorn o valor do dano que o jogador resceberá se forçar interagir com o terreno.
			local land = modTradeLands.getLand(landname)
			land.permanent_validate = ifPernanete
		else
			minetest.log('error',"[TRADELANDS:ERROR] modTradeLands.setPermanentValidate(pos, ifPernanete) A variavel 'ifPernanete' não é do tipo 'boolean'!")
		end
	else
		minetest.log('error',"[TRADELANDS:ERROR] modTradeLands.setPermanentValidate(pos, ifPernanete) A variavel 'pos' não é do tipo 'position'!")
	end
end

modTradeLands.setValidate = function(pos, timeSecounds) --Insere uma nova validade no formato 'datetime_number' ao terreno.
	if pos and pos.x and pos.y and pos.z then
		if type(timeSecounds)=="number" and timeSecounds>=0 then
			local landname = modTradeLands.getLandName(pos)
			if type(modTradeLands.lands)~="table" then modTradeLands.lands={}	end
			if type(modTradeLands.lands[landname])~="table" then modTradeLands.lands[landname]={}	end
			modTradeLands.lands[landname].validate=timeSecounds
		else
			minetest.log('error',"[TRADELANDS:ERROR] modTradeLands.setValidate(pos, timeSecounds) A variavel 'timeSecounds' não é do tipo 'number' não-negativa!")
		end
	else
		minetest.log('error',"[TRADELANDS:ERROR] modTradeLands.setValidate(pos, timeSecounds) A variavel 'pos' não é do tipo 'position'!")
	end	
end

modTradeLands.old_is_protected = minetest.is_protected
function minetest.is_protected (pos, playername)
	if modTradeLands.canInteract(pos, playername) then
		return modTradeLands.old_is_protected(pos,playername)
	end
	return true
end

minetest.register_on_protection_violation(function(pos, playername)
	if not modTradeLands.canInteract(pos, playername) then
		local player = minetest.get_player_by_name(playername) 
		if player and player:is_player() then  -- Verifica se o player esta online
			local damage = modTradeLands.getDamageInteract(pos)
			--minetest.chat_send_player(playername, "[TRADELANDS] minetest.register_on_protection_violation(pos, playername) damage="..damage)
			if damage>0 then
				player:set_hp(player:get_hp()-damage) 
			end
			
			--minetest.chat_send_player(playername, "[TRADELANDS] Voce está tentando cavar o terreno que pertence a '"..modTradeLands.getOwnerName(pos).."' ate '"..modTradeLands.getValidateString(modTradeLands.getValidate(pos)).."'!")
			minetest.chat_send_player(playername, "[TRADELANDS] Voce está tentando cavar o terreno que pertence a '"..modTradeLands.getOwnerName(pos).."'!")
		
			local ownername = modTradeLands.getOwnerName(pos)
			if ownername and ownername~="" then
				local owner = minetest.get_player_by_name(ownername) 		
				if owner and owner:is_player() then
					minetest.chat_send_player(ownername, "[TRADELANDS] O '"..playername.."' está tentando cavar em seu terreno!")
				end
			end
			return
		end
	end
	return true
end)

minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if hitter and hitter:is_player() and type(hitter:get_player_name())=="string" and hitter:get_player_name()~="" then
		return not modTradeLands.ifCanPvp(player:getpos(), hitter:get_player_name())	
	end
end)

modTradeLands.default_place = minetest.item_place
function minetest.item_place(itemstack, placer, pointed_thing)
	local ownername = modTradeLands.getOwnerName(pointed_thing.above)
	local playername = placer:get_player_name()
	local pos = pointed_thing.above
	
	if minetest.get_node(pos).name == "bones:bones" then 
		return itemstack
	end
	
	if modTradeLands.canInteract(pointed_thing.above,playername) or itemstack:get_name() == "" then
		-- add a workaround for TNT, since overwriting the registered node seems not to work
		if itemstack:get_name() == "tnt:tnt" or itemstack:get_name() == "tnt:tnt_burning" then
			local temp_pos = pos
			temp_pos.x = pos.x + 2
			if playername ~= modTradeLands.getOwnerName(temp_pos) then
				minetest.chat_send_player( playername, "Nao coloque TNT perto de areas protegida!" )
				return itemstack
			end
			temp_pos.x = pos.x - 2
			if playername ~= modTradeLands.getOwnerName(temp_pos) then
				minetest.chat_send_player( playername, "Nao coloque TNT perto de areas protegida!!!" )
				return itemstack
			end
			temp_pos.z = pos.z + 2
			if playername ~= modTradeLands.getOwnerName(temp_pos) then
				minetest.chat_send_player( playername, "Nao coloque TNT perto de areas protegida!!!" )
				return itemstack
			end
			temp_pos.z = pos.z - 2
			if playername ~= modTradeLands.getOwnerName(temp_pos) then
				minetest.chat_send_player( playername, "Nao coloque TNT perto de areas protegida!!!" )
				return itemstack
			end
		end
		-- end of the workaround
		return modTradeLands.default_place(itemstack, placer, pointed_thing)
	else
		if ownername~="" then
			--minetest.chat_send_player(playername, "[TRADELANDS] Este terreno pertence a '"..modTradeLands.getOwnerName(pos).."' ate '"..modTradeLands.getValidateString(modTradeLands.getValidate(pos)).."'!")
			minetest.chat_send_player(playername, "[TRADELANDS] Este terreno pertence a '"..modTradeLands.getOwnerName(pos).."'!")
		
			local ownername = modTradeLands.getOwnerName(pos)
			if ownername and ownername~="" then
				local owner = minetest.get_player_by_name(ownername) 		
				if owner and owner:is_player() then
					minetest.chat_send_player(ownername, "[TRADELANDS] O '"..playername.."' está tentando mexer em seu terreno!")
				end
			end
		
		
			--minetest.chat_send_player(playername, "Esta area pertence a '"..ownername.."'.")
			return itemstack
		else
			minetest.chat_send_player(playername,"Area nao protegida, reivindique essa area para construir ou minerar.")
			return itemstack
		end
	end
end

minetest.register_on_newplayer(function(player)
	modTradeLands.doSave()
end)

minetest.register_on_joinplayer(function(player)
	modTradeLands.doSave()
end)

minetest.register_on_leaveplayer(function(player)
	modTradeLands.doSave()
end)

minetest.register_on_shutdown(function()
	modTradeLands.doSave()
end)

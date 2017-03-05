modTradeLands.getDetachedInventory = function() --criar um inventario desatachado de nome 'detached:charter'
	local newInv = minetest.create_detached_inventory("charter", { --trunk
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player) 
			if from_list=="listPrice" then return 0 end
			return count
		end,
		allow_put = function(inv, listname, index, stack, player) 
			if listname=="listPrice" then return 0 end
			return stack:get_count()
		end,
		allow_take = function(inv, listname, index, stack, player) 
			if listname=="listPrice" then return 0 end
			return stack:get_count()
		end,

		on_move = function(inv, from_list, from_index, to_list, to_index, count, player) end,
		on_put = function(inv, listname, index, stack, player) end,
		on_take = function(inv, listname, index, stack, player) end,
		
	})
	newInv:set_size("listPrice", 2*2)
	newInv:set_size("listPay", 2*2)
	local price = modTradeLands.price
	if #price>=1 then
		for i=1,#price do
			newInv:add_item("listPrice", ItemStack(price[i]))	
		end
	end
	
	return newInv
end

modTradeLands.getFormMain = function(pos, playername)
	local landname = modTradeLands.getLandName(pos) -- Area selecionada
	local ifPermanentValidate = modTradeLands.getPermanentValidate(pos)
	local frmHeight = 1.5 --3.25
	local formspec = ""
	--.."bgcolor[#636D76FF;false]"
	--..default.gui_bg
	--..default.gui_bg_img
	--..default.gui_slots
	.."label[0,0;ALVARÁ DE TERRENO]"
	.."button_exit[0,0.50;3,1;btnShowLand;Exibir Tamanho]"
	
	if not ifPermanentValidate then
		frmHeight=frmHeight+0.75
		formspec=formspec.."button[0,"..(frmHeight-1)..";3,1;btnPayForm;Proteger Terreno]"
	end
	
	local ownername = modTradeLands.getOwnerName(pos)
	if ownername~="" then
		if ownername==playername or minetest.get_player_privs(playername).mayor then
			frmHeight=frmHeight+0.75
			formspec=formspec.."button[0,"..(frmHeight-1)..";3,1;btnGuestsForm;Listar Convidados]"
		
			frmHeight=frmHeight+0.75
			formspec=formspec.."button[0,"..(frmHeight-1)..";3,1;btnConfigForm;Configurar]"

			frmHeight=frmHeight+0.75
			formspec=formspec.."button[0,"..(frmHeight-1)..";3,1;btnGiveUpForm;Abandonar Terreno]"

			if minetest.get_player_privs(playername).mayor then
				frmHeight=frmHeight+0.75
				formspec=formspec.."checkbox[0,"..(frmHeight-1)..";chkPermanentValidate;Proteção Permanente;"..tostring(ifPermanentValidate).."]"
			end
		end
	end
	
	formspec=formspec.."label[0,"..(frmHeight-0.25)..";Terreno: "..landname.."]"

	return "size[3,"..frmHeight.."]"..formspec
end

modTradeLands.getFormGiveUpLand = function(pos, playername)
	local formspec = "size[5.5,2.5]"
	--.."bgcolor[#636D76FF;false]"
	--..default.gui_bg
	--..default.gui_bg_img
	--..default.gui_slots
	.."label[0,0;ABANDONO DE TERRENO]"
	.."label[0,0.75;Deseja realmente desproteger deste terreno?]"
	.."button[0.5,1.5;2,1;btnGiveUpYes;Desproteger]"
	.."button[3.0,1.5;2,1;btnGiveUpNot;Cancelar]"
	return formspec
end

modTradeLands.getFormSpecGuests = function(pos, playername)
	local listGuests = modTradeLands.getGuestsTextList(pos)
	local formspec = "size[4,5.5]"
	--.."bgcolor[#636D76FF;false]"
	--..default.gui_bg
	--..default.gui_bg_img
	--..default.gui_slots
	.."label[0,0;CONVIDADOS DO TERRENO]"
	.."textlist[0,0.5;3.85,2;selGuest;"..listGuests..";0;false]"
	.."button[0,2.60;4,1;btnDelGuest;Remover Convidado]"
	--.."pwdfield[0.29,4.25;4,1;txtNewGuest;Nome do Convidado]"
	.."field[0.29,4.25;4,1;txtNewGuest;Nome do Convidado;]"
	.."button[0,4.75;4,1;btnNewGuest;Adicionar Convidado]"
	return formspec
end

modTradeLands.getFormSpecConfig = function(pos, playername)
	local damage = modTradeLands.getDamageInteract(pos)
	local ifDamageString = modTradeLands.getIfDamageString(pos)
	local pvpTypeIndex = modTradeLands.getPvpTypeIndex(pos)
	local pvpStrings = modTradeLands.getPvpStrings()
	
	local formspec = "size[5,2.5]"
	--.."bgcolor[#636D76FF;false]"
	--..default.gui_bg
	--..default.gui_bg_img
	--..default.gui_slots
	.."label[0,0;CONFIGURAÇÃO DO TERRENO]"
	--{"checkbox", x=<X>, y=<Y>, name="<name>", label="<label>", selected=<selected>}
	.."checkbox[0,0.50;chkIfDamage;Habilitar dano de interação forçada;"..ifDamageString.."]"

	.."label[0,1.62;"..minetest.formspec_escape("Tipo de PVP:").."]"
	.."dropdown[1.75,1.5;3,0.25;selPvpType;"..pvpStrings..";"..pvpTypeIndex.."]"
	return formspec
end

modTradeLands.getFormSpecPay = function(pos, playername)
	local ownername = modTradeLands.getOwnerName(pos)
	if ownername=="" then ownername="nenhum" end
	local dayRests =  modTradeLands.getDaysRest(pos)
	local strValidate = "nenhum"
	local strRest = ""
	if dayRests>0 then 
		strValidate = modTradeLands.getValidateString(modTradeLands.getValidate(pos)) 
		if dayRests > 0 then strRest="(restam "..math.ceil(dayRests).." dias)"	end
	end
	local strNewValidate = modTradeLands.getValidateString(modTradeLands.getNewValidate(pos))
	if modTradeLands.protected_days>0 then
		strNewValidate=strNewValidate.." (até "..modTradeLands.protected_days.." dias)"
	end

	local formspec = "size[8,9]"
	--.."bgcolor[#636D76FF;false]"
	--..default.gui_bg
	--..default.gui_bg_img
	--..default.gui_slots
	.."label[1.5,0;ALVARÁ DE PROTEÇÃO DE TERRENO]"
	
	--.."vertlabel[0,3;Preço:]"
	.."label[0.5,0.5;Taxa:]"
	.."list[detached:charter;listPrice;0.5,1;2,2;]"

	.."label[3.5,0.5;Pagamento:]"
	.."list[detached:charter;listPay;3.5,1;2,2;]"


	.."label[0.5,3;Vencimento: "..strValidate.." "..strRest.."\n"
	.."Renovação: "..strNewValidate.."]"

	.."label[0.5,4;Atual Dono: "..ownername.." \n"
	.."Novo Dono: "..playername.." ]"

	--.."button[5.5,1.00;2,1;btnPay;Pagar]"
	.."button_exit[5.5,1.00;2,1;btnPay;Pagar]"
	.."button_exit[5.5,1.75;2,1;btnCancel;Cancelar]"
	.."list[current_player;main;0,5;8,4;]"
	return formspec
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "frmTradelands" then -- This is your form name
		local playername = player:get_player_name()
		local playerpos = player:getpos()
		--minetest.chat_send_player(playername, "minetest.register_on_player_receive_fields(player, formname, fields) ==> playername='"..playername.."' formname='"..formname.."' fields="..dump(fields))
		if fields.btnShowLand then
			minetest.chat_send_player(playername, "[TRADELANDS] Exibindo o tamanho do terreno atual!")
			modTradeLands.doShowLand(playername) --Mostra o limite do territorio onde o jogador esta.
		elseif fields.btnPayForm then
			if type(modTradeLands.formPlayer)=="nil" then modTradeLands.formPlayer = {} end
			if type(modTradeLands.formPlayer[playername])=="nil" then modTradeLands.formPlayer[playername] = {} end
			modTradeLands.formPlayer[playername].invLandPay = modTradeLands.getDetachedInventory()
			modTradeLands.formPlayer[playername].selPos = playerpos --ATENCAO: O terreno protegido eh onde o jogador esta, e nao onde o jogar apontar.
			modTradeLands.doShowLand(playername) --Mostra o limite do territorio onde o jogador esta.
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormSpecPay(playerpos, playername))
		elseif fields.btnPay then
			modTradeLands.doPay(playername)
		elseif fields.btnCancel or fields.quit then
			modTradeLands.giveChange(playername)
		elseif fields.btnGuestsForm then
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormSpecGuests(playerpos, playername))
		elseif fields.btnNewGuest then
			if type(fields.txtNewGuest)=="string" and fields.txtNewGuest~="" then
				modTradeLands.addGuest(playerpos, fields.txtNewGuest)
			else
				minetest.chat_send_player(playername, "[TRADELANDS:ERRO] Digite o 'nome do convidado' antes de pressionar o botão 'Adicionar Comvidado'!")
			end
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormSpecGuests(playerpos, playername))
		elseif fields.selGuest then
			if type(modTradeLands.formPlayer)=="nil" then modTradeLands.formPlayer = {} end
			if type(modTradeLands.formPlayer[playername])=="nil" then modTradeLands.formPlayer[playername] = {} end
			

			local guests = modTradeLands.getGuests(playerpos)
			local event = minetest.explode_textlist_event(fields.selGuest)
			--minetest.chat_send_player(playername, "event="..dump(event))
			if event.type=="CHG" and event.index>=1 and event.index<=#guests then
				modTradeLands.formPlayer[playername].selGuest = event.index
			end
		elseif fields.btnDelGuest then
			if modTradeLands.formPlayer and modTradeLands.formPlayer[playername] and modTradeLands.formPlayer[playername].selGuest then
				local guests = modTradeLands.getGuests(playerpos)
				local selGuest = modTradeLands.formPlayer[playername].selGuest
				--minetest.chat_send_player(playername, "selGuest="..dump(selGuest).." guests="..dump(guests))
				if type(selGuest)=="number" and selGuest>=1 and selGuest<=#guests then
					modTradeLands.delGuest(playerpos, selGuest)
					minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormSpecGuests(playerpos, playername))
				end
			end
		elseif fields.btnConfigForm then
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormSpecConfig(playerpos, playername))
		elseif type(fields.chkIfDamage)=="string" then
			modTradeLands.setIfDamageInteract(playerpos, (fields.chkIfDamage=="true"))
		elseif type(fields.selPvpType)=="string" then
			modTradeLands.setPvpType(playerpos, fields.selPvpType)
		elseif fields.btnGiveUpForm then
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormGiveUpLand(playerpos, playername))
		elseif fields.btnGiveUpYes then
			modTradeLands.doGiveUpLand(playerpos)
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormMain(playerpos, playername))
		elseif fields.btnGiveUpNot then
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormMain(playerpos, playername))
		elseif type(fields.chkPermanentValidate)=="string" then
			modTradeLands.setPermanentValidate(playerpos, (fields.chkPermanentValidate=="true"))
			minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormMain(playerpos, playername))
		end
	end
end)

	
modTradeLands.giveChange = function(playername) --Recuperar o troco da caixa de pagamento
	if type(modTradeLands.formPlayer)~="nil" 
		and type(modTradeLands.formPlayer[playername])~="nil" 
		and type(modTradeLands.formPlayer[playername].invLandPay)~="nil" 
	then
		local inv = modTradeLands.formPlayer[playername].invLandPay
		local listPay = inv:get_list("listPay")
		if listPay then
			local player = minetest.env:get_player_by_name(playername)
			if player and player:is_player() then
				for _,item in ipairs(listPay) do
					player:get_inventory():add_item("main",item)
					inv:remove_item("listPay",item)
				end
			end
		end
	end
end

modTradeLands.doPay = function(playername) --Faz o pagamento do terreno
	if type(modTradeLands.formPlayer)~="nil" 
		and type(modTradeLands.formPlayer[playername])~="nil" 
		and type(modTradeLands.formPlayer[playername].invLandPay)~="nil" 
		and type(modTradeLands.formPlayer[playername].selPos)~="nil" 
	then
		local selPos = modTradeLands.formPlayer[playername].selPos
		local minv = modTradeLands.formPlayer[playername].invLandPay
		local restDays = modTradeLands.getDaysRest(selPos)
		if restDays <= modTradeLands.protected_days then --Verifica se o jogador ja tem pago adiantado
			local ifFaltaItem = false
			local listPrice = minv:get_list("listPrice")
			for i, item in pairs(listPrice) do
				if not minv:contains_item("listPay",item) then
					ifFaltaItem = true
					break
				end
			end
			if not ifFaltaItem then
				for i, item in pairs(listPrice) do
					minv:remove_item("listPay",item)
				end
				modTradeLands.setOwnerName(selPos, playername)
				modTradeLands.setIfDamageInteract(selPos, true)
				modTradeLands.setPvpType(selPos, modTradeLands.default_pvp)
				modTradeLands.setValidate(selPos, modTradeLands.getNewValidate(selPos))
				modTradeLands.doShowLand(playername)
				modTradeLands.doSave()
		
				--minetest.chat_send_player(playername, "[TRADELANDS] Parabens! Voce se tornou proprietario deste territorio!")
				minetest.chat_send_all("[TRADELANDS] "..playername.." protegeu o terreno ("..modTradeLands.getLandName(selPos)..")!")
				modTradeLands.doSoundProtector()
			else
				minetest.chat_send_player(playername, "[TRADELANDS:AVISO] Verifique se voce ofereceu corretamente a taxa de alvará!")
			end
		else
			minetest.chat_send_player(playername, "[TRADELANDS:AVISO] Você so pode pagar a taxa de alvará adiantada uma única vez!")
		end
		modTradeLands.giveChange(playername)
	end
end

minetest.register_craftitem("tradelands:charter", {
	description = "Alvará de Proteção de Terreno (16x16)",
	inventory_image = "icon_charter.png",
	on_use = function(itemstack, user, pointed_thing)
		local playername = user:get_player_name()
		local selPos = user:getpos()
		if selPos.y >= modTradeLands.getMaxDepth() then
			local now = os.time()
			local ownername = modTradeLands.getOwnerName(selPos)
			local restDays = modTradeLands.getDaysRest(selPos)
			if ownername=="" or playername==ownername or restDays==0 or minetest.get_player_privs(playername).mayor then
				if type(modTradeLands.formPlayer)=="nil" then modTradeLands.formPlayer = {} end
				if type(modTradeLands.formPlayer[playername])=="nil" then modTradeLands.formPlayer[playername] = {} end
				modTradeLands.formPlayer[playername].invLandPay = modTradeLands.getDetachedInventory()
				modTradeLands.formPlayer[playername].selPos = selPos --ATENCAO: O terreno protegido eh onde o jogador esta, e nao onde o jogar apontar.
				minetest.show_formspec(playername, "frmTradelands", modTradeLands.getFormMain(selPos, playername))
			else
				minetest.chat_send_player(playername, "[TRADELANDS] Este terreno pertence a '"..ownername.."' por mais "..math.ceil(restDays).." dias!")
				
			end
		else
			minetest.chat_send_player(playername, "[TRADELANDS] Você não pode usar o alvará com muita profundidade!")
		end
	end,
})

minetest.register_craft({
	output = 'tradelands:charter',
	recipe = {
		{"default:paper"	,"default:paper"	,"default:mese_crystal_fragment"},
		{"default:paper"	,"default:paper"	,"default:mese_crystal_fragment"},
		{"dye:red"			,"default:paper"	,"default:mese"},
	}
})

minetest.register_alias("charter", "tradelands:charter")
minetest.register_alias("alvara", "tradelands:charter")
minetest.register_alias("alvará", "tradelands:charter")
minetest.register_alias("alvarah", "tradelands:charter")
minetest.register_alias("escritura", "tradelands:charter")

if not JokerInfo then
  _G.JokerInfo = {}
  
  JokerInfo.messages = {}
  local file = io.open(ModPath .. "messages.json", "r")
  if file then
    JokerInfo.messages = json.decode(file:read("*all")) or JokerInfo.messages
    file:close()
  end
  
  function JokerInfo:generic_attacker_info()
    return { nickname = function () return "an unknown force" end }
  end
  
  Hooks:Add("NetworkReceivedData", "NetworkReceivedDataJokerInfo", function(sender, id, data)
    local peer = LuaNetworking:GetPeers()[sender]
    if id == "joker_info" then
      managers.chat:_receive_message(1, "Joker Info", tostring(data), tweak_data.system_chat_color)
    end
  end)
  
end

if RequiredScript == "lib/units/enemies/cop/copdamage" then

  local die_original = CopDamage.die
  function CopDamage:die(attack_data, ...)
    local result = die_original(self, attack_data, ...)
    
    if Network:is_server() then
      local attacker_info = HopLib.unit_info_manager:get_user_info(attack_data.attacker_unit)
      if managers.groupai:state():is_enemy_converted_to_criminal(self._unit) then
        local info = HopLib.unit_info_manager:get_info(self._unit)
        local text = ""
        for i, v in ipairs(JokerInfo.messages.death) do
          if info._kills <= v.threshold or i == #JokerInfo.messages.death then
            text = table.random(v.texts):gsub("<N>", info:nickname()):gsub("<K>", tostring(info._kills)):gsub("<A>", attacker_info and attacker_info:nickname() or "an unknown force")
            break
          end
        end
        managers.chat:_receive_message(1, "Joker Info", text, tweak_data.system_chat_color)
        LuaNetworking:SendToPeers("joker_info", text)
      end
    end
    
    return result
  end
  
end

if RequiredScript == "lib/states/missionendstate" then

  local at_enter_original = MissionEndState.at_enter
  function MissionEndState:at_enter(...)
    DelayedCalls:Add("Joker Info", 1, function()
      local text = ""
      for _, info in pairs(HopLib.unit_info_manager:all_infos()) do
        if info._sub_type == "joker" then
          for i, v in ipairs(JokerInfo.messages.survive) do
            if info._kills <= v.threshold or i == #JokerInfo.messages.survive then
              text = text .. table.random(v.texts):gsub("<N>", info:nickname()):gsub("<K>", tostring(info._kills)) .. " "
              break
            end
          end
        end
      end
      if text ~= "" then
        managers.chat:_receive_message(1, "Joker Info", text, tweak_data.system_chat_color)
        LuaNetworking:SendToPeers("joker_info", text)
      end
    end)
    return at_enter_original(self, ...)
  end

end
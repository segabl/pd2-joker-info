if not HopLib then
  return
end

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
  
  Hooks:Add("HopLibOnUnitDied", "HopLibOnUnitDiedJokerInfo", function (unit, damage_info)
    local info = HopLib.unit_info_manager:get_info(unit)
    if info and info._sub_type == "joker" then
      local attacker_info = HopLib.unit_info_manager:get_user_info(damage_info.attacker_unit)
      local text = ""
      for i, v in ipairs(JokerInfo.messages.death) do
        if info._kills <= v.threshold or i == #JokerInfo.messages.death then
          text = table.random(v.texts):gsub("<N>", info:nickname()):gsub("<K>", tostring(info._kills)):gsub("<A>", attacker_info and attacker_info:nickname() or "an unknown force")
          break
        end
      end
      managers.chat:_receive_message(1, "Joker Info", text, tweak_data.system_chat_color)
    end
  end)
  
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
              text = text .. table.random(v.texts):gsub("<N>", info:nickname()):gsub("<K>", tostring(info._kills)) .. "\n"
              break
            end
          end
        end
      end
      if text ~= "" then
        managers.chat:_receive_message(1, "Joker Info", text, tweak_data.system_chat_color)
      end
    end)
    return at_enter_original(self, ...)
  end

end
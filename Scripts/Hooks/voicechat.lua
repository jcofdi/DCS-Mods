local base = _G

local voice_chat = require('mul_voicechat')

function onPlayerChangeSlot(id)
	voice_chat.onPlayerChangeSlot(id)
end

local voiceChatCallbacks = {}
voiceChatCallbacks.onPlayerChangeSlot = onPlayerChangeSlot
DCS.setUserCallbacks(voiceChatCallbacks)
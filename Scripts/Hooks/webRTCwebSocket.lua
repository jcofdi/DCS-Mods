local base = _G

local print = base.print

local WebSocket = require('WebSocket')
local net = require('net')
local U = require("me_utilities")

local peers = {}
local peer_count = 0

local function addPeer(conn)

	local peer_data = {}
	
	peer_count = peer_count + 1
	peer_data.peer_id = peer_count
	peer_data.conn = conn
	peers[conn.id] = peer_data

	return peer_count
end

local function on_receive(conn, data)

	local first_ch = string.sub(data, 1, 1)
	
	base.print("try define raw message ", first_ch)

	if (first_ch == '{') then

		local lua_obj = net.json2lua(data)	
		
		U.traverseTable(lua_obj)
		base.print("-- lua obj --: ", lua_obj)
		
		if lua_obj["type"] == "get-id" then
			lua_obj["peer_id"] = addPeer(conn)
			return net.lua2json(lua_obj)
		else
			for conn_id, peer_data in pairs(peers) do
				if (conn_id ~= conn.id) then
					--base.print("try send message from peer_id to peer_id", peers[conn.id].peer_id, peer_data.peer_id)
					--lua_obj["peer_id"] = peers[conn.id].peer_id
					if (lua_obj["signaling"]) then
						base.print("try send signaling message from peer_id to peer_id", peers[conn.id].peer_id, peer_data.peer_id)
						conn.send(peer_data.conn, net.lua2json(lua_obj))
					else
						base.print("try send raw message from peer_id to peer_id", peers[conn.id].peer_id, peer_data.peer_id)
						conn.send(peer_data.conn, data)
					end
				end
			end
			--lua_obj["type"] = ""
			return {}
		end
	else
		base.print("data is not json format")
		for conn_id, peer_data in pairs(peers) do
			if (conn_id ~= conn.id) then
				--base.print("try send raw message from peer_id to peer_id", peers[conn.id].peer_id, peer_data.peer_id)
				conn.send(peer_data.conn, data)
			end
		end

		return {}
	end
	
    return net.lua2json(lua_obj)
end

local function connect_handler(conn)
    
	--local ok_address = net.is_loopback_address(conn.addr) or net.is_private_address(conn.addr)
    
	--if not ok_address then 
		--base.print('zzz connection has not ok address '..conn.addr..':'..tostring(conn.port))
		--return 
	--end
    
	base.print('test web_rtc connection from '..conn.addr..':'..tostring(conn.port))
		   
	conn.onReceive = on_receive
    
	return conn
end

WebSocket.addHandler('/webrtc_connect', connect_handler)

base.print("WebRTC websocket handler added")

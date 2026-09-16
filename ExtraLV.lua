-- ============================================================
-- Extra LV | by HISSOKASHOP | v.11.9
-- + Скинченджер: ручной ввод ID 0-17099 + сетка превью
-- + "Другое" (ANTIAFK) и "Скинченджер" — кнопки в Софтах
-- + Полная выгрузка на панику
-- + ФИКС: убрана sampGetPlayerIdByNickname (нет в CRMP)
-- ============================================================
local ffi = require 'ffi'
local bit = require 'bit'

local config = {}
config.naming = 'Extra LV by HISSOKASHOP'
config.screen = {}
config.screen.x, config.screen.y = getScreenResolution()

config.json = {
	showobj = false, showpic = false, show3d = false, showdialog = false,
	camhack = { speed = 1.0, hide_hud = true },
	objwh = { enabled = false, sizetr = 1, models = {}, show_price = true },
	lovlya = {
		house_wh = false, house_lov = false,
		biz = false, garage = false, garden = false,
		flood_biz = false, flood_alt = false, delay_biz = 500
	},
	customflood = {
		mode = "single", text = "/me привет", interval = 1000, enabled = false,
		quick = { "/buybiz", "/buygarage", "/buygarden" },
		block = { messages = { "/buybiz", "/buygarage" }, msg_delay = 500, block_interval = 180 }
	},
	auth = { login = "", password = "", enabled = false },
	telegram = {
		enabled = false, token = "", chat_id = "",
		notify_enter = true, notify_admin = true, notify_drop = true, notify_purchase = true
	},
	ui_style = "dark",
	overlay = {
		enabled = true, corner = 1, offset_x = 0, offset_y = 0,
		show = {
			objwh = true, house_wh = true, house_lov = true,
			flood = true, telegram = true, camhack = true, stats = false,
		},
		time_enabled = true, time_corner = 5,
		time_offset_x = 0, time_offset_y = -20,
		time_24h = true, time_show_date = false,
	},
	window = { x = -1, y = -1 },
	chs = { list = {}, filter_football = false },
	panic = { vk = 0, show_chat_cmd = true, unload = true },
	antish = { enabled = false },
	softs = { visual_skin = { enabled = false, skinId = 0 } },
	stats = {
		pickups_total = 0, houses_total = 0, biz_total = 0,
		garage_total = 0, garden_total = 0,
		seconds_total = 0, last_session_ts = 0
	}
}

local vkeys = require 'vkeys'
local events = require 'samp.events'
local font_flag = require('moonloader').font_flag
local sampapi = require 'sampapi'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local effil = require 'effil'
local requests = require 'requests'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local IS_UTF8 = (#"Ё" > 1)
local function t(s)
	if type(s) ~= "string" then return s end
	if IS_UTF8 then return s end
	return u8:decode(s)
end
local function srv(s)
	if type(s) ~= "string" then return s end
	return u8:decode(s)
end

local VK_NAMES = {
	[0x08]="Backspace",[0x09]="Tab",[0x0D]="Enter",[0x10]="Shift",[0x11]="Ctrl",[0x12]="Alt",
	[0x13]="Pause",[0x14]="CapsLock",[0x1B]="Esc",[0x20]="Space",
	[0x21]="PageUp",[0x22]="PageDown",[0x23]="End",[0x24]="Home",
	[0x25]="Left",[0x26]="Up",[0x27]="Right",[0x28]="Down",
	[0x2D]="Insert",[0x2E]="Delete",
	[0x30]="0",[0x31]="1",[0x32]="2",[0x33]="3",[0x34]="4",
	[0x35]="5",[0x36]="6",[0x37]="7",[0x38]="8",[0x39]="9",
	[0x41]="A",[0x42]="B",[0x43]="C",[0x44]="D",[0x45]="E",[0x46]="F",[0x47]="G",[0x48]="H",[0x49]="I",
	[0x4A]="J",[0x4B]="K",[0x4C]="L",[0x4D]="M",[0x4E]="N",[0x4F]="O",[0x50]="P",[0x51]="Q",[0x52]="R",
	[0x53]="S",[0x54]="T",[0x55]="U",[0x56]="V",[0x57]="W",[0x58]="X",[0x59]="Y",[0x5A]="Z",
	[0x60]="Num0",[0x61]="Num1",[0x62]="Num2",[0x63]="Num3",[0x64]="Num4",
	[0x65]="Num5",[0x66]="Num6",[0x67]="Num7",[0x68]="Num8",[0x69]="Num9",
	[0x6A]="Num*",[0x6B]="Num+",[0x6D]="Num-",[0x6E]="Num.",[0x6F]="Num/",
	[0x70]="F1",[0x71]="F2",[0x72]="F3",[0x73]="F4",[0x74]="F5",[0x75]="F6",
	[0x76]="F7",[0x77]="F8",[0x78]="F9",[0x79]="F10",[0x7A]="F11",[0x7B]="F12",
	[0xBA]=";",[0xBB]="=",[0xBC]=",",[0xBD]="-",[0xBE]=".",[0xBF]="/",
	[0xC0]="`",[0xDB]="[",[0xDC]="\\",[0xDD]="]",[0xDE]="'",
}
local function vkName(vk)
	if not vk or vk == 0 then return "не задана" end
	return VK_NAMES[vk] or ("VK_" .. vk)
end

local panic_waiting = false
local antish = { enabled = false }
local visual_skin_original = 0
local visual_skin_last_check = 0

local function set_player_skin(id, skin)
	local BS = raknetNewBitStream()
	raknetBitStreamWriteInt32(BS, id)
	raknetBitStreamWriteInt32(BS, skin)
	raknetEmulRpcReceiveBitStream(153, BS)
	raknetDeleteBitStream(BS)
end

local new = imgui.new
local MainWindow = new.bool(false)
local showAuthWindow = new.bool(false)
local showOtherWindow = new.bool(false)
local showSkinChanger = new.bool(false)

local newblk_buf = new.char[128]("")
local newmsg_buf = new.char[128]("")
local newchs_buf = new.char[64]("")
local skin_buf = new.char[16]("")

local MAX_SKIN_ID     = 17099
local skin_textures   = {}
local available_skins = {}
local skins_scanned   = false
local skin_search_buf = new.char[16]("")
local skins_dir = getWorkingDirectory() .. "\\config\\Extra LV\\skins\\"

local function getSkinTexture(id)
	local cached = skin_textures[id]
	if cached ~= nil then return cached end
	local path = skins_dir .. id .. '.png'
	if doesFileExist(path) then
		local ok, tex = pcall(imgui.CreateTextureFromFile, path)
		if ok and tex then
			skin_textures[id] = tex
			return tex
		end
	end
	skin_textures[id] = false
	return false
end

local function scanSkinsFolder()
	lua_thread.create(function()
		available_skins = {}
		local id = 0
		while id <= MAX_SKIN_ID do
			if doesFileExist(skins_dir .. id .. '.png') then
				table.insert(available_skins, id)
			end
			id = id + 1
			if id % 400 == 0 then wait(0) end
		end
		skins_scanned = true
	end)
end

local house_purchase_failed = false
local lov_busy = false
local drag_data = { active = false, offsetX = 0, offsetY = 0 }

local DIALOG_STYLES = {
	[0] = "MSG", [1] = "INPUT", [2] = "LIST",
	[3] = "PASSWORD", [4] = "TABLIST", [5] = "TABLIST_HEADERS"
}
local dialog_info = { id = -1, style = -1, title = "", button1 = "", button2 = "", shown_at = 0 }
local dialog_history = {}
local DIALOG_HISTORY_MAX = 20

-- CEF monitor для Radmir CRMP.
-- В Radmir CRMP CEF-команды приходят через RakNet packet 215/220.
-- В пакетах встречаются вызовы вида interface('Name').method(...)
-- и window.executeEvent('cef.modals.showModal', '["Name", ...]').
local cef_info = { id = "", title = "", raw = "", source = "", shown_at = 0 }
local cef_history = {}
local CEF_HISTORY_MAX = 30

local function cefShort(s, n)
	s = tostring(s or ""):gsub("%s+", " ")
	n = n or 180
	if #s > n then return s:sub(1, n) .. "..." end
	return s
end

local function logCefInterface(interfaceId, raw, source)
	interfaceId = tostring(interfaceId or "")
	if interfaceId == "" then return end
	raw = tostring(raw or "")
	source = tostring(source or "CEF")
	cef_info.id = interfaceId
	cef_info.raw = cefShort(raw, 220)
	cef_info.source = source
	cef_info.shown_at = os.clock()

	table.insert(cef_history, 1, {
		id = interfaceId,
		raw = cefShort(raw, 180),
		source = source,
		time = os.date("%H:%M:%S")
	})
	while #cef_history > CEF_HISTORY_MAX do table.remove(cef_history) end

	if not json.showdialog then return end
	local msg = string.format("CEF Interface: %s | %s | %s", interfaceId, source, cefShort(raw, 120))
	showPopup("CEF: " .. interfaceId, "i", imgui.ImVec4(0.55, 0.85, 1.00, 1.0))
	pcall(sampAddChatMessage, t("{C8A2FF}[Extra LV] {FFFFFF}" .. msg), -1)
end


-- ============================================================
-- КИОСК RADMIR CRMP
-- Входной pickup: MODEL 19134 (это модель, а не m_nId).
--
-- Важный момент Radmir CEF:
--   interface('Interaction')
--   interface('Business')
-- могут приходить в одном/разных packet 215, а данные Business
-- нередко идут следующими packet 215 уже БЕЗ interface('Business').
-- Поэтому после открытия Business собираем последующие CEF-строки
-- в общий буфер и разбираем весь накопленный JS/JSON.
-- ============================================================
local pickup_pool
local KIOSK_PICKUP_MODEL = 19134
local KIOSK_LOG_PATH = getWorkingDirectory() .. "\\config\\ExtraLV_kiosk_business.log"
local KIOSK_SESSION_TIMEOUT = 12.0
local KIOSK_BUFFER_MAX = 700000

local kiosk_monitor = {
	enabled = true,
	near = false,
	last_raw = "",
	last_time = 0,
	business_active = false,
	business_until = 0,
	business_buffer = "",
	items = {},
	signature = "",
	raw_count = 0
}

local function kioskIsNearPickup(maxDist)
	if not pickup_pool then return false end
	maxDist = maxDist or 25.0
	local ok, result = pcall(function()
		local x, y, z = getCharCoordinates(PLAYER_PED)
		local count = pickup_pool.m_nCount
		local i = ffi.C.MAX_PICKUPS - 1
		while count > 0 and i >= 0 do
			if pickup_pool.m_nId[i] ~= -1 then
				local obj = pickup_pool.m_object[i]
				if obj and tonumber(obj.m_nModel) == KIOSK_PICKUP_MODEL and obj.m_position then
					local d = getDistanceBetweenCoords3d(x, y, z,
						obj.m_position.x, obj.m_position.y, obj.m_position.z)
					if d <= maxDist then return true end
				end
				count = count - 1
			end
			i = i - 1
		end
		return false
	end)
	return ok and result or false
end

local function kioskCleanString(v)
	if v == nil then return nil end
	v = tostring(v)
	v = v:gsub('\\"', '"'):gsub('\\\\', '\\')
	v = v:gsub('<.->', '')
	v = v:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
	if v == '' then return nil end
	return v
end

local function kioskFirst(tbl, keys)
	if type(tbl) ~= 'table' then return nil end
	for _, key in ipairs(keys) do
		local v = tbl[key]
		if v ~= nil and (type(v) == 'string' or type(v) == 'number') then
			return v
		end
	end
	return nil
end

local function kioskLooksLikeItem(tbl)
	if type(tbl) ~= 'table' then return false end
	local name = kioskFirst(tbl, {
		'name','title','label','itemName','item_name','productName','product_name',
		'displayName','display_name','item','item_name_ru','caption','text'
	})
	local price = kioskFirst(tbl, {
		'price','cost','sum','sellPrice','buyPrice','sell_price','buy_price',
		'value','amount','priceSell','priceBuy'
	})
	local model = kioskFirst(tbl, {
		'model','modelId','model_id','itemId','item_id','objectId','object_id','id'
	})
	return name ~= nil and (price ~= nil or model ~= nil)
end

local function kioskAddItem(items, seen, tbl)
	if not kioskLooksLikeItem(tbl) then return end

	local name = kioskCleanString(kioskFirst(tbl, {
		'name','title','label','itemName','item_name','productName','product_name',
		'displayName','display_name','item','item_name_ru','caption','text'
	}))
	local price = kioskFirst(tbl, {
		'price','cost','sum','sellPrice','buyPrice','sell_price','buy_price',
		'value','amount','priceSell','priceBuy'
	})
	local model = kioskFirst(tbl, {
		'model','modelId','model_id','itemId','item_id','objectId','object_id','id'
	})
	local count = kioskFirst(tbl, {
		'count','qty','quantity','stock','amount','quantityAvailable',
		'quantity_available','available','cnt'
	})

	if not name then return end
	local key = table.concat({tostring(name), tostring(model or ''), tostring(price or ''), tostring(count or '')}, '|')
	if seen[key] then return end
	seen[key] = true
	table.insert(items, {name=name, model=model, price=price, count=count})
end

local function kioskWalkTable(tbl, items, seen, depth)
	if type(tbl) ~= 'table' or depth > 12 then return end
	kioskAddItem(items, seen, tbl)
	for _, v in pairs(tbl) do
		if type(v) == 'table' then kioskWalkTable(v, items, seen, depth + 1) end
	end
end

local function kioskTryDecode(candidate, items, seen)
	if type(candidate) ~= 'string' or candidate == '' then return end
	candidate = candidate:gsub('\\/', '/'):gsub('\\"', '"'):gsub('\\\\', '\\')
	local data
	local ok = pcall(function() data = decodeJson(candidate) end)
	if ok and type(data) == 'table' then kioskWalkTable(data, items, seen, 0) end
end

-- Извлекает сбалансированные JSON [] / {} из JS-команды.
-- Обычный gmatch по последней ]/} ломается на вложенных массивах.
local function kioskExtractJsonParts(text)
	local out = {}
	local n = #text
	local i = 1
	while i <= n do
		local c = text:sub(i, i)
		if c == '[' or c == '{' then
			local stack = {c}
			local quote = nil
			local escaped = false
			local j = i + 1
			while j <= n and #stack > 0 do
				local ch = text:sub(j, j)
				if quote then
					if escaped then escaped = false
					elseif ch == '\\' then escaped = true
					elseif ch == quote then quote = nil end
				else
					if ch == '"' or ch == "'" then
						quote = ch
					elseif ch == '[' or ch == '{' then
						table.insert(stack, ch)
					elseif ch == ']' or ch == '}' then
						local top = stack[#stack]
						if (ch == ']' and top == '[') or (ch == '}' and top == '{') then
							table.remove(stack)
						else
							stack = {}
						end
					end
				end
				j = j + 1
			end
			if #stack == 0 then
				table.insert(out, text:sub(i, j - 1))
				i = j
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end
	return out
end

local function kioskParseBusinessText(text)
	local items, seen = {}, {}
	if type(text) ~= 'string' or text == '' then return items end

	kioskTryDecode(text, items, seen)
	for _, candidate in ipairs(kioskExtractJsonParts(text)) do
		kioskTryDecode(candidate, items, seen)
	end

	-- Резерв: вытаскиваем name/title + ближайшие числовые поля.
	local patterns = {
		'name','title','label','itemName','item_name','productName','product_name','displayName','display_name'
	}
	for _, key in ipairs(patterns) do
		local pat = '["' .. key .. '"]%s*:%s*["\']([^"\']+)["\']'
		for name in text:gmatch(pat) do
			local pos = text:find(name, 1, true)
			if pos then
				local around = text:sub(math.max(1, pos - 250), math.min(#text, pos + 900))
				local price = around:match('["\']price["\']%s*:%s*([%d%.%-]+)')
					or around:match('["\']cost["\']%s*:%s*([%d%.%-]+)')
				local model = around:match('["\']model["\']%s*:%s*([%d%-]+)')
					or around:match('["\']modelId["\']%s*:%s*([%d%-]+)')
					or around:match('["\']itemId["\']%s*:%s*([%d%-]+)')
				local count = around:match('["\']count["\']%s*:%s*([%d%-]+)')
					or around:match('["\']quantity["\']%s*:%s*([%d%-]+)')
				local clean = kioskCleanString(name)
				if clean then
					local k = table.concat({clean,tostring(model or ''),tostring(price or ''),tostring(count or '')}, '|')
					if not seen[k] then
						seen[k] = true
						table.insert(items,{name=clean,model=model,price=price,count=count})
					end
				end
			end
		end
	end
	return items
end

local function kioskFormatItem(item)
	local parts = { tostring(item.name or '???') }
	if item.model ~= nil then table.insert(parts, 'ID:' .. tostring(item.model)) end
	if item.price ~= nil then table.insert(parts, 'Цена:' .. tostring(item.price)) end
	if item.count ~= nil then table.insert(parts, 'Кол-во:' .. tostring(item.count)) end
	return table.concat(parts, ' | ')
end

local function kioskStoreItems(items, raw)
	if #items == 0 then return end
	local sigParts = {}
	for _, item in ipairs(items) do table.insert(sigParts, kioskFormatItem(item)) end
	table.sort(sigParts)
	local signature = table.concat(sigParts, ' || ')
	kiosk_monitor.items = items
	kiosk_monitor.last_raw = tostring(raw or '')
	kiosk_monitor.last_time = os.clock()
	if signature == kiosk_monitor.signature then return end
	kiosk_monitor.signature = signature
	pcall(sampAddChatMessage, t(string.format(
		'{C8A2FF}[Extra LV] {FFFFFF}Киоск [model %d] | найдено предметов: %d',
		KIOSK_PICKUP_MODEL, #items)), -1)
	for _, item in ipairs(items) do
		pcall(sampAddChatMessage, t('{B8FFB8}[KIOSK] {FFFFFF}' .. kioskFormatItem(item)), -1)
	end
end

local function kioskDumpRaw(text, source)
	if not kiosk_monitor.enabled or type(text) ~= 'string' or text == '' then return end
	if not kiosk_monitor.business_active then return end
	local f = io.open(KIOSK_LOG_PATH, 'a')
	if not f then return end
	local raw = text
	if #raw > 250000 then raw = raw:sub(1, 250000) .. '\n[TRUNCATED]' end
	f:write(os.date('[%Y-%m-%d %H:%M:%S] '), '[', tostring(source or '215'), ']\n')
	f:write(raw, '\n', string.rep('-', 100), '\n')
	f:close()
	kiosk_monitor.raw_count = kiosk_monitor.raw_count + 1
end

local function kioskResetSession(clearFile)
	kiosk_monitor.business_active = false
	kiosk_monitor.business_until = 0
	kiosk_monitor.business_buffer = ''
	kiosk_monitor.items = {}
	kiosk_monitor.signature = ''
	kiosk_monitor.last_raw = ''
	kiosk_monitor.last_time = 0
	kiosk_monitor.raw_count = 0
	if clearFile then
		local f = io.open(KIOSK_LOG_PATH, 'w')
		if f then f:write('Extra LV | KIOSK Business raw log\n') f:close() end
	end
end

local function kioskFeedCefText(text, interfaceId, source)
	if not kiosk_monitor.enabled or type(text) ~= 'string' or text == '' then return end

	local now = os.clock()
	kiosk_monitor.near = kioskIsNearPickup(25.0)

	if interfaceId == 'Interaction' then
		-- Interaction перед Business — не считаем это концом будущей Business-сессии.
		-- Просто не парсим его как товары.
		return
	end

	if interfaceId == 'Business' then
		kiosk_monitor.business_active = true
		kiosk_monitor.business_until = now + KIOSK_SESSION_TIMEOUT
		kiosk_monitor.business_buffer = ''
		kiosk_monitor.items = {}
		kiosk_monitor.signature = ''
		kiosk_monitor.raw_count = 0
		local f = io.open(KIOSK_LOG_PATH, 'w')
		if f then
			f:write('Extra LV | KIOSK Business session ', os.date('%Y-%m-%d %H:%M:%S'), '\n', string.rep('=', 100), '\n')
			f:close()
		end
	elseif not kiosk_monitor.business_active then
		return
	elseif now > kiosk_monitor.business_until then
		kioskResetSession(false)
		return
	else
		kiosk_monitor.business_until = now + KIOSK_SESSION_TIMEOUT
	end

	kioskDumpRaw(text, source or '215')
	kiosk_monitor.last_raw = text
	kiosk_monitor.last_time = now

	if #kiosk_monitor.business_buffer < KIOSK_BUFFER_MAX then
		local add = text
		local room = KIOSK_BUFFER_MAX - #kiosk_monitor.business_buffer
		if #add > room then add = add:sub(1, room) end
		kiosk_monitor.business_buffer = kiosk_monitor.business_buffer .. '\n' .. add
	end

	-- Разбираем не только текущую строку, а весь накопленный Business buffer.
	local items = kioskParseBusinessText(kiosk_monitor.business_buffer)
	if #items > 0 then kioskStoreItems(items, kiosk_monitor.business_buffer) end
end

local function scanCefText(text, source)
	if type(text) ~= 'string' or text == '' then return end
	local found, interfaceIds = {}, {}

	for id in text:gmatch("interface%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
		if not found[id] then
			found[id] = true
			table.insert(interfaceIds, id)
			logCefInterface(id, text, source)
		end
	end

	-- Сначала Business: если в этом же packet есть Interaction -> Business,
	-- Business должен открыть новую сессию.
	for _, id in ipairs(interfaceIds) do
		if id == 'Business' then
			kioskFeedCefText(text, 'Business', source)
			return
		end
	end

	-- Остальные строки того же packet и последующие packet 215 идут в буфер.
	if kiosk_monitor.business_active then
		kioskFeedCefText(text, nil, source)
	end

	if text:find('cef%.modals%.showModal', 1, false) then
		local id = text:match("showModal.-['\"]([^'\"]+)['\"]")
		if id and not found[id] then
			found[id] = true
			logCefInterface(id, text, tostring(source) .. '/showModal')
		end
		if id == 'Business' then
			kioskFeedCefText(text, 'Business', tostring(source) .. '/showModal')
		end
	end
end

local function readCefPacket215(bs)
	local ok = pcall(function()
		raknetBitStreamIgnoreBits(bs, 8)
		local bt = raknetBitStreamReadInt16(bs)
		if bt ~= 2 then return end
		raknetBitStreamReadInt32(bs)
		local count = raknetBitStreamReadInt8(bs)
		if not count or count < 0 or count > 128 then return end
		for i = 1, count do
			local len = raknetBitStreamReadInt32(bs)
			if not len or len < 0 or len > 200000 then return end
			local text = raknetBitStreamReadString(bs, len)
			if text then scanCefText(text, 'Packet 215') end
		end
	end)
	return ok
end

local function readCefPacket220(bs)
	pcall(function()
		local opcode = raknetBitStreamReadInt8(bs)
		if opcode ~= 17 then return end
		raknetBitStreamReadInt32(bs)
		local len = raknetBitStreamReadInt16(bs)
		local encoded = raknetBitStreamReadInt8(bs)
		if not len or len < 0 or len > 200000 then return end
		local text
		if encoded ~= 0 and raknetBitStreamDecodeString then
			text = raknetBitStreamDecodeString(bs, len)
		else
			text = raknetBitStreamReadString(bs, len)
		end
		if text then scanCefText(text, 'Packet 220') end
	end)
end

local function logDialogId(dialogId, style, title, button1, button2)
	local ttl = tostring(title or ""):gsub("{.-}", "")
	if #ttl > 64 then ttl = ttl:sub(1, 64) .. "..." end
	dialog_info.id = dialogId or -1
	dialog_info.style = style or -1
	dialog_info.title = ttl
	dialog_info.button1 = tostring(button1 or "")
	dialog_info.button2 = tostring(button2 or "")
	dialog_info.shown_at = os.clock()
	table.insert(dialog_history, 1, {
		id = dialog_info.id,
		style = dialog_info.style,
		title = ttl,
		time = os.date("%H:%M:%S")
	})
	while #dialog_history > DIALOG_HISTORY_MAX do
		table.remove(dialog_history)
	end
	if not json.showdialog then return end
	local stName = DIALOG_STYLES[style] or tostring(style)
	local msg = string.format("Dialog ID: %s | Style: %s (%s) | Title: %s",
		tostring(dialogId), tostring(style), stName, ttl)
	showPopup("Dialog ID: " .. tostring(dialogId), "i", imgui.ImVec4(0.55, 0.85, 1.00, 1.0))
	pcall(sampAddChatMessage, t("{C8A2FF}[Extra LV] {FFFFFF}" .. msg), -1)
end

local bg_alpha = 0
local function clamp(val, min, max)
	if val < min then return min elseif val > max then return max else return val end
end
local function rgba(r, g, b, a)
	a = a or 1.0
	return math.floor(a * 255) * 0x1000000 + math.floor(r * 255) * 0x10000 +
	       math.floor(g * 255) * 0x100 + math.floor(b * 255)
end

local show = new.bool(false)
local popupStart = 0.0
local popupText = "Сообщение"
local popupIcon = "i"
local popupAccent = nil
local popupWidth, popupHeight = 400, 68

function showPopup(text, icon, accent)
	popupText = text or "Сообщение"
	popupIcon = icon or "i"
	popupAccent = accent or imgui.ImVec4(0.55, 0.35, 0.95, 1.0)
	popupStart = os.clock()
	show[0] = true
end

local json_path = 'moonloader\\' .. config.naming .. '.json'
if not doesFileExist(json_path) then
	local f = io.open(json_path, 'w'); if f then f:write('[]'); f:close() end
end
local json = {}
local f = io.open(json_path, 'r')
if f then json = decodeJson(f:read('*a')) or {}; f:close() end

local function checkJson(original, default)
	local changed = false
	for k, v in pairs(default) do
		if type(v) == 'table' then
			if original[k] == nil then original[k] = {}; changed = true end
			if checkJson(original[k], default[k]) then changed = true end
		else
			if original[k] == nil then original[k] = v; changed = true end
		end
	end
	return changed
end
local function saveJson()
	local f2 = io.open(json_path, 'w+')
	if f2 then f2:write(encodeJson(json)); f2:close() end
end
if checkJson(json, config.json) then saveJson() end

local auth_login_buf = new.char[64](json.auth.login or "")
local auth_pass_buf  = new.char[64](json.auth.password or "")
local auth_show_pass = new.bool(false)

local UI_STYLES = {
	dark    = { name = "Тёмный",     bg = imgui.ImVec4(0.08, 0.08, 0.13, 0.98), bg2 = imgui.ImVec4(0.13, 0.13, 0.19, 1.00), border = imgui.ImVec4(0.35, 0.30, 0.55, 0.60), accent = imgui.ImVec4(0.55, 0.35, 0.95, 1.00) },
	glass   = { name = "Стекло",     bg = imgui.ImVec4(0.10, 0.10, 0.18, 0.60), bg2 = imgui.ImVec4(0.14, 0.14, 0.24, 0.45), border = imgui.ImVec4(0.60, 0.55, 0.90, 0.40), accent = imgui.ImVec4(0.60, 0.45, 0.98, 1.00) },
	neon    = { name = "Неон",       bg = imgui.ImVec4(0.03, 0.03, 0.07, 0.99), bg2 = imgui.ImVec4(0.06, 0.06, 0.12, 0.95), border = imgui.ImVec4(0.75, 0.50, 1.00, 1.00), accent = imgui.ImVec4(0.65, 0.40, 1.00, 1.00) },
	minimal = { name = "Минимализм", bg = imgui.ImVec4(0.09, 0.09, 0.11, 0.98), bg2 = imgui.ImVec4(0.13, 0.13, 0.16, 1.00), border = imgui.ImVec4(0.30, 0.30, 0.35, 0.50), accent = imgui.ImVec4(0.70, 0.70, 0.85, 1.00) },
	black   = { name = "Чёрный",     bg = imgui.ImVec4(0.00, 0.00, 0.00, 1.00), bg2 = imgui.ImVec4(0.06, 0.06, 0.06, 1.00), border = imgui.ImVec4(0.20, 0.20, 0.20, 0.80), accent = imgui.ImVec4(0.40, 0.40, 0.40, 1.00) },
	whitegreen = { name = "Бело-зелёный", bg = imgui.ImVec4(0.94, 0.97, 0.94, 0.98), bg2 = imgui.ImVec4(0.87, 0.94, 0.87, 1.00), border = imgui.ImVec4(0.20, 0.65, 0.30, 0.90), accent = imgui.ImVec4(0.15, 0.72, 0.35, 1.00) },
	cyberpunk = { name = "Киберпанк", bg = imgui.ImVec4(0.04, 0.02, 0.10, 0.98), bg2 = imgui.ImVec4(0.08, 0.04, 0.16, 1.00), border = imgui.ImVec4(0.00, 0.95, 1.00, 0.85), accent = imgui.ImVec4(0.95, 0.15, 0.75, 1.00), rounding = 4.0, border_size = 3.0 },
	matrix    = { name = "Матрица",  bg = imgui.ImVec4(0.00, 0.03, 0.00, 0.98), bg2 = imgui.ImVec4(0.02, 0.08, 0.02, 1.00), border = imgui.ImVec4(0.20, 1.00, 0.30, 0.90), accent = imgui.ImVec4(0.15, 0.95, 0.25, 1.00), rounding = 2.0, border_size = 2.5 },
	sunset    = { name = "Закат",    bg = imgui.ImVec4(0.10, 0.05, 0.12, 0.98), bg2 = imgui.ImVec4(0.16, 0.08, 0.16, 1.00), border = imgui.ImVec4(1.00, 0.55, 0.30, 0.85), accent = imgui.ImVec4(1.00, 0.40, 0.45, 1.00), rounding = 16.0, border_size = 2.0 },
	ocean     = { name = "Океан",    bg = imgui.ImVec4(0.02, 0.05, 0.10, 0.98), bg2 = imgui.ImVec4(0.05, 0.10, 0.20, 1.00), border = imgui.ImVec4(0.20, 0.75, 1.00, 0.85), accent = imgui.ImVec4(0.10, 0.65, 0.95, 1.00), rounding = 14.0, border_size = 2.0 },
	gold      = { name = "Золото",   bg = imgui.ImVec4(0.06, 0.05, 0.02, 0.98), bg2 = imgui.ImVec4(0.12, 0.10, 0.04, 1.00), border = imgui.ImVec4(1.00, 0.80, 0.20, 0.90), accent = imgui.ImVec4(1.00, 0.75, 0.15, 1.00), rounding = 20.0, border_size = 2.0 },
	blood     = { name = "Кровь",    bg = imgui.ImVec4(0.06, 0.01, 0.01, 0.98), bg2 = imgui.ImVec4(0.14, 0.02, 0.02, 1.00), border = imgui.ImVec4(0.95, 0.15, 0.15, 0.90), accent = imgui.ImVec4(0.90, 0.10, 0.10, 1.00), rounding = 8.0, border_size = 3.0 },
	purple    = { name = "Пурпур",   bg = imgui.ImVec4(0.08, 0.03, 0.12, 0.98), bg2 = imgui.ImVec4(0.15, 0.06, 0.22, 1.00), border = imgui.ImVec4(0.85, 0.35, 1.00, 0.85), accent = imgui.ImVec4(0.75, 0.25, 1.00, 1.00), rounding = 18.0, border_size = 2.0 },
	ice       = { name = "Лёд",      bg = imgui.ImVec4(0.88, 0.94, 0.98, 0.98), bg2 = imgui.ImVec4(0.80, 0.88, 0.95, 1.00), border = imgui.ImVec4(0.25, 0.55, 0.85, 0.90), accent = imgui.ImVec4(0.20, 0.60, 0.95, 1.00), rounding = 12.0, border_size = 2.0 },
	clean     = { name = "Чистый",   bg = imgui.ImVec4(0.00, 0.00, 0.00, 0.00), bg2 = imgui.ImVec4(0.00, 0.00, 0.00, 0.00), border = imgui.ImVec4(0.00, 0.00, 0.00, 0.00), accent = imgui.ImVec4(0.85, 0.65, 1.00, 1.00), rounding = 0.0, border_size = 0.0, clean = true },
}
for _, v in pairs(UI_STYLES) do v.name = t(v.name) end

local UI_KEYS = {
	"dark", "glass", "neon", "minimal", "black", "whitegreen",
	"cyberpunk", "matrix", "sunset", "ocean", "gold", "blood", "purple", "ice", "clean"
}

function setExtraTheme()
	local style = imgui.GetStyle()
	local c = style.Colors
	local uk = json.ui_style or "dark"
	local t2 = UI_STYLES[uk] or UI_STYLES.dark
	local accent       = t2.accent
	local accentHover  = imgui.ImVec4(math.min(accent.x * 1.25, 1), math.min(accent.y * 1.25, 1), math.min(accent.z * 1.25, 1), 1)
	local accentActive = imgui.ImVec4(accent.x * 0.75, accent.y * 0.75, accent.z * 0.75, 1)
	local bg, bg2, border = t2.bg, t2.bg2, t2.border
	local white        = imgui.ImVec4(0.95, 0.96, 1.00, 1.00)
	local textMuted    = imgui.ImVec4(0.65, 0.65, 0.85, 1.00)
	if uk == "whitegreen" or uk == "ice" then
		white     = imgui.ImVec4(0.10, 0.12, 0.18, 1.00)
		textMuted = imgui.ImVec4(0.35, 0.40, 0.50, 1.00)
	end
	c[imgui.Col.WindowBg]=bg; c[imgui.Col.ChildBg]=bg2; c[imgui.Col.PopupBg]=bg
	c[imgui.Col.Border]=border; c[imgui.Col.BorderShadow]=imgui.ImVec4(0,0,0,0)
	c[imgui.Col.FrameBg]=bg2; c[imgui.Col.FrameBgHovered]=accentHover; c[imgui.Col.FrameBgActive]=accentActive
	c[imgui.Col.TitleBg]=accent; c[imgui.Col.TitleBgActive]=accentActive; c[imgui.Col.TitleBgCollapsed]=accentActive
	c[imgui.Col.MenuBarBg]=bg2; c[imgui.Col.ScrollbarBg]=bg2
	c[imgui.Col.ScrollbarGrab]=accent; c[imgui.Col.ScrollbarGrabHovered]=accentHover; c[imgui.Col.ScrollbarGrabActive]=accentActive
	c[imgui.Col.CheckMark]=accent; c[imgui.Col.SliderGrab]=accent; c[imgui.Col.SliderGrabActive]=accentHover
	c[imgui.Col.Button]=accent; c[imgui.Col.ButtonHovered]=accentHover; c[imgui.Col.ButtonActive]=accentActive
	c[imgui.Col.Header]=accent; c[imgui.Col.HeaderHovered]=accentHover; c[imgui.Col.HeaderActive]=accentActive
	c[imgui.Col.Separator]=border; c[imgui.Col.SeparatorHovered]=accentHover; c[imgui.Col.SeparatorActive]=accentActive
	c[imgui.Col.Text]=white; c[imgui.Col.TextDisabled]=textMuted
	c[imgui.Col.TextSelectedBg]=accent; c[imgui.Col.DragDropTarget]=accent; c[imgui.Col.NavHighlight]=accent
	c[imgui.Col.Tab]=accent; c[imgui.Col.TabHovered]=accentHover; c[imgui.Col.TabActive]=accentActive
	c[imgui.Col.TabUnfocused]=bg2; c[imgui.Col.TabUnfocusedActive]=bg2
	style.WindowRounding=14; style.ChildRounding=10; style.FrameRounding=10
	style.PopupRounding=10; style.ScrollbarRounding=10; style.GrabRounding=10; style.TabRounding=10
	style.WindowBorderSize=(uk=="neon") and 3.0 or 2.0
	style.FrameBorderSize=1.2; style.PopupBorderSize=1.5
	style.WindowPadding=imgui.ImVec2(16,14)
	style.FramePadding=imgui.ImVec2(11,7)
	style.ItemSpacing=imgui.ImVec2(11,9)
	style.ItemInnerSpacing=imgui.ImVec2(8,6)
	if t2.rounding    then style.WindowRounding   = t2.rounding end
	if t2.border_size then style.WindowBorderSize = t2.border_size end
	if t2.clean then
		style.WindowPadding = imgui.ImVec2(10, 8)
		style.ItemSpacing   = imgui.ImVec2(10, 8)
	end
end

function imgui.CenterText(text)
	local w = imgui.GetWindowWidth()
	local sz = imgui.CalcTextSize(text)
	local sw = tonumber(sz.x) or 0
	imgui.SetCursorPosX(w / 2 - sw / 2)
	imgui.Text(text)
end
function imgui.CenterTextColored(color, text)
	local w = imgui.GetWindowWidth()
	local sz = imgui.CalcTextSize(text)
	local sw = tonumber(sz.x) or 0
	imgui.SetCursorPosX(w / 2 - sw / 2)
	imgui.TextColored(color, text)
end

local function HelpMark(text)
	imgui.SameLine()
	imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.00, 1.00), "[?]")
	if imgui.IsItemHovered() then
		imgui.BeginTooltip()
		imgui.PushTextWrapPos(400)
		imgui.Text(text)
		imgui.PopTextWrapPos()
		imgui.EndTooltip()
	end
end

local function sendOnfoot(x, y, z, keys)
	local data = allocateMemory(68)
	sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)
	setStructElement(data, 0, 4, 0, true)
	setStructElement(data, 4, 2, keys or 0, true)
	setStructFloatElement(data, 6, x, true)
	setStructFloatElement(data, 10, y, true)
	setStructFloatElement(data, 14, z, true)
	setStructFloatElement(data, 38, 0, true)
	setStructFloatElement(data, 42, 0, true)
	setStructFloatElement(data, 46, 0, true)
	sampSendOnfootData(data)
	freeMemory(data)
end

local function sendOnDialogResponse(button, list, text)
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, 215)
	raknetBitStreamWriteInt16(bs, 2)
	raknetBitStreamWriteInt32(bs, 0)
	raknetBitStreamWriteInt32(bs, #"OnDialogResponse")
	raknetBitStreamWriteString(bs, "OnDialogResponse")
	raknetBitStreamWriteInt32(bs, 8)
	raknetBitStreamWriteInt8(bs, 100)
	raknetBitStreamWriteInt32(bs, 0)
	raknetBitStreamWriteInt8(bs, 100)
	raknetBitStreamWriteInt32(bs, button)
	raknetBitStreamWriteInt8(bs, 100)
	raknetBitStreamWriteInt32(bs, list or -1)
	raknetBitStreamWriteInt8(bs, 115)
	raknetBitStreamWriteInt32(bs, #(text or ""))
	raknetBitStreamWriteString(bs, text or "")
	raknetSendBitStream(bs)
	raknetDeleteBitStream(bs)
end

local function bitStreamStructure(bs)
	local text = ''
	for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do
		local byte = raknetBitStreamReadInt8(bs)
		if byte >= 32 and byte <= 255 and byte ~= 37 then
			text = text .. string.char(byte)
		end
	end
	raknetBitStreamResetReadPointer(bs)
	return text
end

local net_game, object_pool, label_pool
local block_player_sync, block_vehicle_sync = false, false
local font_wh, font_big, font_sub
local render_font_wh
local DATA_GAP = 2.999

local house = {
	active = false, timer = os.clock(), timer_state = 0, pickup = -1,
	wh = { state = 0, number = 0, pickups = {}, sales = {}, check = 6 }
}

local lovlya = {
	house_wh = false, house_lov = false,
	biz = false, garage = false, garden = false,
	flood_biz = false, flood_alt = false
}

local custom_flood = {
	enabled = false, last_sent = 0,
	block_running = false, block_next_at = 0,
	block_current_idx = 0, block_next_msg_at = 0
}

local cam = {
	active = false, posX = 0.0, posY = 0.0, posZ = 0.0,
	angZ = 0.0, angY = 0.0, radarHud = 0, keyPressed = 0, speed = 1.0
}

local wh_items = {
	[10711]="Золотой рубль",[10716]="Отмычка",[10715]="Системный блок",[10707]="Телефон Nokia 3310",
	[10505]="Ноутбук",[10825]="Глушитель",[13923]="Красный кристалл",[10828]="Запчасти к ноутбуку",
	[10818]="Бутылка",[13952]="Лобовое стекло",[1044]="Металл",[10816]="Тряпка",
	[10708]="Телефон Nokia",[10826]="Сломанный iPhone",[13948]="Химия",[10833]="Колесо",
	[13922]="Спутник",[13929]="Модель РАФ-2203",[10819]="Шприц",[10706]="Гоночное сиденье",
	[10709]="Телефон Samsung",[10702]="Ящик с патронами",[10704]="Старое сиденье",[13928]="Модель ВАЗ-2109",
	[13925]="Зеленый кристалл",[10710]="Телефон iPhone",[10509]="Сломанный телевизор",[13926]="Синий кристалл",
	[13950]="Старый руль AMG",[10719]="Руль Nissan GTR",[10827]="Запчасти к iPhone",[10713]="Золотой червонец",
	[13930]="Гироскутер",[13927]="Модель Волга",[10712]="Золотые два рубля",[10723]="Ноутбук Apple",
	[10703]="Сломанный банкомат",[16212]="Мешочек с золотом",[10720]="Старый сейф",[15411]="КЛЮЧИ",
	[10508]="Телевизор",[10718]="Руль Mercedes AMG",[13924]="Сварка",[13949]="Двигатель",
	[10714]="Золотые пятьдесят",[10721]="Станок",[13951]="Запчасти к рулю AMG",[10831]="Инструменты",
	[10834]="Аккумулятор",[634]="Черное сиденье"
}
local wh_items_cp = {}
for model, name in pairs(wh_items) do wh_items_cp[model] = t(name) end

local wh_prices = {
	[10716]={ "Отмычка",3000 },[10707]={ "Телефон Nokia 3310",3000 },[10708]={ "Телефон Nokia",14000 },
	[10704]={ "Старое сиденье",5000 },[634]={ "Чёрное сиденье",12000 },[10709]={ "Телефон Samsung",22000 },
	[10715]={ "Системный блок",16000 },[10721]={ "Станок",16000 },[10706]={ "Гоночное сиденье",21000 },
	[10719]={ "Руль Nissan GT-R",31000 },[10718]={ "Руль Mercedes AMG",37000 },[10703]={ "Сломанный банкомат",25000 },
	[10720]={ "Старый сейф",26000 },[10833]={ "Диски",44000 },[10710]={ "Телефон iPhone",40000 },
	[10723]={ "Ноутбук Apple",72000 },[10711]={ "Золотой рубль",52000 },[10713]={ "Золотой червонец",103000 },
	[10712]={ "Золотые два рубля",70000 },[10714]={ "Золотые пятьдесят",173000 },[10508]={ "Телевизор",22000 },
	[10505]={ "Ноутбук",52000 },[13930]={ "Гироскутер",40000 },[13922]={ "Спутник",60000 },
	[13929]={ "Мини-машинка РАФ",4000 },[13928]={ "Мини-машинка ВАЗ",4000 },[13927]={ "Мини-машинка Волга",4000 },
	[13923]={ "Красный кристалл",12000 },[13925]={ "Зеленый кристалл",12000 },[13926]={ "Синий кристалл",12000 },
	[13948]={ "Химия",3200 },[13951]={ "Запчасти к рулю AMG",400000 },[16212]={ "Мешочек с золотом",350000 }
}
local wh_prices_cp = {}
for model, data in pairs(wh_prices) do wh_prices_cp[model] = { t(data[1]), data[2] } end

local function formatPrice(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	out = out:gsub("^%.", ""):gsub("%.$", "")
	return out
end

local wh_colors_names_raw = { "Красный","Оранжевый","Желтый","Голубой","Синий","Фиолетовый","Зеленый","Мятно-Зеленый" }
local wh_colors_names = {}
for i, n in ipairs(wh_colors_names_raw) do wh_colors_names[i] = t(n) end
local wh_colors_draw = { 4294641158,4294670598,4294441734,4278640123,4278590715,4287563515,4278647573,4281726305 }
local wh_colors_const = imgui.new["const char*"][#wh_colors_names](wh_colors_names)

if json.objwh and json.objwh.models then
	for model, _ in pairs(wh_items) do
		if json.objwh.models[tostring(model)] == nil then json.objwh.models[tostring(model)] = false end
	end
	saveJson()
end

lovlya.house_wh = json.lovlya.house_wh or false
lovlya.house_lov = json.lovlya.house_lov or false
lovlya.biz = json.lovlya.biz or false
lovlya.garage = json.lovlya.garage or false
lovlya.garden = json.lovlya.garden or false
lovlya.flood_biz = json.lovlya.flood_biz or false
lovlya.flood_alt = json.lovlya.flood_alt or false
custom_flood.enabled = json.customflood.enabled or false

local tg = { updateid = nil, nickname = "", player_id = 0, connected = false, ready = false }

function tg.send(text)
	if not json.telegram.enabled then return end
	local token = json.telegram.token or ""
	local chat_id = json.telegram.chat_id or ""
	if token == "" or chat_id == "" then return end
	local msg = string.format('[%s] %s\n%s', tg.nickname, os.date('%H:%M:%S'), tostring(text))
	msg = msg:gsub('{......}', ''):gsub(' ', '%%20'):gsub('\n', '%%0A')
	local url = 'https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text=' .. msg
	lua_thread.create(function() pcall(requests.get, url) end)
end
local function tg_runner()
	return effil.thread(function(u)
		local https = require 'ssl.https'
		local ok, result = pcall(https.request, u, '')
		if ok then return {true, result} else return {false, result} end
	end)
end
local function tg_http(url, resolve, reject)
	local runner = tg_runner()
	reject = reject or function() end
	lua_thread.create(function()
		local th = runner(url)
		local r = th:get(0)
		while not r do r = th:get(0); wait(0) end
		local status = th:status()
		if status == 'completed' then
			local ok, result = r[1], r[2]
			if ok then resolve(result) else reject(result) end
		elseif status == 'canceled' then reject(status) end
		th:cancel(0)
	end)
end
local function tg_get_last_update()
	if json.telegram.token == "" or json.telegram.chat_id == "" then return end
	local url = 'https://api.telegram.org/bot' .. json.telegram.token .. '/getUpdates?chat_id=' .. json.telegram.chat_id .. '&offset=-1'
	tg_http(url, function(result)
		if result then
			local proc = decodeJson(result)
			if proc and proc.ok then
				tg.updateid = (#proc.result > 0) and proc.result[1].update_id or 1
				tg.ready = true
			end
		end
	end)
end
local function tg_handle_message(result)
	if not result then return end
	local proc = decodeJson(result)
	if not proc or not proc.ok or #proc.result == 0 then return end
	local res = proc.result[1]
	if not res or res.update_id == tg.updateid then return end
	tg.updateid = res.update_id
	if not res.message or not res.message.text then return end
	local text = res.message.text .. ' '
	if text:match('^/info') then
		tg.send('Сервер: '..sampGetCurrentServerName()..'\nНик: '..tg.nickname..'\nID: '..tg.player_id..'\nHP: '..getCharHealth(PLAYER_PED))
	elseif text:match('^/chat .*') then
		local m = text:match('^/chat (.*) ')
		sampSendChat(u8:decode(m))
		tg.send('Отправлено в чат: '..m)
	elseif text:match('^/getplayers') then
		tg.send('Игроков рядом: '..(#getAllChars()-1))
	elseif text:match('^/poweroff') then
		tg.send('ОК, выключаю ПК'); os.execute('shutdown -s -t 0')
	elseif text:match('^/q') then
		tg.send('Выхожу из игры...'); deleteChar(PLAYER_PED)
	elseif text:match('^/help') then
		tg.send('/info\n/chat <текст>\n/getplayers\n/q\n/poweroff')
	end
end
local function tg_poll_updates()
	while not tg.ready do wait(100) end
	while true do
		if json.telegram.enabled and json.telegram.token ~= "" and json.telegram.chat_id ~= "" then
			local url = 'https://api.telegram.org/bot' .. json.telegram.token .. '/getUpdates?chat_id=' .. json.telegram.chat_id .. '&offset=-1'
			tg_http(url, tg_handle_message, function() end)
		end
		wait(1000)
	end
end

local function camhack_enable()
	cam.active = true
	if json.camhack.hide_hud then displayRadar(false); displayHud(false) end
	local px, py, pz = getCharCoordinates(PLAYER_PED)
	cam.posX, cam.posY, cam.posZ = px, py, pz
	cam.angZ = getCharHeading(PLAYER_PED) * -1.0
	cam.angY = 0.0; cam.radarHud = 0; cam.keyPressed = 0
	cam.speed = json.camhack.speed or 1.0
	setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
	lockPlayerControl(true)
	showPopup("CamHack: включён", ">", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
end
local function camhack_disable()
	cam.active = false
	displayRadar(true); displayHud(true)
	cam.radarHud = 0
	lockPlayerControl(false)
	restoreCameraJumpcut(); setCameraBehindPlayer()
	showPopup("CamHack: выключен", "#", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
end

local function restoreVisualSkin()
	if visual_skin_original > 0 then
		local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
		if myid then set_player_skin(myid, visual_skin_original) end
	end
	visual_skin_original = 0
end
local function applyVisualSkin(skinId)
	if skinId <= 0 then return end
	if not isModelAvailable(skinId) then
		requestModel(skinId)
		local timeout = os.clock() + 3
		while not hasModelLoaded(skinId) and os.clock() < timeout do wait(0) end
	end
	local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if myid then set_player_skin(myid, skinId)
	elseif hasModelLoaded(skinId) then setCharModel(PLAYER_PED, skinId) end
end
local function applySkinById(id)
	if not id or id < 0 or id > MAX_SKIN_ID then
		showPopup("ID должен быть от 0 до " .. MAX_SKIN_ID, "!",
			imgui.ImVec4(0.95, 0.45, 0.30, 1.0))
		return
	end
	json.softs = json.softs or {}
	json.softs.visual_skin = json.softs.visual_skin or { enabled = false, skinId = 0 }
	local vs = json.softs.visual_skin
	vs.skinId  = id
	vs.enabled = true
	saveJson()
	if visual_skin_original == 0 then
		visual_skin_original = getCharModel(PLAYER_PED)
	end
	lua_thread.create(function()
		applyVisualSkin(id)
		showPopup("Скин применён: ID " .. id, ">", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
	end)
end

local function panicStop()
	json.showobj = false
	json.showpic = false
	json.show3d = false
	json.showdialog = false
	kiosk_monitor.enabled = false
	json.objwh.enabled = false
	lovlya.house_wh = false; json.lovlya.house_wh = false
	lovlya.house_lov = false; json.lovlya.house_lov = false
	lovlya.biz = false; json.lovlya.biz = false
	lovlya.garage = false; json.lovlya.garage = false
	lovlya.garden = false; json.lovlya.garden = false
	lovlya.flood_biz = false; json.lovlya.flood_biz = false
	lovlya.flood_alt = false; json.lovlya.flood_alt = false
	custom_flood.enabled = false
	json.customflood.enabled = false
	custom_flood.block_running = false
	custom_flood.block_current_idx = 0
	custom_flood.block_next_at = 0
	antish.enabled = false
	json.antish.enabled = false
	house.active = false
	if cam.active then camhack_disable() end
	if json.softs and json.softs.visual_skin and json.softs.visual_skin.enabled then
		restoreVisualSkin()
		json.softs.visual_skin.enabled = false
	end
	block_player_sync = false
	block_vehicle_sync = false
	showCursor(false)
	saveJson()
	showPopup("ЭКСТРЕННЫЙ СТОП — всё выключено", "!", imgui.ImVec4(1.0, 0.20, 0.20, 1.0))
	if json.telegram.enabled and json.telegram.notify_enter then
		tg.send('СРАБОТАЛ ЭКСТРЕННЫЙ СТОП')
	end
	if json.panic.unload then
		lua_thread.create(function()
			wait(700)
			thisScript():unload()
		end)
	end
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end

	imgui.Process = true

	sampRegisterChatCommand('rm', function() MainWindow[0] = not MainWindow[0] end)
	sampRegisterChatCommand('kioskraw', function()
		kiosk_monitor.business_active = false
		kiosk_monitor.last_raw = ''
		kiosk_monitor.items = {}
		kiosk_monitor.signature = ''
		local ok, f = pcall(io.open, KIOSK_LOG_PATH, 'w')
		if ok and f then f:close() end
		sampAddChatMessage(t('{C8A2FF}[Extra LV] {FFFFFF}Лог киоска очищен: ' .. KIOSK_LOG_PATH), -1)
	end)
	sampRegisterChatCommand('objwh', function()
		json.objwh.enabled = not json.objwh.enabled; saveJson()
		showPopup("WH предметов: "..(json.objwh.enabled and "вкл" or "выкл"))
	end)
	sampRegisterChatCommand('auth', function() showAuthWindow[0] = not showAuthWindow[0] end)
	sampRegisterChatCommand('tg', function()
		json.telegram.enabled = not json.telegram.enabled; saveJson()
		showPopup("Telegram: "..(json.telegram.enabled and "вкл" or "выкл"))
		if json.telegram.enabled then tg.send('Уведомления включены') end
	end)
	sampRegisterChatCommand('cflood', function()
		custom_flood.enabled = not custom_flood.enabled
		json.customflood.enabled = custom_flood.enabled; saveJson()
		custom_flood.block_running = false
		custom_flood.block_next_at = 0
		showPopup("Флуд: "..(custom_flood.enabled and "вкл" or "выкл"))
	end)
	sampRegisterChatCommand('panic', function() panicStop() end)
	sampRegisterChatCommand('stopall', function() panicStop() end)
	sampRegisterChatCommand('unload', function()
		showPopup("Выгрузка скрипта...", "#", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		lua_thread.create(function()
			wait(300)
			thisScript():unload()
		end)
	end)
	sampRegisterChatCommand('fk', function()
		antish.enabled = not antish.enabled
		json.antish.enabled = antish.enabled
		saveJson()
		showPopup("ANTIAFK: " .. (antish.enabled and "вкл" or "выкл"),
			antish.enabled and ">" or "#",
			antish.enabled and imgui.ImVec4(0.35, 0.85, 0.55, 1.0) or imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
	end)
	sampRegisterChatCommand('showdialog', function()
		json.showdialog = not json.showdialog; saveJson()
		showPopup("CEF Monitoring: "..(json.showdialog and "вкл" or "выкл"))
	end)
	sampRegisterChatCommand('kiosk', function()
		kiosk_monitor.enabled = not kiosk_monitor.enabled
		showPopup("Парсинг киоска: " .. (kiosk_monitor.enabled and "вкл" or "выкл"))
	end)
	sampRegisterChatCommand('skin', function() showSkinChanger[0] = not showSkinChanger[0] end)
	sampRegisterChatCommand('fskin', function(arg)
		local skinid = tonumber(arg)
		if not skinid or skinid < 0 or skinid > MAX_SKIN_ID then
			showPopup("/fskin ID (0-"..MAX_SKIN_ID..")", "!",
				imgui.ImVec4(0.95, 0.75, 0.30, 1.0))
			return
		end
		if skinid == 0 then
			restoreVisualSkin()
			json.softs.visual_skin.enabled = false
			json.softs.visual_skin.skinId = 0
			saveJson()
			showPopup("Скин восстановлен", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
			return
		end
		applySkinById(skinid)
	end)

	tg.nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
	tg.player_id = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
	if json.telegram.enabled and json.telegram.token ~= "" and json.telegram.chat_id ~= "" then
		tg_get_last_update()
		lua_thread.create(tg_poll_updates)
	end

	do
		net_game = sampapi.require('CNetGame', true).RefNetGame()
		object_pool = net_game.m_pPools.m_pObject
		pickup_pool = net_game.m_pPools.m_pPickup
		label_pool  = net_game.m_pPools.m_pLabel
	end

	cam.speed = json.camhack.speed or 1.0
	antish.enabled = json.antish.enabled or false

	if json.softs and json.softs.visual_skin and json.softs.visual_skin.enabled
	   and json.softs.visual_skin.skinId and json.softs.visual_skin.skinId > 0 then
		wait(2000)
		visual_skin_original = getCharModel(PLAYER_PED)
		lua_thread.create(function() applyVisualSkin(json.softs.visual_skin.skinId) end)
	end

	showPopup("Extra LV v.11.9 загружен. Insert — меню.", "i")
	scanSkinsFolder()

	while true do
		wait(0)

		if not panic_waiting and json.panic and json.panic.vk and json.panic.vk > 0 then
			if isKeyJustPressed(json.panic.vk) then panicStop() end
		end

		if json.softs and json.softs.visual_skin and json.softs.visual_skin.enabled
		   and json.softs.visual_skin.skinId and json.softs.visual_skin.skinId > 0 then
			if os.clock() - visual_skin_last_check > 0.7 then
				visual_skin_last_check = os.clock()
				local want = json.softs.visual_skin.skinId
				local cur = getCharModel(PLAYER_PED)
				if cur ~= want then
					if not isModelAvailable(want) then requestModel(want) end
					local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
					if myid then set_player_skin(myid, want) end
				end
			end
		end

		if isKeyJustPressed(vkeys.VK_INSERT) then MainWindow[0] = not MainWindow[0] end
		if isKeyDown(vkeys.VK_C) and isKeyDown(0x31) and not cam.active then camhack_enable() end
		if isKeyDown(vkeys.VK_C) and isKeyDown(0x32) and cam.active then camhack_disable() end

		if cam.active and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
			local offMouX, offMouY = getPcMouseMovement()
			cam.angZ = cam.angZ + offMouX / 4.0
			cam.angY = cam.angY + offMouY / 4.0
			if cam.angZ > 360.0 then cam.angZ = cam.angZ - 360.0 end
			if cam.angZ < 0.0 then cam.angZ = cam.angZ + 360.0 end
			if cam.angY > 89.0 then cam.angY = 89.0 end
			if cam.angY < -89.0 then cam.angY = -89.0 end
			local speed = cam.speed
			local radZ = math.rad(cam.angZ)
			local radY = math.rad(cam.angY)
			local sinZ = math.sin(radZ) * math.cos(radY)
			local cosZ = math.cos(radZ) * math.cos(radY)
			local sinY = math.sin(radY)
			pointCameraAtPoint(cam.posX + sinZ, cam.posY + cosZ, cam.posZ + sinY, 2)
			if isKeyDown(vkeys.VK_W) then
				cam.posX = cam.posX + sinZ * speed; cam.posY = cam.posY + cosZ * speed; cam.posZ = cam.posZ + sinY * speed
				setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
			end
			if isKeyDown(vkeys.VK_S) then
				local rZ = math.rad(cam.angZ + 180.0); local rY = math.rad(cam.angY * -1.0)
				cam.posX = cam.posX + math.sin(rZ) * math.cos(rY) * speed
				cam.posY = cam.posY + math.cos(rZ) * math.cos(rY) * speed
				cam.posZ = cam.posZ + math.sin(rY) * speed
				setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
			end
			if isKeyDown(vkeys.VK_A) then
				local rZ = math.rad(cam.angZ - 90.0)
				cam.posX = cam.posX + math.sin(rZ) * speed
				cam.posY = cam.posY + math.cos(rZ) * speed
				setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
			end
			if isKeyDown(vkeys.VK_D) then
				local rZ = math.rad(cam.angZ + 90.0)
				cam.posX = cam.posX + math.sin(rZ) * speed
				cam.posY = cam.posY + math.cos(rZ) * speed
				setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
			end
			if isKeyDown(vkeys.VK_SPACE) then
				cam.posZ = cam.posZ + speed
				setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
			end
			if isKeyDown(vkeys.VK_SHIFT) then
				cam.posZ = cam.posZ - speed
				setFixedCameraPosition(cam.posX, cam.posY, cam.posZ, 0.0, 0.0, 0.0)
			end
			if cam.keyPressed == 0 and isKeyDown(vkeys.VK_F10) then
				cam.keyPressed = 1
				if cam.radarHud == 0 then displayRadar(true); displayHud(true); cam.radarHud = 1
				else displayRadar(false); displayHud(false); cam.radarHud = 0 end
			end
			if wasKeyReleased(vkeys.VK_F10) and cam.keyPressed == 1 then cam.keyPressed = 0 end
		end

		-- ============================================================
		-- ЧС: перебор игроков (CRMP-совместимый)
		-- ============================================================
		if json.chs and json.chs.list and #json.chs.list > 0 then
			local myid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
			for pid = 0, 2048 do
				if sampIsPlayerConnected(pid) and pid ~= myid then
					local nick = sampGetPlayerNickname(pid)
					if nick then
						for _, chs_nick in ipairs(json.chs.list) do
							if nick == chs_nick then
								local res = sampGetCharHandleBySampPlayerId(pid)
								if res then
									local bs = raknetNewBitStream()
									raknetBitStreamWriteInt16(bs, pid)
									raknetEmulRpcReceiveBitStream(163, bs)
									raknetDeleteBitStream(bs)
								end
								break
							end
						end
					end
				end
			end
		end

		if lovlya.biz or lovlya.garage or lovlya.garden then
			local pxx, pyy, pzz = getCharCoordinates(PLAYER_PED)
			for i = 0, 2048 do
				if sampIs3dTextDefined(i) then
					local text, color, posX, posY, posZ = sampGet3dTextInfoById(i)
					local dist2d = getDistanceBetweenCoords2d(pxx, pyy, posX, posY)
					local dist3d = getDistanceBetweenCoords3d(pxx, pyy, pzz, posX, posY, posZ)
					if lovlya.biz and text:find('/buybiz') then
						local sx, sy = convert3DCoordsToScreen(posX, posY, posZ)
						if sx and sy then renderFontDrawText(render_font_wh, "{FF0000}BIZ {FFFFFF}"..string.format("%.0fm", dist3d), sx, sy, color) end
						if dist2d < 1 then
							lovlya.biz = false; json.lovlya.biz = false; saveJson()
							sampSendChat("/buybiz")
							showPopup("Бизнес: попытка покупки, стоп - Y", "!")
							lua_thread.create(function()
								while not sampIsChatInputActive() do
									wait(0); setVirtualKeyDown(13, true); wait(1); setVirtualKeyDown(13, false)
									if wasKeyPressed(vkeys.VK_Y) then break end
								end
							end)
						end
					end
					if lovlya.garage and text:find('/buygarage') then
						local sx, sy = convert3DCoordsToScreen(posX, posY, posZ)
						if sx and sy then renderFontDrawText(render_font_wh, "{00AAFF}GARAGE {FFFFFF}"..string.format("%.0fm", dist3d), sx, sy, color) end
						if dist2d < 1 then
							lovlya.garage = false; json.lovlya.garage = false; saveJson()
							sampSendChat("/buygarage")
							showPopup("Гараж: попытка покупки, стоп - Y", "!")
							lua_thread.create(function()
								while not sampIsChatInputActive() do
									wait(0); setVirtualKeyDown(13, true); wait(1); setVirtualKeyDown(13, false)
									if wasKeyPressed(vkeys.VK_Y) then break end
								end
							end)
						end
					end
					if lovlya.garden and text:find('/buygarden') then
						local sx, sy = convert3DCoordsToScreen(posX, posY, posZ)
						if sx and sy then renderFontDrawText(render_font_wh, "{00FF00}GARDEN {FFFFFF}"..string.format("%.0fm", dist3d), sx, sy, color) end
						if dist2d < 1 then
							lovlya.garden = false; json.lovlya.garden = false; saveJson()
							sampSendChat("/buygarden")
							showPopup("Огород: попытка покупки, стоп - Y", "!")
							lua_thread.create(function()
								while not sampIsChatInputActive() do
									wait(0); setVirtualKeyDown(13, true); wait(1); setVirtualKeyDown(13, false)
									if wasKeyPressed(vkeys.VK_Y) then break end
								end
							end)
						end
					end
				end
			end
		end

		if lovlya.flood_biz then sampSendChat("/buybiz") wait(json.lovlya.delay_biz or 500) end

		if lovlya.flood_alt then
			setGameKeyState(21, 255); wait(1); setGameKeyState(21, 0)
			if wasKeyPressed(vkeys.VK_Y) and not sampIsChatInputActive() then
				lovlya.flood_alt = false; json.lovlya.flood_alt = false; saveJson()
				showPopup("Флуд ALT+ENTER остановлен", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
			end
		end

		if custom_flood.enabled and json.customflood.mode == "single" then
			local now_ms = os.clock() * 1000
			if json.customflood.text and json.customflood.text ~= "" and
			   now_ms - custom_flood.last_sent >= (json.customflood.interval or 1000) then
				custom_flood.last_sent = now_ms
				sampSendChat(u8:decode(json.customflood.text))
			end
		end

		if custom_flood.enabled and json.customflood.mode == "block" then
			local now_ms = os.clock() * 1000
			local block = json.customflood.block or {}
			local msgs = block.messages or {}
			local msg_delay = (block.msg_delay or 500) * 1.0
			local block_interval = (block.block_interval or 180) * 1000.0
			if #msgs > 0 then
				if not custom_flood.block_running and now_ms >= custom_flood.block_next_at then
					custom_flood.block_running = true
					custom_flood.block_current_idx = 1
					custom_flood.block_next_msg_at = now_ms
				end
				if custom_flood.block_running and now_ms >= custom_flood.block_next_msg_at then
					local msg = msgs[custom_flood.block_current_idx]
					if msg and msg ~= "" then sampSendChat(u8:decode(msg)) end
					custom_flood.block_current_idx = custom_flood.block_current_idx + 1
					if custom_flood.block_current_idx > #msgs then
						custom_flood.block_running = false
						custom_flood.block_current_idx = 0
						custom_flood.block_next_at = now_ms + block_interval
					else
						custom_flood.block_next_msg_at = now_ms + msg_delay
					end
				end
			end
		end

		if isKeyJustPressed(vkeys.VK_F4) then
			lovlya.house_lov = not lovlya.house_lov
			json.lovlya.house_lov = lovlya.house_lov; saveJson()
			showCursor(lovlya.house_lov)
			showPopup("Lov домов: "..(lovlya.house_lov and "включён" or "выключен"),
				lovlya.house_lov and ">" or "#",
				lovlya.house_lov and imgui.ImVec4(0.35, 0.85, 0.55, 1.0) or imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		end

		if isKeyDown(vkeys.VK_B) and isKeyJustPressed(vkeys.VK_1) then
			house.active = not house.active
			house.timer = os.clock() + 1
			house.timer_state = 0
			if house.active then
				local x, y, z = getCharCoordinates(PLAYER_PED)
				local index, distance = -1, 99999
				local count = pickup_pool.m_nCount
				local i = ffi.C.MAX_PICKUPS - 1
				while count > 0 and i >= 0 do
					if pickup_pool.m_nId[i] ~= -1 then
						if pickup_pool.m_object[i].m_nModel == 1273 then
							local d = getDistanceBetweenCoords3d(x, y, z, pickup_pool.m_object[i].m_position.x, pickup_pool.m_object[i].m_position.y, pickup_pool.m_object[i].m_position.z)
							if d < distance then index, distance = i, d end
						end
						count = count - 1
					end
					i = i - 1
				end
				if index ~= -1 then house.pickup = index end
			end
			showPopup("House auto: "..(house.active and "включён" or "выключен"),
				house.active and ">" or "#",
				house.active and imgui.ImVec4(0.35, 0.85, 0.55, 1.0) or imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		end

		if house.active then
			if house.timer_state == 1 and house.timer <= os.clock() then
				house.timer = os.clock() + math.random(0.15, 0.2)
				house.timer_state = 0
				setVirtualKeyDown(vkeys.VK_LMENU, false)
				local bs = raknetNewBitStream()
				raknetBitStreamWriteInt16(bs, 2); raknetBitStreamWriteInt32(bs, 2); raknetBitStreamWriteInt8(bs, 1)
				local str = 'interface(\'GameText\').add(\'[2,"~r~Закрыто",3000,0,-1,1,0,3.00]\')'
				raknetBitStreamWriteInt32(bs, #str); raknetBitStreamWriteString(bs, str)
				raknetEmulPacketReceiveBitStream(215, bs); raknetDeleteBitStream(bs)
			end
			if house.timer_state == 0 and house.timer <= os.clock() then
				house.timer = os.clock() + math.random(0.075, 0.1)
				house.timer_state = 1
				setVirtualKeyDown(vkeys.VK_LMENU, true)
			end
		end
	end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	setExtraTheme()
	local builder = imgui.ImFontGlyphRangesBuilder()
	builder:AddRanges(imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
	builder:AddRanges(imgui.GetIO().Fonts:GetGlyphRangesDefault())
	builder:AddText([[‚„…†‡€‰‹‘’“”•–—™›№«»]])
	local glyphs = imgui.ImVector_ImWchar()
	builder:BuildRanges(glyphs)
	local font_path = getFolderPath(0x14)..'\\trebucbd.ttf'
	if not doesFileExist(font_path) then font_path = getFolderPath(0x14)..'\\tahoma.ttf' end
	if not doesFileExist(font_path) then font_path = getFolderPath(0x14)..'\\arial.ttf' end
	imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 14, nil, glyphs[0].Data)
	font_wh  = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 20, nil, glyphs[0].Data)
	font_big = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 96, nil, glyphs[0].Data)
	font_sub = imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 32, nil, glyphs[0].Data)
	render_font_wh = renderCreateFont('Arial', 20, font_flag.BOLD + font_flag.SHADOW)
end)

local function isCleanStyle()
	return (json.ui_style or "dark") == "clean"
end

imgui.OnFrame(
	function() return MainWindow[0] and not isCleanStyle() end,
	function(player)
		player.HideCursor = false
		local sx, sy = getScreenResolution()
		bg_alpha = math.floor(clamp(bg_alpha + (MainWindow[0] and 12 or -12), 0, 180))
		imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(sx, sy), imgui.Cond.Always)
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
		imgui.Begin('##anim_bg', nil,
			imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove +
			imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoBackground +
			imgui.WindowFlags.NoBringToFrontOnFocus)
		local dl = imgui.GetWindowDrawList()
		local tt = os.clock()
		local a = bg_alpha / 180.0
		local cx, cy = sx / 2, sy / 2
		local rr = math.floor(math.sin(tt * 0.9)       * 127 + 128)
		local gg = math.floor(math.sin(tt * 0.9 + 2.1) * 127 + 128)
		local bb = math.floor(math.sin(tt * 0.9 + 4.2) * 127 + 128)
		local rainbowCol = rgba(rr/255, gg/255, bb/255, 0.85 * a)
		local glow       = rgba(rr/255, gg/255, bb/255, 0.25 * a)
		local soft       = rgba(0.35, 0.55, 1.00, 0.30 * a)
		local accent     = rgba(0.55, 0.35, 0.95, 0.85 * a)
		local bobX = math.sin(tt * 0.45) * 14
		local bobY = math.cos(tt * 0.55) * 8
		local baseR = 260 + math.sin(tt * 0.7) * 12
		dl:AddCircle(imgui.ImVec2(cx + bobX, cy + bobY), baseR, soft, 128, 1.5)
		dl:AddCircle(imgui.ImVec2(cx + bobX, cy + bobY), baseR + 14, rgba(0.55, 0.35, 0.95, 0.25 * a), 128, 1.0)
		dl:AddCircle(imgui.ImVec2(cx + bobX, cy + bobY), 130 + math.sin(tt * 1.1) * 6,
			rgba(0.55, 0.85, 1.0, 0.30 * a), 96, 1.2)
		local rot = tt * 0.35
		for i = 1, 6 do
			local ang = rot + i * (math.pi * 2 / 6)
			local px = cx + bobX + math.cos(ang) * baseR
			local py = cy + bobY + math.sin(ang) * baseR
			local s = 10 + math.sin(tt * 1.4 + i) * 3
			dl:AddQuadFilled(imgui.ImVec2(px, py - s), imgui.ImVec2(px + s, py),
				imgui.ImVec2(px, py + s), imgui.ImVec2(px - s, py), rgba(0.75, 0.55, 1.0, 0.55 * a))
		end
		local rot2 = -tt * 0.5
		for i = 1, 4 do
			local ang = rot2 + i * (math.pi / 2)
			local rr2 = baseR + 60
			local px = cx + bobX + math.cos(ang) * rr2
			local py = cy + bobY + math.sin(ang) * rr2
			local s = 14
			dl:AddTriangleFilled(imgui.ImVec2(px, py - s),
				imgui.ImVec2(px + s, py + s * 0.8), imgui.ImVec2(px - s, py + s * 0.8),
				rgba(0.55, 0.85, 1.0, 0.45 * a))
		end
		for i = 1, 12 do
			local ang = tt * 0.15 + i * (math.pi * 2 / 12)
			local x1 = cx + bobX + math.cos(ang) * (baseR + 30)
			local y1 = cy + bobY + math.sin(ang) * (baseR + 30)
			local x2 = cx + bobX + math.cos(ang) * (baseR + 90)
			local y2 = cy + bobY + math.sin(ang) * (baseR + 90)
			dl:AddLine(imgui.ImVec2(x1, y1), imgui.ImVec2(x2, y2), rgba(0.55, 0.35, 0.95, 0.25 * a), 1.0)
		end
		local m = 40
		local L = 60
		local colBr = rgba(0.55, 0.35, 0.95, 0.55 * a)
		dl:AddLine(imgui.ImVec2(m, m), imgui.ImVec2(m + L, m), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(m, m), imgui.ImVec2(m, m + L), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(sx - m, m), imgui.ImVec2(sx - m - L, m), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(sx - m, m), imgui.ImVec2(sx - m, m + L), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(m, sy - m), imgui.ImVec2(m + L, sy - m), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(m, sy - m), imgui.ImVec2(m, sy - m - L), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(sx - m, sy - m), imgui.ImVec2(sx - m - L, sy - m), colBr, 2.0)
		dl:AddLine(imgui.ImVec2(sx - m, sy - m), imgui.ImVec2(sx - m, sy - m - L), colBr, 2.0)
		imgui.PushFont(font_big)
		local bsz = imgui.CalcTextSize("Extra LV")
		local bw = tonumber(bsz.x) or 0
		local bh = tonumber(bsz.y) or 0
		local big_x = cx - bw / 2 + bobX
		local big_y = cy - bh / 1.4 + bobY
		dl:AddText(imgui.ImVec2(big_x - 3, big_y - 3), glow, "Extra LV")
		dl:AddText(imgui.ImVec2(big_x + 3, big_y + 3), glow, "Extra LV")
		dl:AddText(imgui.ImVec2(big_x, big_y), rainbowCol, "Extra LV")
		imgui.PopFont()
		imgui.PushFont(font_sub)
		local ssz = imgui.CalcTextSize("H I S S O K A S H O P")
		local sw = tonumber(ssz.x) or 0
		dl:AddText(imgui.ImVec2(cx - sw/2 + bobX, big_y + bh + 8 + bobY), accent, "H I S S O K A S H O P")
		imgui.PopFont()
		dl:AddText(imgui.ImVec2(20, sy - 30), rgba(0.55, 0.55, 0.75, 0.55 * a), "Extra LV | by HISSOKASHOP | v.11.9")
		imgui.End()
		imgui.PopStyleColor()
		imgui.PopStyleVar(3)
	end
)

local objwh_cache = {}
local objwh_last_scan = 0

imgui.OnFrame(
	function() return json.objwh and json.objwh.enabled and isSampAvailable() end,
	function(player)
		player.HideCursor = true
		local resX, resY = getScreenResolution()
		local now = os.clock()
		if now - objwh_last_scan > 0.25 then
			objwh_last_scan = now
			objwh_cache = {}
			pcall(function()
				for _, obj in pairs(getAllObjects()) do
					if isObjectOnScreen(obj) then
						local res, oX, oY, oZ = getObjectCoordinates(obj)
						local model = getObjectModel(obj)
						if res and oX and model then
							table.insert(objwh_cache, { obj = obj, x = oX, y = oY, z = oZ, model = model })
						end
					end
				end
			end)
		end
		if not font_wh then return end
		imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(resX, resY), imgui.Cond.Always)
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
		imgui.Begin('##objwh_draw', nil,
			imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove +
			imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoBackground +
			imgui.WindowFlags.NoBringToFrontOnFocus)
		local dl = imgui.GetWindowDrawList()
		local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
		local poX, poY = convert3DCoordsToScreen(pX, pY, pZ)
		imgui.PushFont(font_wh)
		for _, o in ipairs(objwh_cache) do
			if wh_items_cp[o.model] and json.objwh.models[tostring(o.model)] then
				local soX, soY = convert3DCoordsToScreen(o.x, o.y, o.z)
				local dist3d = getDistanceBetweenCoords3d(o.x, o.y, o.z, pX, pY, pZ)
				if soX and soY and dist3d > 1.2 then
					if poX and poY then
						dl:AddLine(imgui.ImVec2(poX, poY), imgui.ImVec2(soX, soY),
							wh_colors_draw[(json.objwh.colortr or 2) + 1], json.objwh.sizetr or 1.0)
					end
					local info = wh_prices[o.model]
					local priceTxt = ""
					if json.objwh.show_price ~= false and info then
						priceTxt = " ~" .. formatPrice(info[2])
					end
					local txt = string.format("%s %dm.%s", wh_items_cp[o.model], math.floor(dist3d), priceTxt)
					local tsize = imgui.CalcTextSize(txt)
					local tsx = tonumber(tsize.x) or 0
					dl:AddText(imgui.ImVec2(soX - tsx / 2, soY - 20), wh_colors_draw[json.objwh.colortx or 2], txt)
				end
			end
		end
		imgui.PopFont()
		imgui.End()
		imgui.PopStyleColor()
		imgui.PopStyleVar(3)
	end
)

local info_cache = { objects = {}, pickups = {}, labels = {} }
local info_last_scan = 0
local function rescan_info_entities()
	info_cache.objects = {}
	info_cache.pickups = {}
	info_cache.labels  = {}
	local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
	if json.showobj then
		pcall(function()
			for _, obj in pairs(getAllObjects()) do
				if isObjectOnScreen(obj) then
					local res, oX, oY, oZ = getObjectCoordinates(obj)
					if res and oX then
						local model = getObjectModel(obj)
						table.insert(info_cache.objects, { x = oX, y = oY, z = oZ, model = model,
							dist = getDistanceBetweenCoords3d(pX, pY, pZ, oX, oY, oZ) })
					end
				end
			end
		end)
	end
	if json.showpic then
		pcall(function()
			if pickup_pool then
				local count = pickup_pool.m_nCount
				local i = ffi.C.MAX_PICKUPS - 1
				while count > 0 and i >= 0 do
					if pickup_pool.m_nId[i] ~= -1 then
						local o = pickup_pool.m_object[i]
						if o and o.m_nModel and o.m_nModel ~= 0 then
							local pos = o.m_position
							if pos then
								local dist = getDistanceBetweenCoords3d(pX, pY, pZ, pos.x, pos.y, pos.z)
								if dist < 200 then
									table.insert(info_cache.pickups, { id = pickup_pool.m_nId[i], model = o.m_nModel,
										x = pos.x, y = pos.y, z = pos.z, dist = dist })
								end
							end
						end
						count = count - 1
					end
					i = i - 1
				end
			end
		end)
	end
	if json.show3d then
		pcall(function()
			for i = 0, 2048 do
				if sampIs3dTextDefined(i) then
					local text, color, tX, tY, tZ = sampGet3dTextInfoById(i)
					if text and tX then
						local dist = getDistanceBetweenCoords3d(pX, pY, pZ, tX, tY, tZ)
						if dist < 200 then
							table.insert(info_cache.labels, { id = i, text = text, color = color,
								x = tX, y = tY, z = tZ, dist = dist })
						end
					end
				end
			end
		end)
	end
end

imgui.OnFrame(
	function() return (json.showobj or json.showpic or json.show3d) and isSampAvailable() end,
	function(player)
		player.HideCursor = true
		local resX, resY = getScreenResolution()
		local now = os.clock()
		if now - info_last_scan > 0.25 then
			info_last_scan = now
			rescan_info_entities()
		end
		if not font_wh then return end
		imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(resX, resY), imgui.Cond.Always)
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 0))
		imgui.Begin('##info_draw', nil,
			imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove +
			imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoBackground +
			imgui.WindowFlags.NoBringToFrontOnFocus)
		local dl = imgui.GetWindowDrawList()
		local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
		local poX, poY = convert3DCoordsToScreen(pX, pY, pZ)
		imgui.PushFont(font_wh)
		local function drawLabel(sX, sY, txt, col)
			local sz = imgui.CalcTextSize(txt)
			local sw = tonumber(sz.x) or 0
			local sh = tonumber(sz.y) or 0
			local px, py = sX - sw / 2, sY - 20
			dl:AddRectFilled(imgui.ImVec2(px - 4, py - 2), imgui.ImVec2(px + sw + 4, py + sh + 2),
				rgba(0.05, 0.05, 0.09, 0.55), 4)
			dl:AddText(imgui.ImVec2(px, py), col, txt)
		end
		if json.showobj then
			for _, o in ipairs(info_cache.objects) do
				local sX, sY = convert3DCoordsToScreen(o.x, o.y, o.z)
				if sX and sY and o.dist > 1.0 then
					if poX and poY then
						dl:AddLine(imgui.ImVec2(poX, poY), imgui.ImVec2(sX, sY), rgba(0.55, 0.85, 1.0, 0.75), 1.2)
					end
					drawLabel(sX, sY, string.format("[OBJ %d] %.0fm", o.model, o.dist), rgba(0.70, 0.90, 1.0, 1.0))
				end
			end
		end
		if json.showpic then
			for _, o in ipairs(info_cache.pickups) do
				local sX, sY = convert3DCoordsToScreen(o.x, o.y, o.z)
				if sX and sY and o.dist > 1.0 then
					if poX and poY then
						dl:AddLine(imgui.ImVec2(poX, poY), imgui.ImVec2(sX, sY), rgba(1.0, 0.85, 0.35, 0.75), 1.2)
					end
					drawLabel(sX, sY, string.format("[PIC id:%d] mod:%d %.0fm", o.id, o.model, o.dist), rgba(1.0, 0.92, 0.55, 1.0))
				end
			end
		end
		if json.show3d then
			for _, o in ipairs(info_cache.labels) do
				local sX, sY = convert3DCoordsToScreen(o.x, o.y, o.z)
				if sX and sY and o.dist > 1.0 then
					if poX and poY then
						dl:AddLine(imgui.ImVec2(poX, poY), imgui.ImVec2(sX, sY), rgba(0.55, 1.0, 0.65, 0.75), 1.2)
					end
					local cleaned = o.text:gsub("{.-}", "")
					if #cleaned > 48 then cleaned = cleaned:sub(1, 48) .. "..." end
					drawLabel(sX, sY, string.format("[3D #%d] %s (%.0fm)", o.id, cleaned, o.dist), rgba(0.75, 1.0, 0.80, 1.0))
				end
			end
		end
		imgui.PopFont()
		imgui.End()
		imgui.PopStyleColor()
		imgui.PopStyleVar(3)
	end
)

imgui.OnFrame(
	function() return json.showdialog and isSampAvailable() end,
	function(player)
		player.HideCursor = true
		if cef_info.id == "" then return end
		local resX = select(1, getScreenResolution())
		imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - 180, 16), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(0, 0), imgui.Cond.Always)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.05, 0.05, 0.09, 0.78))
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.55, 0.85, 1.00, 0.55))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 8.0)
		imgui.Begin("##dialog_id_overlay", nil,
			imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
			imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar +
			imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoFocusOnAppearing +
			imgui.WindowFlags.NoInputs)
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.00, 1.0),
			string.format("CEF Interface: %s", tostring(cef_info.id)))
		if cef_info.source ~= "" then
			imgui.TextColored(imgui.ImVec4(0.75, 0.75, 0.90, 1.0), tostring(cef_info.source))
		end
		imgui.End()
		imgui.PopStyleVar()
		imgui.PopStyleColor(2)
	end
)

imgui.OnFrame(
	function() return isSampAvailable() and lovlya.house_wh end,
	function(player)
		player.HideCursor = true
		imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowSize(imgui.ImVec2(config.screen.x, config.screen.y), imgui.Cond.FirstUseEver)
		imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0)
		imgui.Begin('wh', nil, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoBackground + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoInputs)
		imgui.PushFont(font_wh)
		local dl = imgui.GetWindowDrawList()
		dl:ChannelsSplit(4)
		local traceurs = {}
		if lovlya.house_wh then
			local x, y, z = getCharCoordinates(PLAYER_PED)
			local count = pickup_pool.m_nCount
			local i = ffi.C.MAX_PICKUPS - 1
			while count > 0 and i >= 0 do
				if pickup_pool.m_nId[i] ~= -1 then
					local pic
					if house.wh.state == 4 then
						for j, v in ipairs(house.wh.pickups) do
							if i == v and house.wh.sales[j] ~= nil then pic = house.wh.sales[j] end
						end
					end
					if pickup_pool.m_object[i].m_nModel == 1273 or pic ~= nil then
						local ren_count = 16
						local position = { main = { x=0,y=0,z=0 }, start = { x=x,y=y,z=z }, finish = { x=0,y=0,z=0 } }
						position.main.x = pickup_pool.m_object[i].m_position.x
						position.main.y = pickup_pool.m_object[i].m_position.y
						position.main.z = pickup_pool.m_object[i].m_position.z
						if not isPointOnScreen(position.main.x, position.main.y, position.main.z) then
							position.finish.x = position.main.x
							position.finish.y = position.main.y
							position.finish.z = position.main.z
							local _, _, _, zz = convert3DCoordsToScreenEx(position.main.x, position.main.y, position.main.z)
							while (zz <= 0 or isPointOnScreen(position.main.x, position.main.y, position.main.z)) and ren_count > 0 do
								ren_count = ren_count - 1
								if zz > 0 then
									position.start.x = position.main.x; position.start.y = position.main.y; position.start.z = position.main.z
									position.main.x = (position.main.x + position.finish.x) / 2
									position.main.y = (position.main.y + position.finish.y) / 2
									position.main.z = (position.main.z + position.finish.z) / 2
								else
									position.finish.x = position.main.x; position.finish.y = position.main.y; position.finish.z = position.main.z
									position.main.x = (position.main.x + position.start.x) / 2
									position.main.y = (position.main.y + position.start.y) / 2
									position.main.z = (position.main.z + position.start.z) / 2
								end
								_, _, _, zz = convert3DCoordsToScreenEx(position.main.x, position.main.y, position.main.z)
							end
						end
						local x1, y1 = convert3DCoordsToScreen(x, y, z)
						local x2, y2 = convert3DCoordsToScreen(position.main.x, position.main.y, position.main.z)
						table.insert(traceurs, {
							id = i, x1 = x1, y1 = y1, x2 = x2, y2 = y2,
							line_color = pic == false and 0xFFFFFFFF or 0xFF00FF00,
							line_thick = pic == false and 1 or 3,
							circle_draw = isPointOnScreen(pickup_pool.m_object[i].m_position.x, pickup_pool.m_object[i].m_position.y, pickup_pool.m_object[i].m_position.z) and pic ~= false,
							circle_color = 0xFFFFFFFF, circle_radius = 15, pulse = 0.0
						})
					end
					count = count - 1
				end
				i = i - 1
			end
		end

		if lovlya.house_lov then
			if isKeyJustPressed(vkeys.VK_RBUTTON) then
				lovlya.house_lov = false; json.lovlya.house_lov = false; saveJson()
				showCursor(false)
				showPopup("Lov домов: выключен", "#", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
			else
				local cX, cY = getCursorPos()
				local index, distance = -1, 99999
				for i, v in ipairs(traceurs) do
					local d = math.sqrt((cX - v.x2)^2 + (cY - v.y2)^2)
					if d < distance then distance, index = d, i end
				end
				if index ~= -1 and distance < config.screen.x / 10 then
					traceurs[index].circle_color = 0xFFFF9933
					traceurs[index].circle_radius = 45
					if isKeyJustPressed(vkeys.VK_LBUTTON) then
						if lov_busy then
							showPopup("Подожди: операция выполняется", "!", imgui.ImVec4(0.95, 0.75, 0.30, 1.0))
						else
							lov_busy = true
							lovlya.house_lov = false; json.lovlya.house_lov = false; saveJson()
							showCursor(false)
							showPopup("Lov домов: выполнение...", ">")
							local lov_index = traceurs[index].id
							lua_thread.create(function()
								block_player_sync = true
								block_vehicle_sync = true
								if isCharInAnyCar(PLAYER_PED) then
									sampSendExitVehicle(select(2, sampGetVehicleIdByCarHandle(storeCarCharIsInNoSave(PLAYER_PED))))
								end
								local x, y, z = getCharCoordinates(PLAYER_PED)
								local qX = pickup_pool.m_object[lov_index].m_position.x
								local qY = pickup_pool.m_object[lov_index].m_position.y
								local qZ = pickup_pool.m_object[lov_index].m_position.z
								local dist = getDistanceBetweenCoords3d(x, y, z, qX, qY, qZ)
								house_purchase_failed = false
								sendOnfoot(x, y, z)
								for i = 0, dist, DATA_GAP do sendOnfoot(x + (qX - x) * i / dist, y + (qY - y) * i / dist, z + (qZ - z) * i / dist) end
								sampSendPickedUpPickup(lov_index)
								sendOnfoot(qX, qY, qZ, 1024)
								for i = math.floor(dist / DATA_GAP) * DATA_GAP, 0, -DATA_GAP do sendOnfoot(x + (qX - x) * i / dist, y + (qY - y) * i / dist, z + (qZ - z) * i / dist) end
								sendOnfoot(x, y, z)
								wait(200)
								sendOnfoot(x, y, z)
								for i = 0, dist, DATA_GAP do sendOnfoot(x + (qX - x) * i / dist, y + (qY - y) * i / dist, z + (qZ - z) * i / dist) end
								sendOnfoot(qX, qY, qZ)
								sendOnDialogResponse(1)
								wait(0)
								for i = math.floor(dist / DATA_GAP) * DATA_GAP, 0, -DATA_GAP do sendOnfoot(x + (qX - x) * i / dist, y + (qY - y) * i / dist, z + (qZ - z) * i / dist) end
								sendOnfoot(x, y, z)
								wait(700)
								if not house_purchase_failed then
									json.stats.pickups_total = (json.stats.pickups_total or 0) + 1
									saveJson()
									showPopup("Дом словлен", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
									if json.telegram.enabled and json.telegram.notify_purchase then
										tg.send('Словлен дом. Всего: '..(json.stats.pickups_total or 0))
									end
								else
									showPopup("Дом не куплен: мало денег", "!", imgui.ImVec4(0.95, 0.45, 0.30, 1.0))
								end
								house_purchase_failed = false
								block_player_sync = false
								block_vehicle_sync = false
								lov_busy = false
							end)
						end
					end
				end
			end
		end

		local tt = os.clock()
		for _, v in ipairs(traceurs) do
			local rr = math.floor(math.sin(tt * 0.6) * 127 + 128)
			local gg = math.floor(math.sin(tt * 0.6 + 2) * 127 + 128)
			local bb = math.floor(math.sin(tt * 0.6 + 4) * 127 + 128)
			local rainbowCol = 0xFF000000 + rr * 0x10000 + gg * 0x100 + bb
			local lineColor = (v.line_color == 0xFF00FF00) and rainbowCol or v.line_color
			dl:ChannelsSetCurrent(2)
			dl:AddLine(imgui.ImVec2(v.x1, v.y1), imgui.ImVec2(v.x2, v.y2), lineColor, v.line_thick)
			v.pulse = (v.pulse or 0) + 0.08
			local pulseR = 3 + math.sin(v.pulse) * 1.5
			dl:AddCircleFilled(imgui.ImVec2(v.x2, v.y2), pulseR, rainbowCol, 16)
			dl:AddCircle(imgui.ImVec2(v.x2, v.y2), pulseR + 2, 0x55FFFFFF, 20, 1.0)
			if v.circle_draw then
				dl:ChannelsSetCurrent(3)
				local glowR = v.circle_radius + math.sin(v.pulse * 1.6) * 4
				dl:AddCircle(imgui.ImVec2(v.x2, v.y2), glowR, rgba(0.55, 0.35, 0.95, 0.35), 32, 2.0)
				dl:AddCircle(imgui.ImVec2(v.x2, v.y2), v.circle_radius, rgba(0.68, 0.48, 1.00, 0.9), 32, 1.6)
				dl:AddCircleFilled(imgui.ImVec2(v.x2, v.y2), 2, rgba(0.95, 0.96, 1.0, 0.9), 8)
			end
		end
		dl:ChannelsMerge()
		imgui.PopFont()
		imgui.End()
		imgui.PopStyleVar(3)
	end
)

local SIDEBAR_ITEMS = {
	{ name = "Настройки",   id = 1,  icon = "N" },
	{ name = "Авторизация", id = 12, icon = "A" },
	{ name = "Ловля",       id = 2,  icon = "L" },
	{ name = "Флуд",        id = 3,  icon = "!" },
	{ name = "Свалка",      id = 4,  icon = "P" },
	{ name = "Цены",        id = 5,  icon = "$" },
	{ name = "Киоск",       id = 14, icon = "K" },
	{ name = "Софты",       id = 13, icon = "S" },
	{ name = "Камера",      id = 6,  icon = "C" },
	{ name = "Telegram",    id = 7,  icon = "@" },
	{ name = "Оверлей",     id = 10, icon = "O" },
	{ name = "ЧС / ФПС",    id = 11, icon = "X" },
	{ name = "Справка",     id = 8,  icon = "i" }
}
for _, item in ipairs(SIDEBAR_ITEMS) do item.name = t(item.name) end

local MENU_W, MENU_H = 960, 620
local SIDE_W = 200
local alpha_main = new.float[1](0)
local mainwindow_tab = new.int(0)

local function drawContent()
	local windowWidth = imgui.GetWindowWidth()

	if mainwindow_tab[0] == 1 then
		local title = "Общие настройки"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(1.00, 0.35, 0.35, 1.0), "Экстренный стоп:")
		imgui.Separator()
		imgui.Text("Клавиша: ")
		imgui.SameLine()
		imgui.TextColored(imgui.ImVec4(1.00, 0.85, 0.35, 1.0), vkName(json.panic.vk))
		if not panic_waiting then
			if imgui.Button("Назначить клавишу", imgui.ImVec2(160, 26)) then
				panic_waiting = true
				showPopup("Нажми любую клавишу для паники", ">")
			end
		else
			if imgui.Button("Отмена", imgui.ImVec2(160, 26)) then panic_waiting = false end
			imgui.SameLine()
			imgui.TextColored(imgui.ImVec4(1.0, 0.6, 0.2, 1.0), "Ждём нажатия...")
		end
		imgui.SameLine()
		if imgui.Button("Сброс", imgui.ImVec2(80, 26)) then
			json.panic.vk = 0; saveJson()
			showPopup("Клавиша паники сброшена", "x", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		end
		HelpMark("Одна клавиша, которая мгновенно отключает все функции скрипта.")
		local cb_ul = new.bool(json.panic.unload)
		if imgui.Checkbox("Выгружать скрипт при экстренном стопе", cb_ul) then
			json.panic.unload = not json.panic.unload; saveJson()
			showPopup("Выгрузка при панике: " .. (json.panic.unload and "вкл" or "выкл"))
		end
		HelpMark("Если включено — после /panic или кнопки СТОП скрипт выгрузится из MoonLoader.")
		if imgui.Button("ВЫПОЛНИТЬ ЭКСТРЕННЫЙ СТОП СЕЙЧАС", imgui.ImVec2(-1, 34)) then
			panicStop()
		end
		imgui.TextColored(imgui.ImVec4(0.75, 0.75, 0.85, 1.0), "Из чата: /panic, /stopall, /unload")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Подсветка:")
		imgui.Separator()
		local cb1 = new.bool(json.showobj)
		if imgui.Checkbox("Показать объекты (showobj)", cb1) then
			json.showobj = not json.showobj; saveJson()
			showPopup("showobj: " .. (json.showobj and "вкл" or "выкл"))
		end
		HelpMark("id, модель и дистанция объекта.")
		local cb2 = new.bool(json.showpic)
		if imgui.Checkbox("Показать пикапы (showpic)", cb2) then
			json.showpic = not json.showpic; saveJson()
			showPopup("showpic: " .. (json.showpic and "вкл" or "выкл"))
		end
		HelpMark("id, модель и дистанция пикапов.")
		local cb3 = new.bool(json.show3d)
		if imgui.Checkbox("Показать 3D-метки (show3d)", cb3) then
			json.show3d = not json.show3d; saveJson()
			showPopup("show3d: " .. (json.show3d and "вкл" or "выкл"))
		end
		HelpMark("id и дистанция 3D-меток.")
		local cb_dlg = new.bool(json.showdialog)
		if imgui.Checkbox("CEF Monitoring (showdialog)", cb_dlg) then
			json.showdialog = not json.showdialog; saveJson()
			showPopup("CEF Monitoring: " .. (json.showdialog and "вкл" or "выкл"))
		end
		HelpMark("Перехватывает CEF-команды Radmir из packet 215/220 и показывает имя интерфейса. /showdialog")
		if cef_info.id ~= "" then
			imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.00, 1.0),
				string.format("Последний CEF: %s | %s", tostring(cef_info.id), tostring(cef_info.source)))
			imgui.SameLine()
			if imgui.Button("Копировать##cef_copy", imgui.ImVec2(100, 22)) then
				pcall(setClipboardText, tostring(cef_info.id))
				showPopup("CEF ID " .. tostring(cef_info.id) .. " скопирован", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
			end
			imgui.TextWrapped("Команда: " .. tostring(cef_info.raw))
		end
		if #cef_history > 0 then
			imgui.BeginChild("##cef_hist", imgui.ImVec2(0, 130), true)
			for i, c in ipairs(cef_history) do
				imgui.TextColored(imgui.ImVec4(0.75, 0.75, 0.90, 1.0),
					string.format("%s  %s  [%s]", c.time or "", tostring(c.id), tostring(c.source)))
				imgui.SameLine()
				if imgui.SmallButton("copy##cef" .. i) then
					pcall(setClipboardText, tostring(c.id))
					showPopup("CEF ID " .. tostring(c.id) .. " скопирован", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
				end
			end
			imgui.EndChild()
			if imgui.Button("Очистить историю CEF", imgui.ImVec2(-1, 24)) then
				cef_history = {}
				cef_info.id = ""
				cef_info.raw = ""
				showPopup("История CEF очищена", "x", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
			end
		end

		if #dialog_history > 0 then
			imgui.BeginChild("##dlg_hist", imgui.ImVec2(0, 120), true)
			for i, d in ipairs(dialog_history) do
				imgui.TextColored(imgui.ImVec4(0.75, 0.75, 0.90, 1.0),
					string.format("%s  ID %s  %s  %s",
						d.time or "",
						tostring(d.id),
						DIALOG_STYLES[d.style] or tostring(d.style),
						d.title or ""))
				imgui.SameLine()
				if imgui.SmallButton("copy##dlg" .. i) then
					pcall(setClipboardText, tostring(d.id))
					showPopup("ID " .. tostring(d.id) .. " скопирован", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
				end
			end
			imgui.EndChild()
			if imgui.Button("Очистить историю диалогов", imgui.ImVec2(-1, 24)) then
				dialog_history = {}
				dialog_info.id = -1
				dialog_info.title = ""
				showPopup("История диалогов очищена", "x", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
			end
		end
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Стиль интерфейса:")
		imgui.Separator()
		local ustyle_labels = {}
		for i, k in ipairs(UI_KEYS) do ustyle_labels[i] = UI_STYLES[k].name end
		local ustyle_const = imgui.new["const char*"][#UI_KEYS](ustyle_labels)
		local cur_us = json.ui_style or "dark"
		local us_idx = 1
		for i, k in ipairs(UI_KEYS) do if k == cur_us then us_idx = i end end
		local usel = new.int(us_idx - 1)
		if imgui.Combo("Стиль UI", usel, ustyle_const, #UI_KEYS) then
			json.ui_style = UI_KEYS[usel[0] + 1]
			saveJson()
			showPopup("Стиль UI: " .. UI_STYLES[json.ui_style].name, "+")
			setExtraTheme()
		end
		HelpMark("Меняет оформление меню — фон, границы.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Горячие клавиши:")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  Insert - меню")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  /rm - меню из чата")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  /auth - авторизация")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  /skin - скинченджер")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  /fskin ID - сменить скин")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  /showdialog - ID диалогов")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  /fk - ANTIAFK вкл/выкл")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  F4 - Lov домов")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  B + 1 - House auto")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "  C + 1 / C + 2 - CamHack")
		imgui.TextColored(imgui.ImVec4(1.0, 0.55, 0.55, 1), "  /panic - ЭКСТРЕННЫЙ СТОП")
		imgui.TextColored(imgui.ImVec4(1.0, 0.55, 0.55, 1), "  /unload - выгрузить скрипт")

	elseif mainwindow_tab[0] == 12 then
		local title = "Авторизация на сервер"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Данные для входа:")
		imgui.Separator()
		imgui.Text("Логин (ник в игре):")
		imgui.PushItemWidth(-1)
		if imgui.InputText("##auth_login_menu", auth_login_buf, ffi.sizeof(auth_login_buf)) then
			json.auth.login = ffi.string(auth_login_buf); saveJson()
		end
		imgui.PopItemWidth()
		HelpMark("Ник, под которым заходишь на сервер.")
		imgui.Text("Пароль:")
		imgui.PushItemWidth(-1)
		if auth_show_pass[0] then
			if imgui.InputText("##auth_pass_menu", auth_pass_buf, ffi.sizeof(auth_pass_buf)) then
				json.auth.password = ffi.string(auth_pass_buf); saveJson()
			end
		else
			if imgui.InputText("##auth_pass_menu", auth_pass_buf, ffi.sizeof(auth_pass_buf), imgui.InputTextFlags.Password) then
				json.auth.password = ffi.string(auth_pass_buf); saveJson()
			end
		end
		imgui.PopItemWidth()
		if imgui.Checkbox("Показать пароль", auth_show_pass) then end
		imgui.Separator()
		local cb_auth = new.bool(json.auth.enabled)
		if imgui.Checkbox("Авто-вход при подключении", cb_auth) then
			json.auth.enabled = not json.auth.enabled; saveJson()
			showPopup("Авто-вход: " .. (json.auth.enabled and "вкл" or "выкл"))
		end
		HelpMark("Если включено — пароль автоматически отправится на сервер при подключении.")
		imgui.Separator()
		if imgui.Button("Сохранить", imgui.ImVec2(-1, 30)) then
			json.auth.login = ffi.string(auth_login_buf)
			json.auth.password = ffi.string(auth_pass_buf); saveJson()
			showPopup("Сохранено", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		end
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.3, 1), "Данные хранятся в открытом виде.")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "Команда /auth открывает тоже самое окно.")

	elseif mainwindow_tab[0] == 2 then
		local title = "Ловля"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Дома:")
		imgui.Separator()
		local cb_hwh = new.bool(lovlya.house_wh)
		if imgui.Checkbox("WH домов (мод. 1273)", cb_hwh) then
			lovlya.house_wh = not lovlya.house_wh
			json.lovlya.house_wh = lovlya.house_wh; saveJson()
			showPopup("WH домов: " .. (lovlya.house_wh and "вкл" or "выкл"))
		end
		HelpMark("Подсвечивает слетевшие дома.")
		local cb_hlov = new.bool(lovlya.house_lov)
		if imgui.Checkbox("Lov домов (F4)", cb_hlov) then
			lovlya.house_lov = not lovlya.house_lov
			json.lovlya.house_lov = lovlya.house_lov; saveJson()
			showCursor(lovlya.house_lov)
			showPopup("Lov домов: " .. (lovlya.house_lov and "вкл" or "выкл"))
		end
		HelpMark("Курсор + ЛКМ по подсвеченному дому.")
		local cb_ha = new.bool(house.active)
		if imgui.Checkbox("House auto (B + 1)", cb_ha) then
			house.active = not house.active
			house.timer = os.clock() + 1
			house.timer_state = 0
			showPopup("House auto: " .. (house.active and "вкл" or "выкл"))
		end
		HelpMark("Авто-открытие дома (B+1).")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Биз / Гараж / Огород:")
		imgui.Separator()
		local cb_biz = new.bool(lovlya.biz)
		if imgui.Checkbox("Ловля бизнесов (/buybiz)", cb_biz) then
			lovlya.biz = not lovlya.biz
			json.lovlya.biz = lovlya.biz; saveJson()
			showPopup("Ловля бизнесов: " .. (lovlya.biz and "вкл" or "выкл"))
		end
		HelpMark("Сканирует 3D-тексты /buybiz.")
		local cb_garage = new.bool(lovlya.garage)
		if imgui.Checkbox("Ловля гаражей (/buygarage)", cb_garage) then
			lovlya.garage = not lovlya.garage
			json.lovlya.garage = lovlya.garage; saveJson()
			showPopup("Ловля гаражей: " .. (lovlya.garage and "вкл" or "выкл"))
		end
		HelpMark("Сканирует 3D-тексты /buygarage.")
		local cb_garden = new.bool(lovlya.garden)
		if imgui.Checkbox("Ловля огородов (/buygarden)", cb_garden) then
			lovlya.garden = not lovlya.garden
			json.lovlya.garden = lovlya.garden; saveJson()
			showPopup("Ловля огородов: " .. (lovlya.garden and "вкл" or "выкл"))
		end
		HelpMark("Сканирует 3D-тексты /buygarden.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Флуды:")
		imgui.Separator()
		local cb_fb = new.bool(lovlya.flood_biz)
		if imgui.Checkbox("Флуд /buybiz", cb_fb) then
			lovlya.flood_biz = not lovlya.flood_biz
			json.lovlya.flood_biz = lovlya.flood_biz; saveJson()
			showPopup("Флуд /buybiz: " .. (lovlya.flood_biz and "вкл" or "выкл"))
		end
		HelpMark("Постоянно отправляет /buybiz.")
		local delay_buf = new.int(json.lovlya.delay_biz or 500)
		if imgui.SliderInt("Задержка /buybiz (мс)", delay_buf, 50, 1500) then
			json.lovlya.delay_biz = delay_buf[0]; saveJson()
		end
		HelpMark("Пауза между отправками.")
		local cb_fa = new.bool(lovlya.flood_alt)
		if imgui.Checkbox("Флуд ALT+ENTER (киоски)", cb_fa) then
			lovlya.flood_alt = not lovlya.flood_alt
			json.lovlya.flood_alt = lovlya.flood_alt; saveJson()
			showPopup("Флуд ALT+ENTER: " .. (lovlya.flood_alt and "вкл" or "выкл"))
		end
		HelpMark("Спамит ALT+ENTER. Стоп - Y.")

	elseif mainwindow_tab[0] == 3 then
		local title = "Флуд"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		local cb_cf = new.bool(custom_flood.enabled)
		if imgui.Checkbox("Включить флуд", cb_cf) then
			custom_flood.enabled = not custom_flood.enabled
			json.customflood.enabled = custom_flood.enabled; saveJson()
			custom_flood.block_running = false
			custom_flood.block_current_idx = 0
			custom_flood.block_next_at = 0
			showPopup("Флуд: " .. (custom_flood.enabled and "вкл" or "выкл"),
				custom_flood.enabled and ">" or "#",
				custom_flood.enabled and imgui.ImVec4(0.35, 0.85, 0.55, 1.0) or imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		end
		HelpMark("Общий выключатель флуда.")
		imgui.SameLine()
		imgui.Text("   Режим:")
		imgui.SameLine()
		local is_single = (json.customflood.mode == "single")
		if is_single then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.35, 0.95, 1.0)) end
		if imgui.Button("Одиночное", imgui.ImVec2(130, 26)) then
			json.customflood.mode = "single"; saveJson()
			custom_flood.block_running = false
			showPopup("Режим: одиночное", "i")
		end
		if is_single then imgui.PopStyleColor() end
		imgui.SameLine()
		local is_block = (json.customflood.mode == "block")
		if is_block then imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.35, 0.95, 1.0)) end
		if imgui.Button("Блок", imgui.ImVec2(130, 26)) then
			json.customflood.mode = "block"; saveJson()
			custom_flood.block_running = false
			custom_flood.block_next_at = 0
			showPopup("Режим: блок", "i")
		end
		if is_block then imgui.PopStyleColor() end
		imgui.Separator()
		if json.customflood.mode == "single" then
			imgui.TextColored(imgui.ImVec4(0.68, 0.48, 1.0, 1.0), "> Одиночное сообщение")
			imgui.Text("Строка:")
			imgui.PushItemWidth(-1)
			local single_buf = new.char[256](json.customflood.text or "")
			if imgui.InputText("##cf_text", single_buf, ffi.sizeof(single_buf)) then
				json.customflood.text = ffi.string(single_buf); saveJson()
			end
			imgui.PopItemWidth()
			imgui.Text("Интервал (мс):")
			local interval_buf = new.int(json.customflood.interval or 1000)
			if imgui.SliderInt("##cf_int", interval_buf, 100, 10000, "%d мс") then
				json.customflood.interval = interval_buf[0]; saveJson()
			end
			if imgui.Button("0.5 сек", imgui.ImVec2(90, 0)) then json.customflood.interval = 500; saveJson() end
			imgui.SameLine()
			if imgui.Button("1 сек", imgui.ImVec2(90, 0)) then json.customflood.interval = 1000; saveJson() end
			imgui.SameLine()
			if imgui.Button("2 сек", imgui.ImVec2(90, 0)) then json.customflood.interval = 2000; saveJson() end
			imgui.SameLine()
			if imgui.Button("5 сек", imgui.ImVec2(90, 0)) then json.customflood.interval = 5000; saveJson() end
			imgui.Separator()
			imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Быстрые сообщения:")
			imgui.PushItemWidth(-140)
			imgui.InputText("##new_quick_msg", newmsg_buf, ffi.sizeof(newmsg_buf))
			imgui.PopItemWidth()
			imgui.SameLine()
			if imgui.Button("+ Добавить", imgui.ImVec2(120, 0)) then
				local msg = ffi.string(newmsg_buf)
				if msg ~= nil and msg ~= "" then
					json.customflood.quick = json.customflood.quick or {}
					table.insert(json.customflood.quick, msg); saveJson()
					for i = 0, ffi.sizeof(newmsg_buf) - 1 do newmsg_buf[i] = 0 end
					showPopup("Добавлено: " .. msg, "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
				end
			end
			json.customflood.quick = json.customflood.quick or {}
			imgui.BeginChild("##quick_msgs", imgui.ImVec2(0, 120), true)
			local to_remove = nil
			for i, msg in ipairs(json.customflood.quick) do
				if imgui.Selectable(tostring(i) .. ". " .. msg .. "##qmsg" .. i, false, 0, imgui.ImVec2(0, 22)) then
					if imgui.IsMouseClicked(1) then to_remove = i
					else
						json.customflood.text = msg; saveJson()
						showPopup("Выбрано: " .. msg, "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
					end
				end
			end
			imgui.EndChild()
			if to_remove then
				table.remove(json.customflood.quick, to_remove); saveJson()
				showPopup("Удалено", "x", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
			end
		else
			imgui.TextColored(imgui.ImVec4(0.68, 0.48, 1.0, 1.0), "> Блок сообщений")
			json.customflood.block = json.customflood.block or { messages = {}, msg_delay = 500, block_interval = 180 }
			local block = json.customflood.block
			block.messages = block.messages or {}
			imgui.Text("Добавить сообщение:")
			imgui.PushItemWidth(-140)
			imgui.InputText("##newblk_msg", newblk_buf, ffi.sizeof(newblk_buf))
			imgui.PopItemWidth()
			imgui.SameLine()
			if imgui.Button("+ Добавить", imgui.ImVec2(120, 0)) then
				local msg = ffi.string(newblk_buf)
				if msg ~= nil and msg ~= "" then
					table.insert(block.messages, msg); saveJson()
					for i = 0, ffi.sizeof(newblk_buf) - 1 do newblk_buf[i] = 0 end
					showPopup("Добавлено: " .. msg, "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
				end
			end
			imgui.Separator()
			imgui.BeginChild("##block_msgs", imgui.ImVec2(0, 130), true)
			local blk_to_remove, blk_to_up, blk_to_down = nil, nil, nil
			for i = 1, #block.messages do
				local msg = block.messages[i]
				imgui.Text(tostring(i) .. ".")
				imgui.SameLine()
				imgui.TextColored(imgui.ImVec4(0.85, 0.85, 1.0, 1.0), msg)
				imgui.SameLine(imgui.GetWindowWidth() - 140)
				if imgui.Button("^##bup" .. i, imgui.ImVec2(30, 0)) then blk_to_up = i end
				imgui.SameLine()
				if imgui.Button("v##bdown" .. i, imgui.ImVec2(30, 0)) then blk_to_down = i end
				imgui.SameLine()
				if imgui.Button("X##bdel" .. i, imgui.ImVec2(30, 0)) then blk_to_remove = i end
			end
			imgui.EndChild()
			if blk_to_remove then table.remove(block.messages, blk_to_remove); saveJson(); showPopup("Удалено", "X") end
			if blk_to_up and blk_to_up > 1 then
				block.messages[blk_to_up], block.messages[blk_to_up - 1] = block.messages[blk_to_up - 1], block.messages[blk_to_up]; saveJson()
			end
			if blk_to_down and blk_to_down < #block.messages then
				block.messages[blk_to_down], block.messages[blk_to_down + 1] = block.messages[blk_to_down + 1], block.messages[blk_to_down]; saveJson()
			end
			imgui.Separator()
			imgui.Text("КД между сообщениями блока (мс):")
			local msg_delay_buf = new.int(block.msg_delay or 500)
			if imgui.SliderInt("##blk_msg_delay", msg_delay_buf, 100, 5000, "%d мс") then block.msg_delay = msg_delay_buf[0]; saveJson() end
			imgui.Text("Интервал между блоками (сек):")
			local blk_int_buf = new.int(block.block_interval or 180)
			if imgui.SliderInt("##blk_int", blk_int_buf, 5, 900, "%d сек") then block.block_interval = blk_int_buf[0]; saveJson() end
			if imgui.Button("30 сек", imgui.ImVec2(90, 0)) then block.block_interval = 30; saveJson() end
			imgui.SameLine()
			if imgui.Button("1 мин", imgui.ImVec2(90, 0)) then block.block_interval = 60; saveJson() end
			imgui.SameLine()
			if imgui.Button("3 мин", imgui.ImVec2(90, 0)) then block.block_interval = 180; saveJson() end
			imgui.SameLine()
			if imgui.Button("5 мин", imgui.ImVec2(90, 0)) then block.block_interval = 300; saveJson() end
			imgui.Separator()
			imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), ("В блоке сейчас: %d сообщений"):format(#block.messages))
		end

	elseif mainwindow_tab[0] == 4 then
		local title = "Свалка"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		local cb_wh = new.bool(json.objwh.enabled)
		if imgui.Checkbox("Включить WH предметов", cb_wh) then
			json.objwh.enabled = not json.objwh.enabled; saveJson()
			showPopup("WH предметов: " .. (json.objwh.enabled and "вкл" or "выкл"))
		end
		HelpMark("Подсвечивает предметы с дистанцией.")
		local cb_price = new.bool(json.objwh.show_price ~= false)
		if imgui.Checkbox("Показывать цену", cb_price) then
			json.objwh.show_price = not (json.objwh.show_price ~= false); saveJson()
			showPopup("Цена в подсказке: " .. (json.objwh.show_price and "вкл" or "выкл"))
		end
		HelpMark("Показывает макс. цену предмета.")
		local size = new.int(json.objwh.sizetr or 1)
		if imgui.InputInt("Толщина трейсера", size, 0, 0) then json.objwh.sizetr = size[0]; saveJson() end
		local ctr = new.int(json.objwh.colortr or 2)
		if imgui.Combo("Цвет трейсера", ctr, wh_colors_const, #wh_colors_names) then json.objwh.colortr = ctr[0]; saveJson() end
		local ctx = new.int(json.objwh.colortx or 2)
		if imgui.Combo("Цвет текста", ctx, wh_colors_const, #wh_colors_names) then json.objwh.colortx = ctx[0]; saveJson() end
		imgui.Separator()
		if imgui.Button("Включить всё", imgui.ImVec2(120, 0)) then
			for m, _ in pairs(wh_items) do json.objwh.models[tostring(m)] = true end
			saveJson(); showPopup("Все предметы включены", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		end
		imgui.SameLine()
		if imgui.Button("Выключить всё", imgui.ImVec2(120, 0)) then
			for m, _ in pairs(wh_items) do json.objwh.models[tostring(m)] = false end
			saveJson(); showPopup("Все предметы выключены", "x", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		end
		imgui.Separator()
		imgui.BeginChild("##objwh_list", imgui.ImVec2(0, 240), true)
		imgui.Columns(2, "objwh_cols", false)
		local models_sorted = {}
		for m, _ in pairs(wh_items) do
			table.insert(models_sorted, { model = m, name = wh_items_cp[m] })
		end
		table.sort(models_sorted, function(a, b) return a.name < b.name end)
		for i, item in ipairs(models_sorted) do
			local key = tostring(item.model)
			local val = new.bool(json.objwh.models[key])
			if imgui.Checkbox(item.name .. " [" .. item.model .. "]", val) then
				json.objwh.models[key] = not json.objwh.models[key]; saveJson()
			end
			if i % 2 == 0 then imgui.NextColumn() end
		end
		imgui.Columns(1)
		imgui.EndChild()

	elseif mainwindow_tab[0] == 5 then
		local title = "Цены предметов на свалке"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "Максимальные цены продажи.")
		local list = {}
		for model, data in pairs(wh_prices_cp) do
			table.insert(list, { name = data[1], model = model, price = data[2] })
		end
		table.sort(list, function(a, b) return a.price > b.price end)
		imgui.Separator()
		imgui.BeginChild("##prices_list", imgui.ImVec2(0, 0), true)
		imgui.Columns(3, "prices_cols", true)
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Предмет")
		imgui.NextColumn()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Модель")
		imgui.NextColumn()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Макс. цена")
		imgui.NextColumn()
		imgui.Separator()
		for _, it in ipairs(list) do
			local col
			if it.price >= 100000 then col = imgui.ImVec4(1.00, 0.55, 0.10, 1.0)
			elseif it.price >= 40000 then col = imgui.ImVec4(0.85, 0.50, 1.00, 1.0)
			elseif it.price >= 15000 then col = imgui.ImVec4(0.55, 0.85, 1.00, 1.0)
			else col = imgui.ImVec4(0.75, 0.75, 0.85, 1.0) end
			imgui.TextColored(col, it.name)
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.7, 1.0), tostring(it.model))
			imgui.NextColumn()
			imgui.TextColored(col, formatPrice(it.price))
			imgui.NextColumn()
		end
		imgui.Columns(1)
		imgui.EndChild()

	elseif mainwindow_tab[0] == 14 then
		local title = "Киоск"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()

		local cb_k = new.bool(kiosk_monitor.enabled)
		if imgui.Checkbox("Парсинг предметов киоска", cb_k) then
			kiosk_monitor.enabled = not kiosk_monitor.enabled
			showPopup("Парсинг киоска: " .. (kiosk_monitor.enabled and "вкл" or "выкл"))
		end
		imgui.SameLine()
		imgui.TextColored(imgui.ImVec4(0.70, 0.70, 0.82, 1.0),
			"Пикап входа: " .. tostring(KIOSK_PICKUP_MODEL))

		kiosk_monitor.near = kioskIsNearPickup(25.0)
		if kiosk_monitor.near then
			imgui.TextColored(imgui.ImVec4(0.35, 0.95, 0.55, 1.0), "● Рядом с пикапом киоска")
		else
			imgui.TextColored(imgui.ImVec4(0.75, 0.75, 0.85, 1.0), "○ Пикап 19134 не рядом")
		end

		if imgui.Button("Очистить##kiosk") then
			kioskResetSession(true)
		end

		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0),
			"Business | Предметов: " .. tostring(#kiosk_monitor.items))
		imgui.SameLine()
		imgui.TextColored(imgui.ImVec4(0.70, 0.70, 0.82, 1.0),
			(kiosk_monitor.business_active and "● CAPTURE " or "○ WAIT ") .. tostring(kiosk_monitor.raw_count))

		if #kiosk_monitor.items > 0 then
			imgui.BeginChild("##kiosk_items", imgui.ImVec2(0, 260), true)
			imgui.Columns(4, "kiosk_cols", true)
			imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Предмет")
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "ID / модель")
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Цена")
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "Кол-во")
			imgui.NextColumn()
			imgui.Separator()
			for _, item in ipairs(kiosk_monitor.items) do
				imgui.TextWrapped(tostring(item.name or "???"))
				imgui.NextColumn()
				imgui.Text(tostring(item.model or "-"))
				imgui.NextColumn()
				imgui.Text(tostring(item.price or "-"))
				imgui.NextColumn()
				imgui.Text(tostring(item.count or "-"))
				imgui.NextColumn()
			end
			imgui.Columns(1)
			imgui.EndChild()
		else
			imgui.TextWrapped("Предметы пока не распознаны. Открой киоск у пикапа 19134. "
				.."Скрипт перехватит interface('Business') и попробует разобрать его данные.")
		end

		if kiosk_monitor.last_raw ~= "" then
			imgui.Separator()
			imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Последний сырой Business-пакет:")
			imgui.BeginChild("##kiosk_raw", imgui.ImVec2(0, 150), true)
			imgui.TextWrapped(kiosk_monitor.last_raw)
			imgui.EndChild()
		end

	elseif mainwindow_tab[0] == 13 then
		local title = "Софты"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()

		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0),
			"Дополнительные разделы. Нажми на кнопку, чтобы открыть.")
		imgui.Dummy(imgui.ImVec2(0, 30))

		local btnW = (windowWidth - 60) / 2

		imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.35, 0.20, 0.65, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55, 0.35, 0.95, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.25, 0.12, 0.45, 1.0))
		if imgui.Button("ДРУГОЕ##open_other", imgui.ImVec2(btnW, 120)) then
			showOtherWindow[0] = true
		end
		imgui.PopStyleColor(3)

		imgui.SameLine()

		imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.20, 0.45, 0.65, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.35, 0.70, 0.95, 1.0))
		imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.12, 0.30, 0.45, 1.0))
		if imgui.Button("СКИНЧЕНДЖЕР##open_skin", imgui.ImVec2(btnW, 120)) then
			showSkinChanger[0] = true
		end
		imgui.PopStyleColor(3)

		imgui.Dummy(imgui.ImVec2(0, 20))
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0),
			"ANTIAFK: " .. (antish.enabled and "ВКЛ" or "выкл"))
		imgui.SameLine()
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0),
			"   Скин: " .. tostring((json.softs and json.softs.visual_skin and json.softs.visual_skin.skinId) or 0))
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0),
			"Превью скинов найдено: " .. (skins_scanned and #available_skins or "..."))
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0),
			"Папка: " .. skins_dir)

	elseif mainwindow_tab[0] == 6 then
		local title = "Свободная камера (CamHack)"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		local cb_cam = new.bool(cam.active)
		if imgui.Checkbox("Включить CamHack", cb_cam) then
			if cam.active then camhack_disable() else camhack_enable() end
		end
		HelpMark("Отвязывает камеру от персонажа.")
		local cb_hud = new.bool(json.camhack.hide_hud)
		if imgui.Checkbox("Скрывать HUD", cb_hud) then
			json.camhack.hide_hud = not json.camhack.hide_hud; saveJson()
			showPopup("Скрытие HUD: " .. (json.camhack.hide_hud and "вкл" or "выкл"))
		end
		HelpMark("Прячет миникарту и HUD.")
		local cam_speed_buf = new.float(cam.speed)
		if imgui.SliderFloat("Скорость камеры", cam_speed_buf, 0.05, 10.0, "%.2f") then
			cam.speed = cam_speed_buf[0]; json.camhack.speed = cam.speed; saveJson()
		end
		HelpMark("Скорость движения камеры.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "C + 1 / C + 2 - вкл/выкл")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "WASD - движение, Space/Shift - вверх/вниз")
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1), "Мышь - поворот, F10 - HUD")

	elseif mainwindow_tab[0] == 7 then
		local title = "Telegram"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		local cb_tg = new.bool(json.telegram.enabled)
		if imgui.Checkbox("Включить уведомления", cb_tg) then
			json.telegram.enabled = not json.telegram.enabled; saveJson()
			showPopup("Telegram: " .. (json.telegram.enabled and "вкл" or "выкл"))
			if json.telegram.enabled then
				lua_thread.create(function() wait(200); tg.send('Уведомления включены') end)
				if json.telegram.token ~= "" and json.telegram.chat_id ~= "" then
					tg_get_last_update()
					lua_thread.create(tg_poll_updates)
				end
			end
		end
		HelpMark("Уведомления в ТГ + команды /info /chat /getplayers /poweroff")
		imgui.Separator()
		imgui.Text("Токен бота (от @BotFather):")
		local token_buf = new.char[128](json.telegram.token)
		if imgui.InputText("##tg_token", token_buf, ffi.sizeof(token_buf)) then
			json.telegram.token = ffi.string(token_buf); saveJson()
		end
		imgui.Text("Chat ID (от @userinfobot):")
		local chat_buf = new.char[64](json.telegram.chat_id)
		if imgui.InputText("##tg_chat", chat_buf, ffi.sizeof(chat_buf)) then
			json.telegram.chat_id = ffi.string(chat_buf); saveJson()
		end
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Что присылать:")
		local cb_enter = new.bool(json.telegram.notify_enter)
		if imgui.Checkbox("Вход на сервер", cb_enter) then json.telegram.notify_enter = not json.telegram.notify_enter; saveJson() end
		imgui.SameLine()
		local cb_admin = new.bool(json.telegram.notify_admin)
		if imgui.Checkbox("Сообщения админов", cb_admin) then json.telegram.notify_admin = not json.telegram.notify_admin; saveJson() end
		local cb_drop = new.bool(json.telegram.notify_drop)
		if imgui.Checkbox("Начисления", cb_drop) then json.telegram.notify_drop = not json.telegram.notify_drop; saveJson() end
		imgui.SameLine()
		local cb_buy = new.bool(json.telegram.notify_purchase)
		if imgui.Checkbox("Покупки", cb_buy) then json.telegram.notify_purchase = not json.telegram.notify_purchase; saveJson() end
		imgui.Separator()
		if imgui.Button("Проверить связь (тест)", imgui.ImVec2(-1, 0)) then
			if json.telegram.token == "" or json.telegram.chat_id == "" then
				showPopup("Заполни token и chat_id", "!", imgui.ImVec4(0.95, 0.75, 0.30, 1.0))
			else
				tg.send('Тест от Extra LV')
				showPopup("Отправлено", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
			end
		end

	elseif mainwindow_tab[0] == 10 then
		local title = "Оверлей статуса"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		json.overlay.show = json.overlay.show or {}
		local cb_ov = new.bool(json.overlay.enabled)
		if imgui.Checkbox("Показывать оверлей", cb_ov) then
			json.overlay.enabled = not json.overlay.enabled; saveJson()
			showPopup("Оверлей: " .. (json.overlay.enabled and "вкл" or "выкл"))
		end
		HelpMark("Плавающее окно с активными функциями.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Какие функции показывать:")
		imgui.Separator()
		local function ovCheck(label, key)
			local v = new.bool(json.overlay.show[key])
			if imgui.Checkbox(label, v) then
				json.overlay.show[key] = not json.overlay.show[key]; saveJson()
			end
		end
		ovCheck("WH предметов",  "objwh")
		ovCheck("WH домов",      "house_wh")
		ovCheck("Lov домов",     "house_lov")
		ovCheck("Флуд",          "flood")
		ovCheck("Telegram",      "telegram")
		ovCheck("CamHack",       "camhack")
		ovCheck("Статистика",    "stats")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Окно времени (отдельно):")
		imgui.Separator()
		local cb_t = new.bool(json.overlay.time_enabled)
		if imgui.Checkbox("Показывать время", cb_t) then
			json.overlay.time_enabled = not json.overlay.time_enabled; saveJson()
		end
		local cb_24 = new.bool(json.overlay.time_24h)
		if imgui.Checkbox("24-часовой формат", cb_24) then
			json.overlay.time_24h = not json.overlay.time_24h; saveJson()
		end
		imgui.SameLine()
		local cb_date = new.bool(json.overlay.time_show_date)
		if imgui.Checkbox("Показывать дату", cb_date) then
			json.overlay.time_show_date = not json.overlay.time_show_date; saveJson()
		end
		local tcorners = { "Правый верх", "Левый верх", "Левый низ", "Правый низ", "Снизу по центру" }
		local tcorner_labels = imgui.new["const char*"][#tcorners](tcorners)
		local tsel = new.int((json.overlay.time_corner or 5) - 1)
		if imgui.Combo("Позиция времени", tsel, tcorner_labels, #tcorners) then
			json.overlay.time_corner = tsel[0] + 1; saveJson()
		end
		local tox = new.int(json.overlay.time_offset_x or 0)
		if imgui.SliderInt("Смещение времени X", tox, -600, 600) then
			json.overlay.time_offset_x = tox[0]; saveJson()
		end
		local toy = new.int(json.overlay.time_offset_y or -20)
		if imgui.SliderInt("Смещение времени Y", toy, -600, 600) then
			json.overlay.time_offset_y = toy[0]; saveJson()
		end
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Расположение блока функций:")
		imgui.Separator()
		local corners = { "Правый верх", "Левый верх", "Левый низ", "Правый низ", "Снизу по центру" }
		local corner_labels = imgui.new["const char*"][#corners](corners)
		local corner_sel = new.int((json.overlay.corner or 1) - 1)
		if imgui.Combo("Угол экрана", corner_sel, corner_labels, #corners) then
			json.overlay.corner = corner_sel[0] + 1; saveJson()
		end
		local ox = new.int(json.overlay.offset_x or 0)
		if imgui.SliderInt("Смещение X", ox, -400, 400) then json.overlay.offset_x = ox[0]; saveJson() end
		local oy = new.int(json.overlay.offset_y or 0)
		if imgui.SliderInt("Смещение Y", oy, -400, 400) then json.overlay.offset_y = oy[0]; saveJson() end
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "Оверлей виден только когда меню закрыто.")

	elseif mainwindow_tab[0] == 11 then
		local title = "ЧС и ФПС UP"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Чёрный список (ники):")
		HelpMark("Игроки из ЧС удаляются из зоны стрима, их сообщения скрываются в чате.")
		imgui.PushItemWidth(-140)
		imgui.InputText("##newchs_msg", newchs_buf, ffi.sizeof(newchs_buf))
		imgui.PopItemWidth()
		imgui.SameLine()
		if imgui.Button("+ Добавить", imgui.ImVec2(120, 0)) then
			local nick = ffi.string(newchs_buf)
			if nick ~= nil and nick ~= "" then
				json.chs = json.chs or { list = {} }
				json.chs.list = json.chs.list or {}
				table.insert(json.chs.list, nick)
				saveJson()
				for i = 0, ffi.sizeof(newchs_buf) - 1 do newchs_buf[i] = 0 end
				showPopup("Добавлен в ЧС: " .. nick, "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
			end
		end
		json.chs = json.chs or { list = {} }
		json.chs.list = json.chs.list or {}
		imgui.BeginChild("##chs_list", imgui.ImVec2(0, 150), true)
		local to_remove = nil
		for i, nick in ipairs(json.chs.list) do
			imgui.Text(tostring(i) .. ".")
			imgui.SameLine()
			imgui.TextColored(imgui.ImVec4(0.85, 0.85, 1.0, 1.0), nick)
			imgui.SameLine(imgui.GetWindowWidth() - 40)
			if imgui.Button("X##chs" .. i, imgui.ImVec2(30, 0)) then to_remove = i end
		end
		imgui.EndChild()
		if to_remove then
			table.remove(json.chs.list, to_remove); saveJson()
			showPopup("Удалено из ЧС", "x", imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
		end
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "Фильтр чата:")
		imgui.Separator()
		local cb_fb = new.bool(json.chs and json.chs.filter_football or false)
		if imgui.Checkbox("Убирать [FOOTBALL] из чата", cb_fb) then
			json.chs = json.chs or {}
			json.chs.filter_football = not (json.chs.filter_football or false)
			saveJson()
			showPopup("Фильтр FOOTBALL: " .. (json.chs.filter_football and "вкл" or "выкл"))
		end
		HelpMark("Скрывает сообщения с триггером [FOOTBALL].")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0), "ФПС UP:")
		imgui.Separator()
		if imgui.Button("Удалить всех игроков", imgui.ImVec2(-1, 30)) then
			local myid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
			for id = 0, 2048 do
				if sampIsPlayerConnected(id) and id ~= myid then
					local bs = raknetNewBitStream()
					raknetBitStreamWriteInt16(bs, id)
					raknetEmulRpcReceiveBitStream(163, bs)
					raknetDeleteBitStream(bs)
				end
			end
			showPopup("Игроки удалены", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		end
		if imgui.Button("Удалить все машины", imgui.ImVec2(-1, 30)) then
			for _, veh in pairs(getAllVehicles()) do
				local ok, id = sampGetVehicleIdByCarHandle(veh)
				if ok and veh ~= 1 then
					local bs = raknetNewBitStream()
					raknetBitStreamWriteInt16(bs, id)
					raknetEmulRpcReceiveBitStream(165, bs)
					raknetDeleteBitStream(bs)
				end
			end
			showPopup("Машины удалены", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		end

	elseif mainwindow_tab[0] == 8 then
		local title = "Справка"
		imgui.SetCursorPosX((windowWidth - imgui.CalcTextSize(title).x) / 2)
		imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), title)
		imgui.Separator()
		imgui.BeginChild("##help_scroll", imgui.ImVec2(0, 0), true)
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Настройки")
		imgui.TextWrapped("Подсветка, ID диалогов (/showdialog), стиль, хоткеи, клавиша экстренного стопа.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Авторизация")
		imgui.TextWrapped("Логин / пароль для авто-входа на сервер.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Ловля")
		imgui.TextWrapped("WH/Lov домов, бизнесы, гаражи, огороды, флуд.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Флуд")
		imgui.TextWrapped("Одиночное или блоком с интервалом.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Свалка")
		imgui.TextWrapped("WallHack предметов + цены.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Цены")
		imgui.TextWrapped("Максимальные цены.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Софты")
		imgui.TextWrapped("Две кнопки: 'Другое' (ANTIAFK) и 'Скинченджер'.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Камера")
		imgui.TextWrapped("CamHack, свободная камера.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> Telegram")
		imgui.TextWrapped("Уведомления в ТГ.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0), "> ЧС / ФПС UP")
		imgui.TextWrapped("Чёрный список игроков + удаление из стрима.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(1.00, 0.35, 0.35, 1.0), "> ЭКСТРЕННЫЙ СТОП")
		imgui.TextWrapped("Отключает ВСЁ и выгружает скрипт. Из чата - /panic, /stopall, /unload.")
		imgui.Separator()
		imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.3, 1.0), "Меню - /rm или Insert")
		imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.3, 1.0), "Скинченджер - /skin")
		imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.3, 1.0), "ANTIAFK - /fk")
		imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.3, 1.0), "Экстренный стоп - /panic")
		imgui.EndChild()
	end
end

imgui.OnFrame(function() return MainWindow[0] end, function(player)
	player.HideCursor = false
	local resX, resY = getScreenResolution()
	local posX = (json.window and json.window.x or -1)
	local posY = (json.window and json.window.y or -1)
	if posX < 0 then posX = resX / 2 - MENU_W / 2 end
	if posY < 0 then posY = resY / 2 - MENU_H / 2 end
	local clean = isCleanStyle()

	imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
	imgui.SetNextWindowSize(imgui.ImVec2(MENU_W, MENU_H), imgui.Cond.Always)
	imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, clean and 0.0 or 18.0)
	imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, clean and 0.0 or 2.0)
	imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, clean and imgui.ImVec2(6, 4) or imgui.ImVec2(16, 14))
	if not clean then
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.05, 0.03, 0.10, 0.99))
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.55, 0.35, 0.95, 0.55))
	end
	imgui.Begin("Extra LV | by HISSOKASHOP | v.11.9", MainWindow,
		imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

	imgui.SetCursorPos(imgui.ImVec2(0, 0))
	imgui.InvisibleButton("##drag_titlebar", imgui.ImVec2(MENU_W - 90, 55))
	if imgui.IsItemActive() and imgui.IsMouseDragging(0) then
		local mx, my = imgui.GetMousePos()
		if not drag_data.active then
			local wp0 = imgui.GetWindowPos()
			drag_data.offsetX = mx - wp0.x
			drag_data.offsetY = my - wp0.y
			drag_data.active = true
		end
		json.window.x = mx - drag_data.offsetX
		json.window.y = my - drag_data.offsetY
	end
	if not imgui.IsMouseDown(0) and drag_data.active then
		drag_data.active = false
		saveJson()
	end

	local dl = imgui.GetWindowDrawList()
	local wp = imgui.GetWindowPos()
	local ww, wh = MENU_W, MENU_H

	imgui.SetCursorPos(imgui.ImVec2(20, 14))
	imgui.PushFont(font_wh)
	imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.00, 1.0), "Extra LV")
	imgui.PopFont()
	imgui.SameLine()
	imgui.TextColored(imgui.ImVec4(0.75, 0.75, 0.90, 1.0), "  by HISSOKASHOP  -  v.11.9")
	imgui.SameLine()
	imgui.SetCursorPosX(ww - 540)

	local statuses = {
		{ name = "WH об.",   active = json.showobj,          color = imgui.ImVec4(0.30, 0.85, 0.55, 1) },
		{ name = "WH дом.",  active = lovlya.house_wh,       color = imgui.ImVec4(0.55, 0.85, 1.00, 1) },
		{ name = "Lov",      active = lovlya.house_lov,      color = imgui.ImVec4(1.00, 0.65, 0.30, 1) },
		{ name = "Флуд",     active = custom_flood.enabled,  color = imgui.ImVec4(1.00, 0.40, 0.55, 1) },
		{ name = "AFK",      active = antish.enabled,        color = imgui.ImVec4(0.55, 1.00, 0.55, 1) }
	}
	for _, s in ipairs(statuses) do
		local col = s.active and s.color or imgui.ImVec4(0.35, 0.35, 0.45, 1)
		local bg  = s.active and imgui.ImVec4(s.color.x * 0.35, s.color.y * 0.35, s.color.z * 0.35, 0.55)
		          or imgui.ImVec4(0.15, 0.15, 0.22, 0.55)
		local pos = imgui.GetCursorScreenPos()
		local w = 82
		if not clean then
			dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y), imgui.ImVec2(pos.x + w, pos.y + 22), imgui.ColorConvertFloat4ToU32(bg), 6)
			if s.active then
				dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y), imgui.ImVec2(pos.x + 3, pos.y + 22), imgui.ColorConvertFloat4ToU32(col), 6)
			end
		end
		imgui.SetCursorPosX(imgui.GetCursorPosX() + 6)
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 3)
		imgui.TextColored(col, s.name)
		imgui.SameLine()
		imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
	end

	imgui.SameLine()
	imgui.SetCursorPosX(ww - 200)
	imgui.SetCursorPosY(14)
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.70, 0.10, 0.10, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.95, 0.20, 0.20, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.55, 0.05, 0.05, 1.0))
	if imgui.Button("PANIC  СТОП", imgui.ImVec2(110, 24)) then panicStop() end
	imgui.PopStyleColor(3)

	imgui.SameLine()
	imgui.SetCursorPosX(ww - 80)
	imgui.SetCursorPosY(18)
	imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.00, 1.0), os.date("%H:%M:%S"))

	if not clean then
		dl:AddLine(imgui.ImVec2(wp.x + 15, wp.y + 55), imgui.ImVec2(wp.x + ww - 15, wp.y + 55), rgba(0.55, 0.35, 0.95, 0.35), 1.5)
	end

	imgui.SetCursorPos(imgui.ImVec2(15, 70))

	if not clean then
		imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.08, 0.05, 0.13, 0.35))
	end
	imgui.BeginChild("##side_menu", imgui.ImVec2(SIDE_W - 15, wh - 85), true)
	for _, item in ipairs(SIDEBAR_ITEMS) do
		local is_active = (mainwindow_tab[0] == item.id)
		local pos = imgui.GetCursorScreenPos()
		local itemW, itemH = SIDE_W - 40, 38
		if is_active and not clean then
			dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y + 3), imgui.ImVec2(pos.x + 4, pos.y + itemH - 3), rgba(0.55, 0.35, 0.95, 1.0), 2)
			dl:AddRectFilled(imgui.ImVec2(pos.x, pos.y), imgui.ImVec2(pos.x + itemW, pos.y + itemH), rgba(0.55, 0.35, 0.95, 0.22), 8)
		end
		imgui.PushStyleColor(imgui.Col.Header, is_active and imgui.ImVec4(0.55, 0.35, 0.95, 0.0) or imgui.ImVec4(0.20, 0.15, 0.30, 0.35))
		imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(0.28, 0.20, 0.42, 0.55))
		imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(0.35, 0.25, 0.55, 0.75))
		if imgui.Selectable("  " .. item.icon .. "  " .. item.name .. "##nav" .. item.id, is_active, 0, imgui.ImVec2(itemW, itemH)) then
			mainwindow_tab[0] = item.id
			alpha_main[0] = os.clock()
		end
		imgui.PopStyleColor(3)
		imgui.Spacing()
	end

	imgui.Spacing()
	imgui.Separator()
	imgui.Spacing()
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.70, 0.10, 0.10, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.95, 0.20, 0.20, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.55, 0.05, 0.05, 1.0))
	if imgui.Button("!!!  ЭКСТРЕННЫЙ СТОП  !!!", imgui.ImVec2(SIDE_W - 40, 40)) then panicStop() end
	imgui.PopStyleColor(3)
	imgui.TextColored(imgui.ImVec4(1.0, 0.55, 0.55, 1.0), "  Клавиша: " .. vkName(json.panic.vk))
	imgui.EndChild()
	if not clean then imgui.PopStyleColor() end

	imgui.SameLine()

	if not clean then
		imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0.08, 0.05, 0.13, 0.35))
	end
	imgui.BeginChild("##content", imgui.ImVec2(0, wh - 85), true)
	drawContent()
	imgui.EndChild()
	if not clean then imgui.PopStyleColor() end

	imgui.End()
	if not clean then imgui.PopStyleColor(2) end
	imgui.PopStyleVar(3)
end)

imgui.OnFrame(function() return showOtherWindow[0] end, function(player)
	player.HideCursor = false
	local resX, resY = getScreenResolution()
	local winW, winH = 560, 420
	imgui.SetNextWindowPos(imgui.ImVec2(resX/2 - winW/2, resY/2 - winH/2), imgui.Cond.Always)
	imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
	imgui.Begin("Другое | Extra LV", showOtherWindow,
		imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

	imgui.TextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), "ANTIAFK")
	imgui.Separator()

	imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0),
		"Объединяет антиштраф и анти-АФК в один режим:")
	imgui.BulletText("Блокирует отправку OnPlayerDeviceLost (АФК-детект)")
	imgui.BulletText("Блокирует OnPlayerEnterArea / OnPlayerLeaveArea в машине")
	imgui.Separator()

	local cb = new.bool(antish.enabled)
	if imgui.Checkbox("Включить ANTIAFK##other", cb) then
		antish.enabled = not antish.enabled
		json.antish.enabled = antish.enabled; saveJson()
		showPopup("ANTIAFK: " .. (antish.enabled and "вкл" or "выкл"),
			antish.enabled and ">" or "#",
			antish.enabled and imgui.ImVec4(0.35, 0.85, 0.55, 1.0) or imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
	end
	HelpMark("Одна кнопка — и антиштраф, и анти-АФК работают одновременно.")

	imgui.Dummy(imgui.ImVec2(0, 20))
	imgui.SetCursorPosX((imgui.GetWindowWidth() - 400) / 2)
	imgui.PushStyleColor(imgui.Col.Button,        antish.enabled and imgui.ImVec4(0.15, 0.55, 0.25, 1.0) or imgui.ImVec4(0.35, 0.20, 0.65, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, antish.enabled and imgui.ImVec4(0.25, 0.85, 0.40, 1.0) or imgui.ImVec4(0.55, 0.35, 0.95, 1.0))
	imgui.PushStyleColor(imgui.Col.ButtonActive,  antish.enabled and imgui.ImVec4(0.10, 0.40, 0.18, 1.0) or imgui.ImVec4(0.25, 0.12, 0.45, 1.0))
	if imgui.Button(antish.enabled and "ANTIAFK: ВКЛЮЧЁН" or "ВКЛЮЧИТЬ ANTIAFK", imgui.ImVec2(400, 70)) then
		antish.enabled = not antish.enabled
		json.antish.enabled = antish.enabled; saveJson()
		showPopup("ANTIAFK: " .. (antish.enabled and "вкл" or "выкл"),
			antish.enabled and ">" or "#",
			antish.enabled and imgui.ImVec4(0.35, 0.85, 0.55, 1.0) or imgui.ImVec4(0.85, 0.35, 0.35, 1.0))
	end
	imgui.PopStyleColor(3)

	imgui.Dummy(imgui.ImVec2(0, 20))
	imgui.Separator()
	imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "Состояние: ")
	imgui.SameLine()
	imgui.TextColored(antish.enabled and imgui.ImVec4(0.35, 0.95, 0.55, 1.0) or imgui.ImVec4(0.55, 0.55, 0.65, 1.0),
		antish.enabled and "АКТИВЕН" or "выключен")
	imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "Команда из чата: /fk")

	imgui.End()
end)

imgui.OnFrame(function() return showSkinChanger[0] end, function(player)
	player.HideCursor = false
	local resX, resY = getScreenResolution()
	local winW, winH = math.min(1000, resX - 80), math.min(680, resY - 80)
	imgui.SetNextWindowPos(imgui.ImVec2(resX/2 - winW/2, resY/2 - winH/2), imgui.Cond.Always)
	imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
	imgui.Begin("Скинченджер | Extra LV", showSkinChanger,
		imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

	json.softs = json.softs or {}
	json.softs.visual_skin = json.softs.visual_skin or { enabled = false, skinId = 0 }
	local vs = json.softs.visual_skin

	imgui.TextColored(imgui.ImVec4(0.85, 0.75, 1.0, 1.0),
		"Клик по превью — применить скин. Либо введи ID вручную.")
	imgui.SameLine()
	imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0),
		"   Текущий: " .. tostring(vs.skinId or 0)
		.. (vs.enabled and " (активно)" or " (выкл)"))

	imgui.Separator()

	imgui.TextColored(imgui.ImVec4(0.55, 0.85, 1.0, 1.0),
		"Ручной ввод ID скина (0 – " .. MAX_SKIN_ID .. "):")
	imgui.PushItemWidth(140)
	imgui.InputText("##skin_id_manual", skin_buf, ffi.sizeof(skin_buf))
	imgui.PopItemWidth()
	imgui.SameLine()
	if imgui.Button("Применить ID", imgui.ImVec2(140, 0)) then
		local v = tonumber(ffi.string(skin_buf))
		if v and v >= 0 and v <= MAX_SKIN_ID then
			applySkinById(v)
		else
			showPopup("ID должен быть 0–" .. MAX_SKIN_ID, "!",
				imgui.ImVec4(0.95, 0.45, 0.30, 1.0))
		end
	end
	imgui.SameLine()
	if imgui.Button("Сброс скина", imgui.ImVec2(140, 0)) then
		vs.enabled = false
		json.softs.visual_skin.skinId = 0
		saveJson()
		restoreVisualSkin()
		showPopup("Скин возвращён", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
	end
	HelpMark("Работает даже если для ID нет картинки — просто вбей число и нажми «Применить ID».")

	imgui.Separator()

	imgui.Text("Фильтр по ID:")
	imgui.SameLine()
	imgui.PushItemWidth(120)
	imgui.InputText("##skin_search", skin_search_buf, ffi.sizeof(skin_search_buf))
	imgui.PopItemWidth()

	local filter_str = ffi.string(skin_search_buf)
	local filter_id  = tonumber(filter_str)

	imgui.SameLine()
	if imgui.Button("Показать все") then
		for i = 0, ffi.sizeof(skin_search_buf) - 1 do skin_search_buf[i] = 0 end
		filter_id = nil
	end

	imgui.SameLine()
	if imgui.Button("Обновить список") then
		skin_textures = {}
		skins_scanned = false
		scanSkinsFolder()
	end

	imgui.SameLine()
	imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0),
		skins_scanned and ("Найдено картинок: " .. #available_skins) or "Сканируется...")

	imgui.Separator()

	if skins_scanned and #available_skins == 0 then
		imgui.TextColored(imgui.ImVec4(1.0, 0.55, 0.35, 1.0),
			"В папке skins не найдено ни одной картинки *.png.")
		imgui.TextWrapped("Положи картинки в: " .. skins_dir)
		imgui.TextWrapped("Названия файлов — по ID скина, например 17038.png.")
		imgui.TextWrapped("Либо вбей ID в поле выше и нажми «Применить ID».")
	else
		local PREVIEW = 72
		local CELL_W  = PREVIEW + 14
		local cols = math.floor((imgui.GetWindowWidth() - 30) / CELL_W)
		if cols < 1 then cols = 1 end

		imgui.BeginChild("##skin_grid", imgui.ImVec2(0, 0), true)
		imgui.Columns(cols, "skincols", false)

		local drawn = 0
		for _, id in ipairs(available_skins) do
			if not filter_id or id == filter_id then
				local tex = getSkinTexture(id)
				local uid = "##skin_" .. id
				imgui.BeginGroup()
				if tex then
					if imgui.ImageButton(tex, imgui.ImVec2(PREVIEW, PREVIEW),
					                     imgui.ImVec2(0,0), imgui.ImVec2(1,1),
					                     -1, imgui.ImVec4(0,0,0,0),
					                     imgui.ImVec4(1,1,1,1)) then
						applySkinById(id)
					end
				else
					if imgui.Button("нет\nпревью" .. uid, imgui.ImVec2(PREVIEW, PREVIEW)) then
						applySkinById(id)
					end
				end
				local lbl = "ID " .. id
				local lsz = imgui.CalcTextSize(lbl).x
				imgui.SetCursorPosX(imgui.GetCursorPosX() + (PREVIEW - lsz)/2)
				imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.9, 1.0), lbl)
				imgui.EndGroup()
				imgui.NextColumn()
				drawn = drawn + 1
				if drawn >= 800 then break end
			end
		end

		imgui.Columns(1)
		imgui.EndChild()
	end

	imgui.End()
end)

local OVERLAY_W = 190
local OVERLAY_MARGIN = 20

local function getOverlayPos(resX, resY, corner, ox, oy, winW, winH)
	if corner == 1 then
		return resX - winW - OVERLAY_MARGIN + ox, OVERLAY_MARGIN + oy
	elseif corner == 2 then
		return OVERLAY_MARGIN + ox, OVERLAY_MARGIN + oy
	elseif corner == 3 then
		return OVERLAY_MARGIN + ox, resY - winH - OVERLAY_MARGIN + oy
	elseif corner == 4 then
		return resX - winW - OVERLAY_MARGIN + ox, resY - winH - OVERLAY_MARGIN + oy
	else
		return (resX - winW) / 2 + ox, resY - winH - OVERLAY_MARGIN + oy
	end
end

imgui.OnFrame(
	function() return json.overlay.enabled and isSampAvailable() and not MainWindow[0] end,
	function(player)
		player.HideCursor = true
		local resX, resY = getScreenResolution()
		local ov = json.overlay
		local px, py = getOverlayPos(resX, resY, ov.corner or 1, ov.offset_x or 0, ov.offset_y or 0, OVERLAY_W, 0)
		imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(OVERLAY_W, 0), imgui.Cond.Always)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.05, 0.05, 0.09, 0.70))
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.55, 0.35, 0.95, 0.45))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 10.0)
		imgui.Begin("##status_overlay", nil,
			imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
			imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar +
			imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoFocusOnAppearing)
		imgui.TextColored(imgui.ImVec4(0.80, 0.65, 1.00, 1.0), "Extra LV — статус")
		imgui.Separator()
		local show_ov = ov.show or {}
		local function S(name, active)
			local col = active and imgui.ImVec4(0.35, 0.95, 0.55, 1.0) or imgui.ImVec4(0.35, 0.35, 0.45, 1.0)
			imgui.TextColored(col, (active and "  [+]  " or "  [-]  ") .. name)
		end
		if show_ov.objwh     then S("WH предметов", json.objwh.enabled) end
		if show_ov.house_wh  then S("WH домов",      lovlya.house_wh) end
		if show_ov.house_lov then S("Lov домов",     lovlya.house_lov) end
		if show_ov.flood     then S("Флуд",          custom_flood.enabled) end
		if show_ov.telegram  then S("Telegram",      json.telegram.enabled) end
		if show_ov.camhack   then S("CamHack",       cam.active) end
		S("ANTIAFK", antish.enabled)
		if show_ov.stats then
			imgui.Separator()
			imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "  Домов: "    .. (json.stats.pickups_total or 0))
			imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "  Биз: "      .. (json.stats.biz_total or 0))
			imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "  Гаражей: "  .. (json.stats.garage_total or 0))
			imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.85, 1.0), "  Огородов: " .. (json.stats.garden_total or 0))
		end
		imgui.End()
		imgui.PopStyleVar()
		imgui.PopStyleColor(2)
	end
)

imgui.OnFrame(
	function() return json.overlay.enabled and json.overlay.time_enabled
	                 and isSampAvailable() and not MainWindow[0] end,
	function(player)
		player.HideCursor = true
		local resX, resY = getScreenResolution()
		local ov = json.overlay
		local fmt = ov.time_24h and "%H:%M:%S" or "%I:%M:%S %p"
		if ov.time_show_date then fmt = "%d.%m.%Y  " .. fmt end
		local timeStr = os.date(fmt)
		local winW = 130
		local px, py = getOverlayPos(resX, resY, ov.time_corner or 5,
		                             ov.time_offset_x or 0, ov.time_offset_y or -20, winW, 0)
		imgui.SetNextWindowPos(imgui.ImVec2(px, py), imgui.Cond.Always)
		imgui.SetNextWindowSize(imgui.ImVec2(winW, 0), imgui.Cond.Always)
		imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.05, 0.05, 0.09, 0.70))
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(0.55, 0.35, 0.95, 0.45))
		imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 10.0)
		imgui.Begin("##time_overlay", nil,
			imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
			imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar +
			imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoFocusOnAppearing)
		imgui.CenterTextColored(imgui.ImVec4(0.80, 0.65, 1.00, 1.0), timeStr)
		imgui.End()
		imgui.PopStyleVar()
		imgui.PopStyleColor(2)
	end
)

imgui.OnFrame(function() return showAuthWindow[0] end, function(self)
	local resX, resY = getScreenResolution()
	local winW, winH = 420, 340
	imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - winW / 2, resY / 2 - winH / 2), imgui.Cond.Always)
	imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.Always)
	imgui.Begin('Авторизация | Extra LV', showAuthWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
	imgui.CenterTextColored(imgui.ImVec4(0.55, 0.35, 0.95, 1), "Extra LV | by HISSOKASHOP")
	imgui.Separator()
	imgui.Text("Логин (ник в игре):")
	imgui.PushItemWidth(-1)
	if imgui.InputText("##auth_login_win", auth_login_buf, ffi.sizeof(auth_login_buf)) then
		json.auth.login = ffi.string(auth_login_buf); saveJson()
	end
	imgui.PopItemWidth()
	imgui.Text("Пароль:")
	imgui.PushItemWidth(-1)
	if auth_show_pass[0] then
		if imgui.InputText("##auth_pass_win", auth_pass_buf, ffi.sizeof(auth_pass_buf)) then
			json.auth.password = ffi.string(auth_pass_buf); saveJson()
		end
	else
		if imgui.InputText("##auth_pass_win", auth_pass_buf, ffi.sizeof(auth_pass_buf), imgui.InputTextFlags.Password) then
			json.auth.password = ffi.string(auth_pass_buf); saveJson()
		end
	end
	imgui.PopItemWidth()
	if imgui.Checkbox("Показать пароль", auth_show_pass) then end
	imgui.Separator()
	local cb_auth = new.bool(json.auth.enabled)
	if imgui.Checkbox("Авто-вход при подключении", cb_auth) then
		json.auth.enabled = not json.auth.enabled; saveJson()
		showPopup("Авто-вход: " .. (json.auth.enabled and "вкл" or "выкл"))
	end
	imgui.TextColored(imgui.ImVec4(0.9, 0.5, 0.3, 1), "Данные хранятся в открытом виде.")
	imgui.Dummy(imgui.ImVec2(0, 10))
	imgui.SetCursorPosX((imgui.GetWindowWidth() - 240) / 2)
	if imgui.Button("Сохранить", imgui.ImVec2(110, 0)) then
		json.auth.login = ffi.string(auth_login_buf)
		json.auth.password = ffi.string(auth_pass_buf); saveJson()
		showPopup("Сохранено", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
	end
	imgui.SameLine()
	if imgui.Button("Закрыть", imgui.ImVec2(110, 0)) then showAuthWindow[0] = false end
	imgui.End()
end)

imgui.OnFrame(function() return show[0] end, function(self)
	self.HideCursor = true
	local elapsed = os.clock() - popupStart
	local alpha, posY
	local yOffset = 30
	local resX, resY = getScreenResolution()
	if elapsed < 0.35 then
		local tt = elapsed / 0.35
		alpha = tt; posY = resY - popupHeight - yOffset + (1 - tt) * 40
	elseif elapsed < 3.2 then
		alpha = 1.0; posY = resY - popupHeight - yOffset
	elseif elapsed < 3.55 then
		local tt = (elapsed - 3.2) / 0.35
		alpha = 1.0 - tt; posY = resY - popupHeight - yOffset + tt * 40
	else
		show[0] = false; return
	end
	local acc = popupAccent or imgui.ImVec4(0.55, 0.35, 0.95, 1.0)
	imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 14.0)
	imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
	imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
	imgui.SetNextWindowPos(imgui.ImVec2((resX - popupWidth) / 2, posY), imgui.Cond.Always)
	imgui.SetNextWindowSize(imgui.ImVec2(popupWidth, popupHeight), imgui.Cond.Always)
	imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.08, 0.13, 0.97 * alpha))
	imgui.Begin('##popup', show,
		imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize +
		imgui.WindowFlags.NoMove + imgui.WindowFlags.NoSavedSettings +
		imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.NoNav +
		imgui.WindowFlags.NoInputs + imgui.WindowFlags.NoScrollbar)
	local dl = imgui.GetWindowDrawList()
	local wp = imgui.GetWindowPos()
	local w, h = popupWidth, popupHeight
	dl:AddRectFilledMultiColor(
		imgui.ImVec2(wp.x, wp.y), imgui.ImVec2(wp.x + w, wp.y + h),
		rgba(0.10, 0.10, 0.16, alpha), rgba(0.13, 0.10, 0.20, alpha),
		rgba(0.13, 0.10, 0.20, alpha), rgba(0.10, 0.10, 0.16, alpha))
	dl:AddRectFilled(imgui.ImVec2(wp.x, wp.y), imgui.ImVec2(wp.x + 4, wp.y + h), rgba(acc.x, acc.y, acc.z, alpha))
	local iconCX = wp.x + 34
	local iconCY = wp.y + h / 2
	dl:AddCircleFilled(imgui.ImVec2(iconCX, iconCY), 16, rgba(acc.x, acc.y, acc.z, 0.25 * alpha), 32)
	dl:AddCircle(imgui.ImVec2(iconCX, iconCY), 16, rgba(acc.x, acc.y, acc.z, 0.9 * alpha), 32, 1.5)
	imgui.SetCursorPos(imgui.ImVec2(60, 10))
	imgui.TextColored(imgui.ImVec4(acc.x, acc.y, acc.z, alpha), "Extra LV | HISSOKASHOP")
	imgui.SetCursorPos(imgui.ImVec2(60, 32))
	imgui.TextColored(imgui.ImVec4(0.95, 0.96, 1.0, alpha), popupText)
	local tsz = imgui.CalcTextSize(popupIcon)
	dl:AddText(imgui.ImVec2(iconCX - tsz.x / 2, iconCY - tsz.y / 2), rgba(0.95, 0.96, 1.0, alpha), popupIcon)
	imgui.End()
	imgui.PopStyleColor()
	imgui.PopStyleVar(3)
end)

function events.onSendCommand(text)
	if text == '/showobj' then json.showobj = not json.showobj; saveJson(); showPopup("showobj: "..(json.showobj and "вкл" or "выкл")); return false end
	if text == '/showpic' then json.showpic = not json.showpic; saveJson(); showPopup("showpic: "..(json.showpic and "вкл" or "выкл")); return false end
	if text == '/show3d' then json.show3d = not json.show3d; saveJson(); showPopup("show3d: "..(json.show3d and "вкл" or "выкл")); return false end
	if text == '/showdialog' then json.showdialog = not json.showdialog; saveJson(); showPopup("ID диалогов: "..(json.showdialog and "вкл" or "выкл")); return false end
	if text == '/objwh' then json.objwh.enabled = not json.objwh.enabled; saveJson(); showPopup("WH предметов: "..(json.objwh.enabled and "вкл" or "выкл")); return false end
	if text == '/housewh' then lovlya.house_wh = not lovlya.house_wh; json.lovlya.house_wh = lovlya.house_wh; saveJson(); showPopup("WH домов: "..(lovlya.house_wh and "вкл" or "выкл")); return false end
	if text == '/bizwh' then lovlya.biz = not lovlya.biz; json.lovlya.biz = lovlya.biz; saveJson(); showPopup("Ловля бизнесов: "..(lovlya.biz and "вкл" or "выкл")); return false end
	if text == '/garagewh' then lovlya.garage = not lovlya.garage; json.lovlya.garage = lovlya.garage; saveJson(); showPopup("Ловля гаражей: "..(lovlya.garage and "вкл" or "выкл")); return false end
	if text == '/gardenwh' then lovlya.garden = not lovlya.garden; json.lovlya.garden = lovlya.garden; saveJson(); showPopup("Ловля огородов: "..(lovlya.garden and "вкл" or "выкл")); return false end
	if text == '/floodalt' then lovlya.flood_alt = not lovlya.flood_alt; json.lovlya.flood_alt = lovlya.flood_alt; saveJson(); showPopup("Флуд ALT+ENTER: "..(lovlya.flood_alt and "вкл" or "выкл")); return false end
	if text == '/floodbiz' then lovlya.flood_biz = not lovlya.flood_biz; json.lovlya.flood_biz = lovlya.flood_biz; saveJson(); showPopup("Флуд /buybiz: "..(lovlya.flood_biz and "вкл" or "выкл")); return false end
	if text == '/cflood' then
		custom_flood.enabled = not custom_flood.enabled
		json.customflood.enabled = custom_flood.enabled; saveJson()
		custom_flood.block_running = false
		custom_flood.block_next_at = 0
		showPopup("Флуд: "..(custom_flood.enabled and "вкл" or "выкл"))
		return false
	end
	if text == '/panic' or text == '/stopall' then panicStop(); return false end
end

function events.onServerMessage(color, text)
	if json.chs and json.chs.filter_football then
		if text:find("[FOOTBALL]", 1, true) then return false end
	end
	if json.chs and json.chs.list then
		for _, nick in ipairs(json.chs.list) do
			if text:find(nick, 1, true) then return false end
		end
	end
	local cleanText = srv(text):gsub("{.-}", "")
	if cleanText:find(t("недостаточно денег")) or cleanText:find(t("Недостаточно денег")) then
		house_purchase_failed = true
	end
	if cleanText:find(t("Вы купили бизнес")) then
		json.stats.biz_total = (json.stats.biz_total or 0) + 1; saveJson()
		showPopup("Бизнес куплен!", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		if json.telegram.enabled and json.telegram.notify_purchase then
			tg.send('Куплен бизнес. Всего: '..(json.stats.biz_total or 0))
		end
	end
	if cleanText:find(t("Вы купили гараж")) then
		json.stats.garage_total = (json.stats.garage_total or 0) + 1; saveJson()
		showPopup("Гараж куплен!", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		if json.telegram.enabled and json.telegram.notify_purchase then
			tg.send('Куплен гараж. Всего: '..(json.stats.garage_total or 0))
		end
	end
	if cleanText:find(t("Вы купили огород")) then
		json.stats.garden_total = (json.stats.garden_total or 0) + 1; saveJson()
		showPopup("Огород куплен!", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
		if json.telegram.enabled and json.telegram.notify_purchase then
			tg.send('Куплен огород. Всего: '..(json.stats.garden_total or 0))
		end
	end
	if json.telegram.enabled then
		if json.telegram.notify_admin and ((cleanText:find(t("Администратор")) and cleanText:find(":") and tg.nickname ~= "" and cleanText:find(tg.nickname)) or cleanText:find("%[A%]")) then
			tg.send('Написал админ: '..text)
		end
		if json.telegram.notify_drop and cleanText:find(t("Вы успешно получили")) then
			tg.send('Тебе упало: '..text)
		end
	end
end

function events.onDisplayGameText(style, time, text)
	local cleanText = srv(text):gsub("{.-}", "")
	if cleanText:find(t("недостаточно денег")) or cleanText:find(t("Недостаточно денег")) then
		house_purchase_failed = true
	end
end

function events.onShowDialog(dialogId, style, title, button1, button2, text)
	-- SA-MP Dialog ID больше не используется для CEF-мониторинга.
	local cleanText  = srv(text  or ""):gsub("{.-}", "")
	local cleanTitle = srv(title or ""):gsub("{.-}", "")
	if cleanText:find(t("недостаточно денег")) or cleanText:find(t("Недостаточно денег")) then
		house_purchase_failed = true
	end
	if json.auth.enabled and json.auth.password ~= "" then
		local tl = cleanTitle:lower()
		if tl:find(t("авториз")) or tl:find("authoriz")
		   or tl:find(t("вход")) or tl:find("login")
		   or tl:find(t("пароль")) then
			sampSendDialogResponse(dialogId, 1, -1, json.auth.password)
			showPopup("Авто-вход: пароль отправлен", "+", imgui.ImVec4(0.35, 0.85, 0.55, 1.0))
			return false
		end
	end
end

function events.onSetPlayerPos(position)
	if lovlya.house_wh and house.wh.state ~= 1 then
		house.wh.state = 1; house.wh.number = 0
		house.wh.pickups = {}; house.wh.sale = {}; house.wh.check = 6
		lua_thread.create(function()
			wait(0)
			if (math.abs(position.x - 2326.8332519531) < 0.001 and math.abs(position.y - -2456.1984863281) < 0.001 and math.abs(position.z - 1009.4453125) < 0.001)
			or (math.abs(position.x - 3025.4777832031) < 0.001 and math.abs(position.y - 1700.8305664063) < 0.001 and math.abs(position.z - 997.52502441406) < 0.001) then
				house.wh.state = 2
				json.stats.houses_total = (json.stats.houses_total or 0) + 1; saveJson()
				local x, y, z = getCharCoordinates(PLAYER_PED)
				local count = pickup_pool.m_nCount
				local i = ffi.C.MAX_PICKUPS - 1
				while count > 0 and i >= 0 do
					if pickup_pool.m_nId[i] ~= -1 then
						if pickup_pool.m_object[i].m_nModel == 19198
						and getDistanceBetweenCoords2d(x, y, pickup_pool.m_object[i].m_position.x, pickup_pool.m_object[i].m_position.y) < 15
						and math.abs(pickup_pool.m_object[i].m_position.z - z) < 5 then
							house.wh.number = house.wh.number + 1
							house.wh.pickups[house.wh.number] = i
							house.wh.sales[house.wh.number] = nil
						end
						count = count - 1
					end
					i = i - 1
				end
				while house.wh.state == 2 or house.wh.state == 3 do
					local clock = os.clock() + 0.35
					while clock > os.clock() and (house.wh.state == 2 or house.wh.state == 3) and house.wh.check ~= 0 do wait(0) end
					if house.wh.check == 0 then house.wh.state = 0 end
					if (house.wh.state == 2 or house.wh.state == 3) and house.wh.check ~= 0 then
						house.wh.state = 3; house.wh.check = house.wh.check - 1
						x, y, z = getCharCoordinates(PLAYER_PED)
						local qX = pickup_pool.m_object[house.wh.pickups[house.wh.number]].m_position.x
						local qY = pickup_pool.m_object[house.wh.pickups[house.wh.number]].m_position.y
						local qZ = pickup_pool.m_object[house.wh.pickups[house.wh.number]].m_position.z
						local dist = getDistanceBetweenCoords3d(x, y, z, qX, qY, qZ)
						sendOnfoot(x, y, z)
						for i2 = 0, dist, DATA_GAP do sendOnfoot(x + (qX - x) * i2 / dist, y + (qY - y) * i2 / dist, z + (qZ - z) * i2 / dist) end
						sampSendPickedUpPickup(house.wh.pickups[house.wh.number])
						sendOnfoot(qX, qY, qZ)
						for i2 = math.floor(dist / DATA_GAP) * DATA_GAP, 0, -DATA_GAP do sendOnfoot(x + (qX - x) * i2 / dist, y + (qY - y) * i2 / dist, z + (qZ - z) * i2 / dist) end
						sendOnfoot(x, y, z)
					end
				end
			else
				house.wh.state = 0
			end
		end)
	end
end

function events.onSendPickedUpPickup(id)
	if lovlya.house_wh and (house.wh.state == 2 or house.wh.state == 3) then return false end
end

function events.onCreatePickup(id, model, pickupType, position)
	if house.active and position then
		local x, y, z = getCharCoordinates(PLAYER_PED)
		if getDistanceBetweenCoords3d(x, y, z, position.x, position.y, position.z) < 3 then
			sampSendPickedUpPickup(id)
			local data = allocateMemory(68)
			sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)
			setStructElement(data, 4, 2, bit.band(getStructElement(data, 4, 2, true), bit.bnot(1024)), true)
			sampSendOnfootData(data); freeMemory(data)
			data = allocateMemory(68)
			sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)
			setStructElement(data, 4, 2, bit.bor(getStructElement(data, 4, 2, true), 1024), true)
			sampSendOnfootData(data); freeMemory(data)
			sendOnDialogResponse(1)
			house.active = false
		end
	end
end

function events.onDestroyPickup(id)
	if lovlya.house_wh then
		for _, v in ipairs(house.wh.pickups) do
			if id == v then house.wh.state = 0 end
		end
	end
	if house.active and house.pickup == id then
		local data = allocateMemory(68)
		sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)
		setStructElement(data, 4, 2, bit.band(getStructElement(data, 4, 2, true), bit.bnot(1024)), true)
		sampSendOnfootData(data); freeMemory(data)
		data = allocateMemory(68)
		sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)
		setStructElement(data, 4, 2, bit.bor(getStructElement(data, 4, 2, true), 1024), true)
		sampSendOnfootData(data); freeMemory(data)
		sendOnDialogResponse(1)
	end
end

function events.onSendPlayerSync(data)
	if house.active and bit.band(data.keysData, 1024) == 1024 then return false end
	if block_player_sync then return false end
end

function events.onSendVehicleSync(data)
	if block_vehicle_sync then return false end
end

function onSendPacket(id, bs, priority, reliability, orderingChannel)
	if not antish.enabled then return end
	local text = bitStreamStructure(bs)
	if not text or text == "" then return end

	if text:find("OnPlayerDeviceLost", 1, true) then
		return false
	end

	if isCharInAnyCar(PLAYER_PED) and
	   (text:find("OnPlayerEnterArea", 1, true) or text:find("OnPlayerLeaveArea", 1, true)) then
		return false
	end
end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
	if id == 25 and tg.connected and json.telegram.enabled and json.telegram.notify_enter then
		tg.connected = false
		tg.send('Зашёл на сервер: '..sampGetCurrentServerName())
	end
end

function onReceivePacket(id, bs)
	-- Radmir CRMP CEF: мониторим оба используемых формата.
	if id == 215 then
		readCefPacket215(bs)
		-- CEF-монитор читает bitstream, поэтому возвращаем указатель
		-- в начало, чтобы штатная логика авторизации/систем Radmir
		-- продолжила работать как раньше.
		raknetBitStreamResetReadPointer(bs)
	elseif id == 220 then
		readCefPacket220(bs)
	end

	if (id == 32 or id == 33 or id == 36 or id == 37) and not tg.connected and json.telegram.enabled and json.telegram.notify_enter then
		tg.connected = true
		tg.send('Отключён от сервера.')
	end
	if id == 215 then
		raknetBitStreamIgnoreBits(bs, 8)
		local bt = raknetBitStreamReadInt16(bs)
		if bt == 2 then
			raknetBitStreamReadInt32(bs)
			local count = raknetBitStreamReadInt8(bs)
			local texts = {}
			for i = 1, count do
				texts[i] = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
			end
			if texts[1] == 'Authorization' and texts[2] then
				local data = decodeJson(texts[2])
				if json.auth.enabled and json.auth.login ~= ""
				   and data[2] and data[2]:lower() == json.auth.login:lower() then
					local bs2 = raknetNewBitStream()
					raknetBitStreamWriteInt8(bs2, 215); raknetBitStreamWriteInt16(bs2, 2); raknetBitStreamWriteInt32(bs2, 0)
					raknetBitStreamWriteInt32(bs2, #'OnAuthorizationStart'); raknetBitStreamWriteString(bs2, 'OnAuthorizationStart')
					raknetBitStreamWriteInt32(bs2, 2); raknetBitStreamWriteInt8(bs2, 115)
					local str = t(json.auth.password or '')
					raknetBitStreamWriteInt32(bs2, #str); raknetBitStreamWriteString(bs2, str)
					raknetSendBitStream(bs2); raknetDeleteBitStream(bs2)
				end
			end
			if lovlya.house_wh and house.wh.state == 3 and texts[1] == 'Appartament' then
				house.wh.sales[house.wh.number] = decodeJson(texts[2])[3] == u8:decode('Государство')
				house.wh.number = house.wh.number - 1
				if house.wh.number == 0 then house.wh.state = 4 end
				return false
			end
		end
	end
end

function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		if json.telegram.enabled and json.telegram.notify_enter then
			tg.send('Скрипт выгружен.')
		end
	end
end

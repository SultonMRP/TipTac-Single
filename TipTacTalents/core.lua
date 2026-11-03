local gtt = GameTooltip;
local GetTalentTabInfo = GetTalentTabInfo;

-- Locals
local ttt = CreateFrame("Frame","TipTacTalents");
local cache = {};
local current = {};
local TALENTS_PREFIX = TALENTS..":|cffffffff ";
local ILVL_PREFIX = "Item Level:|cffffffff ";
local PARAGON_PREFIX = "Paragon:|cffcf5fe0 ";
local ILVL_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 };
local CACHE_SIZE = 25;		-- Change cache size here (Default 25)
local paragonCache = {};	-- [lowercase name] = level, from SWParagonOf
local SetOrAddLine;

-- Allow these to be accessed through other addons
ttt.cache = cache;
ttt.current = current;

-- Read a TipTac setting, falling back to the standalone default
local function Cfg(key, default)
	if (TipTac_Config) then
		return TipTac_Config[key];
	end
	return default;
end

local function ShowTalentsEnabled()
	return (Cfg("showTalents",true) ~= false);
end

local function ShowItemLevelEnabled()
	return (Cfg("showPlayerItemLevel",true) ~= false);
end

local function HasAethroParagon()
	return (IsAddOnLoaded("AethroParagon"));
end

local function HasSingleWoWParagon()
	return (IsAddOnLoaded("SingleWoWParagon"));
end

local function HasParagonAddon()
	return HasAethroParagon() or HasSingleWoWParagon();
end

-- Tip line only if a paragon addon is loaded. SingleWoWParagon already writes
-- "Paragon 9" itself, so we do not add a second line on that client.
local function ShowParagonEnabled()
	return HasParagonAddon() and (Cfg("showParagonLevel",true) ~= false) and (not HasSingleWoWParagon());
end

local function NormName(name)
	if (not name) or (name == "") then
		return;
	end
	return string.lower(name);
end

local function CacheParagonUnit(unit, level)
	level = tonumber(level);
	if (not level) or (level < 0) or (not unit) then
		return;
	end
	local guid = UnitGUID(unit);
	local name = UnitName(unit);
	if (guid) then
		paragonCache[guid] = level;
	end
	if (name) then
		paragonCache[NormName(name)] = level;
	end
	return level;
end

local function GetCachedParagon(unit)
	if (not unit) or (not HasAethroParagon()) then
		return;
	end
	if (UnitIsUnit(unit,"player")) and (ParagonCharacterLevel) and (ParagonCharacterLevel.Text) then
		return CacheParagonUnit("player",ParagonCharacterLevel.Text:GetText());
	end
	if (UnitIsUnit(unit,"target")) and (ParagonTargetLevel) and (ParagonTargetLevel.Text) then
		if (ParagonTargetLevel.lastTargetGUID == UnitGUID(unit)) and (ParagonTargetLevel:GetAlpha() > 0) then
			return CacheParagonUnit("target",ParagonTargetLevel.Text:GetText());
		end
	end
	return paragonCache[UnitGUID(unit) or ""] or paragonCache[NormName(UnitName(unit)) or ""];
end

local function ShowParagonOnTip(unit, isUpdate)
	if (not ShowParagonEnabled()) or (not unit) or (not UnitIsPlayer(unit)) then
		return;
	end
	local level = GetCachedParagon(unit);
	if (level ~= nil) then
		SetOrAddLine(PARAGON_PREFIX,level,isUpdate);
		return;
	end
	if (not SendClientRequest) then
		return;
	end
	if (UnitIsUnit(unit,"player")) then
		SetOrAddLine(PARAGON_PREFIX,"...",isUpdate);
		SendClientRequest("ParagonAnniversary",1);
	elseif (UnitIsUnit(unit,"target")) then
		SetOrAddLine(PARAGON_PREFIX,"...",isUpdate);
		SendClientRequest("ParagonAnniversary",6);
	end
end

-- Average equipped item level. Shirt and tabard are ignored. Two-handers count twice with no off-hand.
local function ScanUnitItemLevel(unit)
	if (not unit) then
		return;
	end
	local total, count = 0, 0;
	local mainHandIlvl, mainHandLoc, hasOffHand;
	for i = 1, #ILVL_SLOTS do
		local slot = ILVL_SLOTS[i];
		local link = GetInventoryItemLink(unit,slot);
		if (link) then
			local ilvl, _, _, _, _, loc = select(4,GetItemInfo(link));
			if (ilvl) then
				total = (total + ilvl);
				count = (count + 1);
				if (slot == 16) then
					mainHandIlvl = ilvl;
					mainHandLoc = loc;
				elseif (slot == 17) then
					hasOffHand = true;
				end
			end
		end
	end
	if (mainHandIlvl) and (not hasOffHand) and (mainHandLoc == "INVTYPE_2HWEAPON") then
		total = (total + mainHandIlvl);
		count = (count + 1);
	end
	if (count == 0) then
		return;
	end
	return floor(total / count + 0.5);
end

-- Add a new line, or replace an existing line with the same prefix (used after inspect)
function SetOrAddLine(prefix, value, isInspect)
	local text = prefix..value;
	if (isInspect) then
		if (not gtt:GetUnit()) then
			return;
		end
		for i = 2, gtt:NumLines() do
			local line = _G["GameTooltipTextLeft"..i];
			local lineText = (line:GetText() or "");
			if (lineText:sub(1,#prefix) == prefix) then
				line:SetText(text);
				if (not gtt.fadeOut) then
					gtt:Show();
				end
				return;
			end
		end
		gtt:AddLine(text);
		if (not gtt.fadeOut) then
			gtt:Show();
		end
	else
		gtt:AddLine(text);
	end
end

-- GatherTalents
local function GatherTalents(isInspect, unit)
	-- Inspect functions will always use the active spec when not inspecting
	if (ShowTalentsEnabled()) then
		local group = GetActiveTalentGroup(isInspect);
		-- Get points per tree, and set "maxTree" to the tree with most points
		local maxTree, _ = 1;
		for i = 1, 3 do
			_, _, current[i] = GetTalentTabInfo(i,isInspect,nil,group);
			if (current[i] > current[maxTree]) then
				maxTree = i;
			end
		end
		current.tree = GetTalentTabInfo(maxTree,isInspect,nil,group);
		-- Customise output. Use TipTac setting if it exists, otherwise just use formatting style one.
		local talentFormat = (Cfg("talentFormat",1) or 1);
		if (current[maxTree] == 0) then
			current.format = "No Talents";
		elseif (talentFormat == 1) then
			current.format = current.tree.." ("..current[1].."/"..current[2].."/"..current[3]..")";
		elseif (talentFormat == 2) then
			current.format = current.tree;
		elseif (talentFormat == 3) then
			current.format = current[1].."/"..current[2].."/"..current[3];
		end
		SetOrAddLine(TALENTS_PREFIX,current.format,isInspect);
	end
	-- Item level from the same inspect
	if (ShowItemLevelEnabled()) then
		current.ilvl = ScanUnitItemLevel(unit);
		if (current.ilvl) then
			SetOrAddLine(ILVL_PREFIX,current.ilvl,isInspect);
		end
	end
	-- Organise Cache
	local cacheSize = (Cfg("talentCacheSize",CACHE_SIZE) or CACHE_SIZE);
	for i = #cache, 1, -1 do
		if (current.name == cache[i].name) then
			tremove(cache,i);
			break;
		end
	end
	if (#cache > cacheSize) then
		tremove(cache,1);
	end
	-- Cache the new entry
	if (cacheSize > 0) then
		cache[#cache + 1] = CopyTable(current);
	end
end

-- OnEvent
ttt:SetScript("OnEvent",function(self,event)
	self:UnregisterEvent("INSPECT_TALENT_READY");
	local name, unit = gtt:GetUnit();
	if (name == current.name) then
		GatherTalents(1,unit or current.unit);
	end
end);

-- HOOK: OnTooltipSetUnit
gtt:HookScript("OnTooltipSetUnit",function(self,...)
	-- Get the unit -- Check the UnitFrame unit if this tip is from a concated unit, such as "targettarget".
	local _, unit = self:GetUnit();
	if (not unit) then
		local mFocus = GetMouseFocus();
		if (mFocus) and (mFocus.unit) then
			unit = mFocus.unit;
		end
	end
	if (not UnitIsPlayer(unit)) then
		return;
	end
	-- Paragon is independent of inspect range
	ShowParagonOnTip(unit);
	if (not ShowTalentsEnabled()) and (not ShowItemLevelEnabled()) then
		return;
	end
	-- Only for players over level 9 -- Ignore PvP flagged people, unless they are friendly
	if (UnitLevel(unit) > 9 or UnitLevel(unit) == -1) and (CanInspect(unit)) then
		wipe(current);
		current.name = UnitName(unit);
		current.unit = unit;
		-- Player
		if (UnitIsUnit(unit,"player")) then
			GatherTalents(nil,"player");
		-- Others
		else
			local allowInspect = (not InspectFrame or not InspectFrame:IsShown()) and (not Examiner or not Examiner:IsShown());
			if (allowInspect) then
				ttt:RegisterEvent("INSPECT_TALENT_READY");
				NotifyInspect(unit);
			end
			for _, entry in ipairs(cache) do
				if (current.name == entry.name) then
					if (ShowTalentsEnabled()) and (entry.format) then
						self:AddLine(TALENTS_PREFIX..entry.format);
					end
					if (ShowItemLevelEnabled()) and (entry.ilvl) then
						self:AddLine(ILVL_PREFIX..entry.ilvl);
					end
					current.tree = entry.tree;
					current.format = entry.format;
					current.ilvl = entry.ilvl;
					current[1], current[2], current[3] = entry[1], entry[2], entry[3];
					return;
				end
			end
			if (allowInspect) then
				if (ShowTalentsEnabled()) then
					self:AddLine(TALENTS_PREFIX.."Loading...");
				end
				if (ShowItemLevelEnabled()) then
					self:AddLine(ILVL_PREFIX.."Loading...");
				end
			end
		end
	end
end);

local function TipStillShowing(unit)
	local tipName, tipUnit = gtt:GetUnit();
	if (not tipName) then
		return;
	end
	if (tipUnit) and (UnitExists(tipUnit)) and (UnitIsUnit(tipUnit,unit)) then
		return true;
	end
	return (tipName == UnitName(unit));
end

-- AethroParagon only. SingleWoWParagon draws its own tip line.
if (HasAethroParagon()) then
	if (UIParagon_OnClientReceiveLevel) then
		hooksecurefunc("UIParagon_OnClientReceiveLevel",function(_,arg_table)
			local level = CacheParagonUnit("player",arg_table and arg_table[1]);
			if (level ~= nil) and (TipStillShowing("player")) then
				SetOrAddLine(PARAGON_PREFIX,level,true);
			end
		end);
	end
	if (UIParagon_OnReceiveTargetLevel) then
		hooksecurefunc("UIParagon_OnReceiveTargetLevel",function(_,arg_table)
			local level = CacheParagonUnit("target",arg_table and arg_table[1]);
			if (level ~= nil) and (TipStillShowing("target")) then
				SetOrAddLine(PARAGON_PREFIX,level,true);
			end
		end);
	end
end


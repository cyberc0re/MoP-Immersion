local _, L = ...
local Inspector = ImmersionFrame.Inspector

RAID_CLASS_COLORS.HUNTER.colorStr = "ffabd473"
RAID_CLASS_COLORS.WARLOCK.colorStr = "ff8788ee"
RAID_CLASS_COLORS.PRIEST.colorStr = "ffffffff"
RAID_CLASS_COLORS.PALADIN.colorStr = "fff58cba"
RAID_CLASS_COLORS.MAGE.colorStr = "ff3fc7eb"
RAID_CLASS_COLORS.ROGUE.colorStr = "fffff569"
RAID_CLASS_COLORS.DRUID.colorStr = "ffff7d0a"
RAID_CLASS_COLORS.SHAMAN.colorStr = "ff0070de"
RAID_CLASS_COLORS.WARRIOR.colorStr = "ffc79c6e"
RAID_CLASS_COLORS.DEATHKNIGHT.colorStr = "ffc41f3b"
RAID_CLASS_COLORS.MONK.colorStr = "ff00ff98"

ObjectPoolMixin = {};
 
function ObjectPoolMixin:OnLoad(creationFunc, resetterFunc)
  self.creationFunc = creationFunc;
  self.resetterFunc = resetterFunc;
 
  self.activeObjects = {};
  self.inactiveObjects = {};
 
  self.numActiveObjects = 0;
end
 
function ObjectPoolMixin:Acquire()
  local numInactiveObjects = #self.inactiveObjects;
  if numInactiveObjects > 0 then
    local obj = self.inactiveObjects[numInactiveObjects];
    self.activeObjects[obj] = true;
    self.numActiveObjects = self.numActiveObjects + 1;
    self.inactiveObjects[numInactiveObjects] = nil;
    return obj, false;
  end
 
  local newObj = self.creationFunc(self);
  if self.resetterFunc then
    self.resetterFunc(self, newObj);
  end
  self.activeObjects[newObj] = true;
  self.numActiveObjects = self.numActiveObjects + 1;
  return newObj, true;
end
 
function ObjectPoolMixin:Release(obj)
  self.inactiveObjects[#self.inactiveObjects + 1] = obj;
  self.activeObjects[obj] = nil;
  self.numActiveObjects = self.numActiveObjects - 1;
  if self.resetterFunc then
    self.resetterFunc(self, obj);
  end
end
 
function ObjectPoolMixin:ReleaseAll()
  for obj in pairs(self.activeObjects) do
    self:Release(obj);
  end
end
 
function ObjectPoolMixin:EnumerateActive()
  return pairs(self.activeObjects);
end
 
function ObjectPoolMixin:GetNextActive(current)
  return (next(self.activeObjects, current));
end
 
function ObjectPoolMixin:GetNumActive()
  return self.numActiveObjects;
end
 
function ObjectPoolMixin:EnumerateInactive()
  return ipairs(self.inactiveObjects);
end

function Mixin(object, ...)
  for i = 1, select("#", ...) do
    local mixin = select(i, ...);
    for k, v in pairs(mixin) do
      object[k] = v;
    end
  end
 
  return object;
end
 
FramePoolMixin = Mixin({}, ObjectPoolMixin);
-- where ... are the mixins to mixin
function CreateFromMixins(...)
  return Mixin({}, ...)
end

function CreateFramePool(frameType, parent, frameTemplate, resetterFunc)
  local framePool = CreateFromMixins(FramePoolMixin);
  framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or FramePool_HideAndClearAnchors);
  return framePool;
end

function GetClassColor(classFilename)
	local color = RAID_CLASS_COLORS[classFilename];
	if color then
		return color.r, color.g, color.b, color.colorStr;
	end
	return 1, 1, 1, "ffffffff";
end

-- Synthetic OnLoad
do local self = Inspector
	-- add tables for column frames, used when drawing qItems as tooltips
	self.Choices.Columns = {}
	self.Extras.Columns = {}
	self.Active = {}

	self.parent = self:GetParent()
	self.ignoreRegions = true
	self:EnableMouse(true)

	-- set parent/strata on load main frame keeps table key, strata correctly draws over everything else.
	self:SetParent(UIParent)
	self:SetFrameStrata('FULLSCREEN_DIALOG')

	self.Items = {}
	self:SetScale(1.1)

	local r, g, b = GetClassColor(select(2, UnitClass('player')))
	--self.Background:SetColorTexture(1, 1, 1)
	self.Background:SetGradientAlpha('VERTICAL', 0, 0, 0, 0.75, r / 5, g / 5, b / 5, 0.75)

	self.tooltipFramePool = CreateFramePool('GameTooltip', self, 'ImmersionItemTooltipTemplate', function(self, obj) obj:Hide() end)
	self.tooltipFramePool.creationFunc = function(framePool)
		local index = #framePool.inactiveObjects + framePool.numActiveObjects + 1
		local tooltip = L.Create({
			type    = framePool.frameType,
			name    = 'GameTooltip',
			index   = index,
			parent  = framePool.parent,
			inherit = framePool.frameTemplate
		})
		L.SetBackdrop(tooltip.Hilite, L.Backdrops.GOSSIP_HILITE)
		return tooltip
	end
end

function Inspector:OnShow()
	self.parent.TalkBox:Dim();
	self.tooltipFramePool:ReleaseAll();
end

function Inspector:OnHide()
	self.parent.TalkBox:Undim();
	self.tooltipFramePool:ReleaseAll();
	wipe(self.Active);

	-- Reset columns
	for _, column in ipairs(self.Choices.Columns) do
		column.lastItem = nil
		column:SetSize(1, 1)
		column:Hide()
	end
	for _, column in ipairs(self.Extras.Columns) do
		column.lastItem = nil
		column:SetSize(1, 1)
		column:Hide()
	end
end

Inspector:SetScript('OnShow', Inspector.OnShow)
Inspector:SetScript('OnHide', Inspector.OnHide)
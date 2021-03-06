---------------
--NOTE - Please do not change this section without talking to Dan
local _, tbl = ...;
if tbl then
  tbl.SecureCapsuleGet = SecureCapsuleGet;
 
  local function Import(name)
    tbl[name] = tbl.SecureCapsuleGet(name);
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
 
  function CreateFromMixins(...)
    return Mixin({}, ...)
  end
end
----------------
 
 
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
 
function CreateObjectPool(creationFunc, resetterFunc)
  local objectPool = CreateFromMixins(ObjectPoolMixin);
  objectPool:OnLoad(creationFunc, resetterFunc);
  return objectPool;
end
 
FramePoolMixin = Mixin({}, ObjectPoolMixin);
 
local function FramePoolFactory(framePool)
  return CreateFrame(framePool.frameType, nil, framePool.parent, framePool.frameTemplate);
end
 
function FramePoolMixin:OnLoad(frameType, parent, frameTemplate, resetterFunc)
  ObjectPoolMixin.OnLoad(self, FramePoolFactory, resetterFunc);
  self.frameType = frameType;
  self.parent = parent;
  self.frameTemplate = frameTemplate;
end
 
function FramePool_Hide(framePool, frame)
  frame:Hide();
end
 
function FramePool_HideAndClearAnchors(framePool, frame)
  frame:Hide();
  frame:ClearAllPoints();
end
 
function CreateFramePool(frameType, parent, frameTemplate, resetterFunc)
  local framePool = CreateFromMixins(FramePoolMixin);
  framePool:OnLoad(frameType, parent, frameTemplate, resetterFunc or FramePool_HideAndClearAnchors);
  return framePool;
end
 
TexturePoolMixin = Mixin({}, ObjectPoolMixin);
 
local function TexturePoolFactory(texturePool)
  return texturePool.parent:CreateTexture(nil, texturePool.layer, texturePool.textureTemplate, texturePool.subLayer);
end
 
function TexturePoolMixin:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc)
  ObjectPoolMixin.OnLoad(self, TexturePoolFactory, resetterFunc);
  self.parent = parent;
  self.layer = layer;
  self.subLayer = subLayer;
  self.textureTemplate = textureTemplate;
end
 
TexturePool_Hide = FramePool_Hide;
TexturePool_HideAndClearAnchors = FramePool_HideAndClearAnchors;
 
function CreateTexturePool(parent, layer, subLayer, textureTemplate, resetterFunc)
  local texturePool = CreateFromMixins(TexturePoolMixin);
  texturePool:OnLoad(parent, layer, subLayer, textureTemplate, resetterFunc or TexturePool_HideAndClearAnchors);
  return texturePool;
end
 
FontStringPoolMixin = Mixin({}, ObjectPoolMixin);
 
local function FontStringPoolFactory(fontStringPool)
  return fontStringPool.parent:CreateFontString(nil, fontStringPool.layer, fontStringPool.fontStringTemplate, fontStringPool.subLayer);
end
 
function FontStringPoolMixin:OnLoad(parent, layer, subLayer, fontStringTemplate, resetterFunc)
  ObjectPoolMixin.OnLoad(self, FontStringPoolFactory, resetterFunc);
  self.parent = parent;
  self.layer = layer;
  self.subLayer = subLayer;
  self.fontStringTemplate = fontStringTemplate;
end
 
FontStringPool_Hide = FramePool_Hide;
FontStringPool_HideAndClearAnchors = FramePool_HideAndClearAnchors;
 
function CreateFontStringPool(parent, layer, subLayer, fontStringTemplate, resetterFunc)
  local fontStringPool = CreateFromMixins(FontStringPoolMixin);
  fontStringPool:OnLoad(parent, layer, subLayer, fontStringTemplate, resetterFunc or FontStringPool_HideAndClearAnchors);
  return fontStringPool;
end
 
ActorPoolMixin = Mixin({}, ObjectPoolMixin);
 
local function ActorPoolFactory(actorPool)
  return actorPool.parent:CreateActor(nil, actorPool.actorTemplate);
end
 
function ActorPoolMixin:OnLoad(parent, actorTemplate, resetterFunc)
  ObjectPoolMixin.OnLoad(self, ActorPoolFactory, resetterFunc);
  self.parent = parent;
  self.actorTemplate = actorTemplate;
end
 
ActorPool_Hide = FramePool_Hide;
function ActorPool_HideAndClearModel(actorPool, actor)
  actor:ClearModel();
  actor:Hide();
end
 
function CreateActorPool(parent, actorTemplate, resetterFunc)
  local actorPool = CreateFromMixins(ActorPoolMixin);
  actorPool:OnLoad(parent, actorTemplate, resetterFunc or ActorPool_HideAndClearModel);
  return actorPool;
end

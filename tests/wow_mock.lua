-- A deliberately small API simulator. Not a substitute for an in-client test.
local methods={}
function methods:SetAttribute(name,value) assert(not MOCK.combat);self.attributes=self.attributes or {};self.attributes[name]=value end
function methods:SetParent(parent) self.parent=parent end
MOCK={frames={},clock=100000,combat=false,rest=false,instance="none",zone="Elwynn Forest",group=false,raid=false,guild=false}
local function make(kind,name,parent,template)
    if template then
        local allowed={['SecureActionButtonTemplate,SecureHandlerStateTemplate']=true,BackdropTemplate=true,UICheckButtonTemplate=true,UIPanelButtonTemplate=true,InputBoxTemplate=true,UIPanelCloseButton=true,UIPanelScrollFrameTemplate=true}
        assert(allowed[template],"unexpected frame template "..template)
    end
    local f=setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=true,text="",width=600,height=30,enabled=true},{__index=methods})
    MOCK.frames[#MOCK.frames+1]=f
    if name then _G[name]=f end
    return f
end
function CreateFrame(...) return make(...) end
function methods:CreateFontString(name) return make("FontString",name,self) end
function methods:CreateTexture(name) return make("Texture",name,self) end
function methods:CreateLine(name) return make("Line",name,self) end
function methods:SetStartPoint(...) self.startPoint={...} end
function methods:SetEndPoint(...) self.endPoint={...} end
function methods:SetThickness(v) self.thickness=v end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:SetText(s) assert(type(s)=="string" or type(s)=="number"); self.text=tostring(s); if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end end
function methods:GetText() return self.text end
function methods:GetFontString()
    if not self.fontString then self.fontString=make("FontString",nil,self) end
    self.fontString.text=self.text
    return self.fontString
end
function methods:GetStringHeight() return math.ceil(math.max(1,#self.text)/(self.width/7))*14 end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(e) self.events=self.events or {}; self.events[e]=true end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsShown() return self.shown end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetFocus() self.focus=true end
function methods:ClearFocus() self.focus=false end
function methods:SetScale(s) self.scale=s end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:SetFrameLevel(l) self.level=l end
function methods:GetFrameLevel() return self.level or 1 end
function methods:GetCenter() return 100,100 end
function methods:SetScrollChild(c) self.child=c end
function methods:SetVerticalScroll(n) self.scroll=n end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetParent() return self.parent end
function methods:AddMessage(s) MOCK.notice=s end
for _,method in ipairs({"SetFontObject","SetJustifyH","SetWordWrap","SetTextColor","SetAutoFocus","SetMaxLetters","SetFrameStrata","SetClampedToScreen","SetBackdrop","SetMovable","EnableMouse","RegisterForDrag","StartMoving","StopMovingOrSizing","SetTexture","SetNormalTexture","SetHighlightTexture","RegisterForClicks","SetOwner","AddLine","HighlightText"}) do methods[method]=function() end end
UIParent=make("Frame","UIParent"); UIParent:SetSize(1920,1080)
Minimap=make("Frame","Minimap",UIParent); Minimap:SetSize(140,140)
WorldMapFrame=make("Frame","WorldMapFrame",UIParent)
DEFAULT_CHAT_FRAME=make("Frame","DEFAULT_CHAT_FRAME",UIParent)
DEFAULT_CHAT_FRAME.editBox=make("EditBox",nil,DEFAULT_CHAT_FRAME)
GameTooltip=make("Frame","GameTooltip",UIParent)
UISpecialFrames={}; SlashCmdList={}; SOUNDKIT={IG_MAINMENU_OPEN=1,IG_QUEST_LOG_OPEN=2}
function PlaySound(id) MOCK.sound=id end
function time() return MOCK.clock end
function InCombatLockdown() return MOCK.combat end
function GetRealZoneText() return MOCK.zone end
function IsInInstance() return MOCK.instance~="none",MOCK.instance end
function IsResting() return MOCK.rest end
function IsInGroup(category) if category==2 then return MOCK.instanceGroup or false end return MOCK.group end
function IsInRaid() return MOCK.raid end
function IsInGuild() return MOCK.guild end
function GetBuildInfo() return "1.60.1","70862","Nov 7 2026",16001 end
function GetCursorPosition() return 120,150 end
function issecretvalue(v) return type(v)=="table" and v.secret==true end
ChatFrameUtil={
    ChooseBoxForSend=function() return DEFAULT_CHAT_FRAME.editBox end,
    OpenChat=function(text,frame) assert(frame==DEFAULT_CHAT_FRAME); MOCK.chat=text; DEFAULT_CHAT_FRAME.editBox:SetText(text) end,
}
function SendChatMessage() error("Automatic chat send is forbidden") end
function SendAddonMessage() error("Unexpected addon network traffic") end

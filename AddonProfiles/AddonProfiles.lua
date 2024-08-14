local ADDON_NAME, _ = ...;

local strsplit = strsplit;
local strjoin = strjoin;

local UnitName = UnitName;

local C_AddOns = _G.C_AddOns;
local GetNumAddOns = C_AddOns.GetNumAddOns;
local GetAddOnInfo = C_AddOns.GetAddOnInfo;
local GetAddOnEnableState = C_AddOns.GetAddOnEnableState;
local EnableAddOn = C_AddOns.EnableAddOn;
local DisableAddOn = C_AddOns.DisableAddOn;

--##############################################################################

local profiles;
local events = {};
local eventFrame = CreateFrame('frame');

function events.ADDON_LOADED (addonName)
  if (addonName ~= ADDON_NAME) then return end

  if (type(_G.AddonProfiles_Saved) == 'table') then
    profiles = _G.AddonProfiles_Saved;
  else
    profiles = {};
  end

  events.ADDON_LOADED = nil;
  eventFrame:UnregisterEvent('ADDON_LOADED');
end

function events.PLAYER_LOGOUT ()
  if (profiles == nil) then return end

  _G.AddonProfiles_Saved = profiles;
end

for event in pairs(events) do
  eventFrame:RegisterEvent(event);
end

eventFrame:SetScript('OnEvent', function (self, event, ...)
  events[event](...);
end);

--##############################################################################

local slashCommands = {};

local function executeSlashCommand (command, ...)
  if (not slashCommands[command]) then
    return print(ADDON_NAME .. ': unknown command "' .. command .. '"');
  end

  -- All slash commands use profile names so passing "default" as the profile
  -- name if none was passed prevents code duplication.
  if (... == nil) then
    slashCommands[command]('default');
  else
    slashCommands[command](...);
  end
end

local function slashHandler (input)
  if (input == nil or input == '') then
    return executeSlashCommand('default');
  end

  executeSlashCommand (strsplit(' ', input));
end

_G['SLASH_' .. ADDON_NAME .. '1'] = '/' .. ADDON_NAME;
_G['SLASH_' .. ADDON_NAME .. '2'] = '/ap';
_G.SlashCmdList[ADDON_NAME] = slashHandler;

--##############################################################################

local function getPlayerName ()
  return UnitName('player');
end

local function getAddonEnabledInfo ()
  local playerName = getPlayerName();
  local info = {};

  for x = 1, GetNumAddOns(), 1 do
    info[GetAddOnInfo(x)] = (GetAddOnEnableState(x, playerName) == 2);
  end

  return info;
end

function slashCommands.save (profileName)
  profiles[profileName] = getAddonEnabledInfo();
  print('saved addon profile:', profileName);
end

local function getAddonProfile (profileName)
  local profile = profiles[profileName];

  if (profile == nil) then
    print('addon profile not found:', profileName);
  end

  return profile;
end

local function restoreProfile (profile, characterOrAll)
  for x = 1, GetNumAddOns(), 1 do
    local addonName = GetAddOnInfo(x);

    if (profile[addonName] == true) then
      EnableAddOn(x, characterOrAll);
    else
      DisableAddOn(x, characterOrAll);
    end
  end
end

--[[ This has to return either a character name or nil, as it will be passed
     directly to EnableAddOn ]]
local function parseAllCharactersFlag (allCharacters)
  if (allCharacters == nil) then
    return getPlayerName();
  end

  allCharacters = allCharacters:lower();

  if (allCharacters == 'all' or allCharacters == 'true') then
    return nil;
  end

  return getPlayerName();
end

function slashCommands.load (profileName, allCharacters)
  local profile = getAddonProfile(profileName);

  if (profile ~= nil) then
    restoreProfile(profile, parseAllCharactersFlag(allCharacters));
    print('restored saved addon profile:', profileName);
  end
end

function slashCommands.delete (...)
  local profileName = strjoin(' ', ...);

  if (getAddonProfile(profileName) ~= nil) then
    profiles[profileName] = nil;
    print('deleted profile:', profileName);
  end
end

function slashCommands.default ()
  if (next(profiles) == nil) then
    return print('no addon profiles saved');
  end

  print('available addon profiles:');
  for profileName in pairs(profiles) do
    print(profileName);
  end
end

slashCommands.list = slashCommands.default

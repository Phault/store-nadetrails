#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <store>
#include <smjansson>

enum Trail
{
	String:TrailName[STORE_MAX_NAME_LENGTH],
	String:TrailMaterial[PLATFORM_MAX_PATH],
	Float:TrailLifetime,
	Float:TrailWidth,
	Float:TrailEndWidth,
	TrailFadeLength,
	TrailColor[4],
	TrailModelIndex
}

new OFFSET_THROWER;

new g_trails[1024][Trail];
new g_trailCount;

new String:g_game[32];

new Handle:g_trailsNameIndex = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "[Store] NadeTrails",
	author      = "Phault",
	description = "NadeTrails component for [Store] based upon code from the Trails component by alongub",
	version     = "1.1-alpha",
	url         = ""
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	OFFSET_THROWER  = FindSendPropOffs("CBaseGrenade", "m_hThrower");

	GetGameFolderName(g_game, sizeof(g_game));

	Store_RegisterItemType("nadetrails", OnEquip, LoadItem);
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("nadetrails", OnEquip, LoadItem);
	}	
}

/**
 * Map is starting
 */
public OnMapStart()
{
	for (new item = 0; item < g_trailCount; item++)
	{
		if (strcmp(g_trails[item][TrailMaterial], "") != 0 && (FileExists(g_trails[item][TrailMaterial]) || FileExists(g_trails[item][TrailMaterial], true)))
		{
			decl String:_sBuffer[PLATFORM_MAX_PATH];
			strcopy(_sBuffer, sizeof(_sBuffer), g_trails[item][TrailMaterial]);
			g_trails[item][TrailModelIndex] = PrecacheModel(_sBuffer);
			AddFileToDownloadsTable(_sBuffer);
			ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
			AddFileToDownloadsTable(_sBuffer);
		}
	}
}

public Store_OnReloadItems() 
{
	if (g_trailsNameIndex != INVALID_HANDLE)
		CloseHandle(g_trailsNameIndex);
		
	g_trailsNameIndex = CreateTrie();
	g_trailCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_trails[g_trailCount][TrailName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_trailsNameIndex, g_trails[g_trailCount][TrailName], g_trailCount);
	
	new Handle:json = json_load(attrs);

	if (json == INVALID_HANDLE)
	{
		LogError("%s Error loading item attributes : '%s'.", STORE_PREFIX, itemName);
		return;
	}

	json_object_get_string(json, "material", g_trails[g_trailCount][TrailMaterial], PLATFORM_MAX_PATH);

	g_trails[g_trailCount][TrailLifetime] = json_object_get_float(json, "lifetime"); 
	if (g_trails[g_trailCount][TrailLifetime] == 0.0)
		g_trails[g_trailCount][TrailLifetime] = 1.0;

	g_trails[g_trailCount][TrailWidth] = json_object_get_float(json, "width");

	if (g_trails[g_trailCount][TrailWidth] == 0.0)
		g_trails[g_trailCount][TrailWidth] = 15.0;

	g_trails[g_trailCount][TrailEndWidth] = json_object_get_float(json, "endwidth"); 

	if (g_trails[g_trailCount][TrailEndWidth] == 0.0)
		g_trails[g_trailCount][TrailEndWidth] = 6.0;

	g_trails[g_trailCount][TrailFadeLength] = json_object_get_int(json, "fadelength"); 

	if (g_trails[g_trailCount][TrailFadeLength] == 0)
		g_trails[g_trailCount][TrailFadeLength] = 1;

	new Handle:color = json_object_get(json, "color");

	if (color == INVALID_HANDLE)
	{
		g_trails[g_trailCount][TrailColor] = { 255, 255, 255, 255 };
	}
	else
	{
		for (new i = 0; i < 4; i++)
			g_trails[g_trailCount][TrailColor][i] = json_array_get_int(color, i);

		CloseHandle(color);
	}

	CloseHandle(json);

	if (strcmp(g_trails[g_trailCount][TrailMaterial], "") != 0 && (FileExists(g_trails[g_trailCount][TrailMaterial]) || FileExists(g_trails[g_trailCount][TrailMaterial], true)))
	{
		decl String:_sBuffer[PLATFORM_MAX_PATH];
		strcopy(_sBuffer, sizeof(_sBuffer), g_trails[g_trailCount][TrailMaterial]);
		g_trails[g_trailCount][TrailModelIndex] = PrecacheModel(_sBuffer);
		AddFileToDownloadsTable(_sBuffer);
		ReplaceString(_sBuffer, sizeof(_sBuffer), ".vmt", ".vtf", false);
		AddFileToDownloadsTable(_sBuffer);
	}
	
	g_trailCount++;
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}
	
	decl String:name[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, name, sizeof(name));
	
	decl String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
	Store_GetItemLoadoutSlot(itemId, loadoutSlot, sizeof(loadoutSlot));
	
	if (equipped)
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{
		new trail = -1;
		if (!GetTrieValue(g_trailsNameIndex, name, trail))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}
			
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "_projectile", false) != -1)
	{
		SDKHook(entity, SDKHook_Spawn, Event_OnNadeSpawn);
	}
}

public Event_OnNadeSpawn(entity)
{
	CreateTimer(0.0, nadetimer, entity, TIMER_FLAG_NO_MAPCHANGE); // create a timer that checks the m_hThrower next frame
}

public Action:nadetimer(Handle:timer, any:entity)
{
	new owner = GetEntDataEnt2(entity, OFFSET_THROWER);
     
	if(0 < owner <= MaxClients && IsClientInGame(owner)) // Valid client index 
    {
    	new Handle:pack = CreateDataPack();
    	WritePackCell(pack, owner);
    	WritePackCell(pack, entity);
        Store_GetEquippedItemsByType(Store_GetClientAccountID(owner), "nadetrails", Store_GetClientLoadout(owner), OnGetPlayerNadeTrail, pack);
    } 
	return Plugin_Stop;
}

public OnGetPlayerNadeTrail(ids[], count, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new entity = ReadPackCell(pack);
	CloseHandle(pack);
	
	if (client == 0)
		return;

	for (new index = 0; index < count; index++)
	{
		decl String:itemName[32];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));

		new trail = -1;

		if (!GetTrieValue(g_trailsNameIndex, itemName, trail))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return;
		}

		new color[4];
		Array_Copy(g_trails[trail][TrailColor], color, sizeof(color));
		
		TE_SetupBeamFollow(entity, 
							g_trails[trail][TrailModelIndex], 
							0, 
							g_trails[trail][TrailLifetime], 
							g_trails[trail][TrailWidth], 
							g_trails[trail][TrailEndWidth], 
							g_trails[trail][TrailFadeLength], 
							color);
		TE_SendToAll();
	}
}

/**
 * Copies a 1 dimensional static array.
 *
 * @param array			Static Array to copy from.
 * @param newArray		New Array to copy to.
 * @param size			Size of the array (or number of cells to copy)
 * @noreturn
 */
stock Array_Copy(const any:array[], any:newArray[], size)
{
	for (new i=0; i < size; i++) 
	{
		newArray[i] = array[i];
	}
}
/*  SM Franug Anti Rejoin
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>

#pragma newdecls required 

#define DATA "1.0"

public Plugin myinfo = 
{
	name = "SM Franug Anti Rejoin",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

Handle array_players;

ConVar mp_join_grace_time;

Handle _GraceTimer;

bool _bFirstJoin[MAXPLAYERS + 1], _bGraceRespawn[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateConVar("sm_franug_antirejoin_version", DATA, "Anti-Rejoin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	array_players = CreateArray(64);
	
	HookEvent("round_prestart", Event_Start, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEventEx("player_connect_full", Event_OnFullConnect, EventHookMode_Post )
	
	mp_join_grace_time = FindConVar("mp_join_grace_time");
	
	AddCommandListener(SelectTeam, "jointeam");
	
}

public void Event_OnFullConnect( Handle event, const char[] name, bool dontBroadcast ) {
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	_bFirstJoin[client] = true;
}

public Action SelectTeam(int client, const char[] command, int args)
{
	if(_GraceTimer != null)
		_bGraceRespawn[client] = true;
	else
		_bGraceRespawn[client] = false;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!_bFirstJoin[client])return;
	
	if (!_bGraceRespawn[client])return;
	
	_bGraceRespawn[client] = false;
	char steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	if (FindStringInArray(array_players, steamid) == -1)return;
	
	ForcePlayerSuicide(client);
	//PrintToChatAll(" \x04[Franug-AntiRejoin]\x01 %N matado por intento de rejoin (morir y hacer retry rápido para resucitar)", client);
	
	PrintToChatAll(" \x04[Franug-AntiRejoin]\x01 %N killed for rejoin attempt (dead and do retry for respawn)", client);
	
	
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{	
	char steamid[64];
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	if (FindStringInArray(array_players, steamid) == -1)
		PushArrayString(array_players, steamid);
	
}

public Action Event_Start(Handle event, const char[] name, bool dontBroadcast)
{
	ClearArray(array_players);
	
	for (int i = 1; i <= MaxClients; i++)
	{
			_bFirstJoin[i] = false;
			_bGraceRespawn[i] = false;
	}
	
	if(_GraceTimer != null)
		KillTimer(_GraceTimer);
		
	_GraceTimer = CreateTimer(mp_join_grace_time.FloatValue, Timer_GraceEnd);
}

public Action Timer_GraceEnd(Handle timer)
{
	_GraceTimer = null;
}
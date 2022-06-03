#include <sourcemod>
#include <sdktools>
#include <warmod>

#pragma semicolon 1
#pragma tabsize 0

#define PLUGIN_NAME "WarMod Score"
#define PLUGIN_AUTHOR "phenom"
#define PLUGIN_DESC "Swap score match | WarMod GameTech"
#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_URL "https://vk.com/jquerry"

enum struct Variable {
    int ScoreT;
    int ScoreCT;

    void GetScore(int ScoreT, int ScoreCT)
    {
        this.ScoreT = ScoreT;
        this.ScoreCT = ScoreCT;
    }

    void SummMatch()
    {
        if(this.ScoreCT > this.ScoreT)
        {
            this.ScoreCT = this.ScoreCT + 1;
            this.ScoreT = this.ScoreT - 1;
        }
        else
        {
            this.ScoreCT = this.ScoreCT - 1;
            this.ScoreT = this.ScoreT + 1;
        }
    }
}

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url 		= PLUGIN_URL
}

Variable    g_Variable;
ConVar      tRefreshScore;
ConVar      tRefreshMatch;
bool        g_bMatch = false;
float       g_ftRefreshScore,
            g_ftRefreshMatch;

public void OnPluginStart()
{
    HookEvent("round_end", Event_RoundEnd);

    tRefreshScore = CreateConVar("wm_time_refresh_score", "3.0", "В течении какого времени будет обновление счета. Например: каждые 3 секунды счет будет обнуляться на табло.", _, true, 3.0, true, 10.0);
    tRefreshMatch = CreateConVar("wm_time_refresh_match", "6.0", "Через сколько произойдет запуск второй половины матча. Например: через 6 секунд автоматически запустится вторая половина матча.", _, true, 6.0, true, 60.0);
    AutoExecConfig(true, "warmod_score");
}

public void OnConfigsExecuted()
{
	g_ftRefreshMatch = GetConVarFloat(tRefreshMatch);
    g_ftRefreshScore = GetConVarFloat(tRefreshScore);
}

public OnLiveOn3()
{
    if(g_bMatch == true)
    {
        CreateTimer(g_ftRefreshScore, Timer_SetScore, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        g_Variable.GetScore(0, 0);
        CreateTimer(g_ftRefreshScore, Timer_SetScore, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_SetScore(Handle hTimer)
{
    SetTeamScore(2, g_Variable.ScoreT);
    SetTeamScore(3, g_Variable.ScoreCT);
}

public Action Event_RoundEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
    int Win = hEvent.GetInt("winner");

    if(Win == 2)
    {
        g_Variable.ScoreT = g_Variable.ScoreT + 1;
    }
    else if(Win == 3)
    {
        g_Variable.ScoreCT = g_Variable.ScoreCT + 1;
    }
}

public OnHalfTime()
{
    g_bMatch = true;
    g_Variable.SummMatch();

    int buffer = g_Variable.ScoreT;
    g_Variable.ScoreT = g_Variable.ScoreCT;
    g_Variable.ScoreCT = buffer;

    CreateTimer(g_ftRefreshMatch, Timer_lo3, _, TIMER_REPEAT);
}

public Action Timer_lo3(Handle hTimerLo3)
{
    ServerCommand("lo3");
    KillTimer(hTimerLo3);
}

public void OnMapEnd()
{
    g_Variable.GetScore(0, 0);
}
#ifndef dm_script_h
#define dm_script_h

#include "../sdk.h"

#define DM_LUA_ERROR(fmt, args...) 0
#define DM_LUA_STACK_CHECK(L, diff)

namespace dmScript {
	typedef struct {
		dmBuffer::HBuffer m_Buffer;
		bool m_UseLuaGC;
	} LuaHBuffer;
	LuaHBuffer CheckBuffer(lua_State *L, int index);
	void GetInstance(lua_State *L);
	lua_State *GetMainThread(lua_State *L);
	bool IsBuffer(lua_State *L, int index);
	bool IsInstanceValid(lua_State *L);
	void PushBuffer(lua_State *L, LuaHBuffer buffer);
	int Ref(lua_State *L, int table);
	void SetInstance(lua_State *L);
	void Unref(lua_State *L, int table, int reference);
}

#endif
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/*
 * BEGIN COPY-PASTE FROM Lua 5.1.5 lbaselib.c
 */

static int luaB_newproxy (lua_State *L) {
    lua_settop(L, 1);
    lua_newuserdata(L, 0);  /* create proxy */
    if (lua_toboolean(L, 1) == 0)
        return 1;  /* no metatable */
    else if (lua_isboolean(L, 1)) {
        lua_newtable(L);  /* create a new metatable `m' ... */
        lua_pushvalue(L, -1);  /* ... and mark `m' as a valid metatable */
        lua_pushboolean(L, 1);
        lua_rawset(L, lua_upvalueindex(1));  /* weaktable[m] = true */
    }
    else {
        int validproxy = 0;  /* to check if weaktable[metatable(u)] == true */
        if (lua_getmetatable(L, 1)) {
            lua_rawget(L, lua_upvalueindex(1));
            validproxy = lua_toboolean(L, -1);
            lua_pop(L, 1);  /* remove value */
        }
        luaL_argcheck(L, validproxy, 1, "boolean or proxy expected");
        lua_getmetatable(L, 1);  /* metatable is valid; get it */
    }
    lua_setmetatable(L, 2);
    return 1;
}

/*
 * END COPY-PASTE FROM Lua 5.1.5 lbaselib.c
 */

int luaopen_nucleo_newproxy (lua_State *L) {
    lua_pushcclosure(L, luaB_newproxy, 1);
    return 1;
}

/*
* luainternals.h: useful Lua implementation details for lua-nucleo library
* Code quoted from MIT-licensed Lua 5.1.4 internals
* See copyright notice in lua.h
*/

#ifndef LUANUCLEO_LUAINTERNALS_H_
#define LUANUCLEO_LUAINTERNALS_H_

/*
* BEGIN COPY-PASTE FROM Lua 5.1.4 luaconf.h
* MODIFIED: Added preprocessor conditionals
* WARNING: If your Lua config differs, fix this!
*/

#ifndef luai_numeq
  #define luai_numeq(a,b)		((a)==(b))
#endif /* luai_numeq */

#ifndef luai_numisnan
  #define luai_numisnan(a)	(!luai_numeq((a), (a)))
#endif /* luai_numisnan */

/*
* END COPY-PASTE FROM Lua 5.1.4 luaconf.h
*/

/*
* BEGIN COPY-PASTE FROM Lua 5.1.4 lobject.h
* MODIFIED: Added preprocessor conditional.
* MODIFIED: Renamed from luaO_log2 to avoid name collision:
*           it is not static in Lua.
*/

int luanucleoO_log2 (unsigned int x);

#ifndef ceillog2
  #define ceillog2(x)       (luanucleoO_log2((x)-1) + 1)
#endif /* ceillog2 */

/*
* END COPY-PASTE FROM Lua 5.1.4 lobject.h
*/

/*
* BEGIN COPY-PASTE FROM Lua 5.1.4 ltable.c
* MODIFIED: Added preprocessor conditionals
*/

/*
** max size of array part is 2^MAXBITS
*/

#ifndef MAXBITS
  #if LUAI_BITSINT > 26
  #define MAXBITS		26
  #else
  #define MAXBITS		(LUAI_BITSINT-2)
  #endif
#endif /* MAXBITS */

#ifndef MAXASIZE
  #define MAXASIZE	(1 << MAXBITS)
#endif

/*
* END COPY-PASTE FROM Lua 5.1.4 ltable.c
*/

/*
 * BEGIN COPY-PASTE FROM Lua 5.1.4 lbaselib.c
 */

int luaB_tostring (lua_State *L);

/*
 * END COPY-PASTE FROM Lua 5.1.4 lbaselib.c
 */

/*
 * BEGIN COPY-PASTE FROM Lua 5.1.4 ldblib.c
 * debug.traceback() implementation for pcall()'s error handler
 */

int db_errorfb (lua_State * L);

/*
 * END COPY-PASTE FROM Lua 5.1.4 ldblib.c
 */

#endif /* LUANUCLEO_LUAINTERNALS_H_ */

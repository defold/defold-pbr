#ifndef dm_sdk_h
#define dm_sdk_h

#define LUA_COMPAT_MODULE 1

#ifdef __OBJC__
	#import <Foundation/Foundation.h>
	#import <UIKit/UIKit.h>
#endif

#ifdef DM_PLATFORM_ANDROID
	#include <EGL/egl.h>
	#include <EGL/eglext.h>
#endif

#include <lua/lua.h>
#include <lua/lauxlib.h>

#include <dmsdk/dlib/buffer.h>
#include <dmsdk/dlib/hash.h>
#include <dmsdk/dlib/log.h>
#include <dmsdk/script/script.h>

#define luaL_reg luaL_Reg

#define DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final) ;

namespace dmExtension {
	typedef int Result;
	const int RESULT_OK = 1;
	typedef struct {
		lua_State *m_L;
	} Params;
	typedef struct {
		lua_State *m_L;
	} AppParams;
};

namespace dmGraphics {
	#ifdef __OBJC__
		UIWindow *GetNativeiOSUIWindow();
		UIView *GetNativeiOSUIView();
	#endif
	#ifdef DM_PLATFORM_ANDROID
		EGLSurface GetNativeAndroidEGLSurface();
		jobject GetNativeAndroidActivity();
		JavaVM* GetNativeAndroidJavaVM();
	#endif
}

#endif

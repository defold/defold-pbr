#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <dmsdk/sdk.h>
#include <stb_image.h>
#include <queue>

#define THREAD_IMPLEMENTATION
#include <thread.h>

#include "extension.h"

struct Task {
	int script_instance;
	int ref;
	int listener;
	int width;
	int height;
	int channels;
	int desired_channels;
	dmBuffer::HBuffer buffer;
};

static std::queue<Task *> tasks;

struct ThreadParams {
	int script_instance;
	const char *contents;
	size_t content_length;
	const char *filename;
	int ref;
	int listener;
	int desired_channels;
	bool info;
	bool no_vertical_flip;
};

// Perfom actual image loading.
static void load_image(const char *contents, size_t content_length, const char *filename, int *width, int *height, int *channels, int desired_channels, bool info, bool no_vertical_flip, dmBuffer::HBuffer *buffer) {

	bool is_file = false;
	if (contents == NULL) {
		FILE *f = fopen(filename, "rb");
		if (f != NULL) {
			is_file = true;
			fseek(f, 0L, SEEK_END);
			content_length = ftell(f);
			rewind(f);
			contents = new char[content_length];
			fread((void *)contents, content_length, 1, f);
			fclose(f);
		}
	}

	if (info) {
		stbi_info_from_memory((stbi_uc *)contents, content_length, width, height, channels);
		if (is_file) {
			delete []contents;
		}
	} else {
		stbi_set_flip_vertically_on_load(!no_vertical_flip);
		// stbi_uc *pixels = stbi_load_from_memory((stbi_uc *)contents, content_length, width, height, channels, desired_channels);

		float* pixels = stbi_loadf_from_memory((const stbi_uc *)contents, content_length, width, height, channels, desired_channels);

		if (is_file) {
			delete []contents;
		}
		else
		{
			printf("Not file %d, %d\n", *width, *height);
		}

		if (desired_channels == 0) {
			desired_channels = *channels;
		}

		dmBuffer::StreamDeclaration streams_declaration[] = {
			{dmHashString64("pixels"), dmBuffer::VALUE_TYPE_FLOAT32, (uint8_t)desired_channels}
		};
		dmBuffer::Result result = dmBuffer::Create(*width * *height, streams_declaration, 1, buffer);
		if (result == dmBuffer::RESULT_OK) {
			uint8_t *data = NULL;
			uint32_t data_size = 0;
			dmBuffer::GetBytes(*buffer, (void **)&data, &data_size);
			memcpy(data, pixels, data_size);
			stbi_image_free(pixels);

			if (dmBuffer::ValidateBuffer(*buffer) != dmBuffer::RESULT_OK) {
				dmBuffer::Destroy(*buffer);
				*buffer = 0;
			}
		} else {
			printf("Not ok!\n");
			*buffer = 0;
		}
	}
}

// Push loaded data as a Lua table onto the stack.
static void push_image_resource(lua_State *L, int width, int height, int channels, int desired_channels, dmBuffer::HBuffer buffer) {
	// Image resource.
	lua_newtable(L);

	// Image resource -> Header.
	lua_newtable(L);

	lua_pushnumber(L, width);
	lua_setfield(L, -2, "width");

	lua_pushnumber(L, height);
	lua_setfield(L, -2, "height");

	lua_pushnumber(L, channels);
	lua_setfield(L, -2, "channels");

	lua_pushnumber(L, 1);
	lua_setfield(L, -2, "num_mip_maps");

	lua_getglobal(L, "resource");
	lua_getfield(L, -1, "TEXTURE_TYPE_2D");
	lua_setfield(L, -3, "type");

	if (desired_channels == 0) {
		desired_channels = channels;
	}
	switch (desired_channels) {
		case 1:
			lua_getfield(L, -1, "TEXTURE_FORMAT_LUMINANCE");
			break;
		case 3:
			lua_getfield(L, -1, "TEXTURE_FORMAT_RGB");
			break;
		case 4:
			lua_getfield(L, -1, "TEXTURE_FORMAT_RGBA");
			break;
		default:
			lua_pushnil(L);
	}
	lua_setfield(L, -3, "format");

	lua_pop(L, 1); // resource

	lua_setfield(L, -2, "header");

	if (buffer != 0) {
		dmScript::LuaHBuffer lua_buffer(buffer, dmScript::OWNER_LUA);
		dmScript::PushBuffer(L, lua_buffer);
		lua_setfield(L, -2, "buffer");
	}
}

// Thread function for async loading.
static int loading_thread_proc(void *user_data) {
	ThreadParams *params = (ThreadParams *)user_data;
	Task *task = new Task();
	task->script_instance = params->script_instance;
	task->ref = params->ref;
	task->listener = params->listener;
	task->width = 0;
	task->height = 0;
	task->channels = 0;
	task->desired_channels = params->desired_channels;
	task->buffer = 0;

	load_image(params->contents, params->content_length, params->filename, &task->width, &task->height, &task->channels, params->desired_channels, params->info, params->no_vertical_flip, &task->buffer);
	delete params;

	tasks.push(task);
	return 0;
}

static int extension_load(lua_State *L) {
	printf("Calling load\n");
	
	DM_LUA_STACK_CHECK(L, 1);
	int params_index = 1;
	if (!lua_istable(L, params_index)) {
		return DM_LUA_ERROR("The argument must be params table.");
	}
	const char *contents = NULL;
	size_t content_length = 0;
	const char *filename = NULL;
	int ref = LUA_REFNIL; // Save contents or filename Lua string ref, so it doesn't get garbage collected.
	lua_getfield(L, params_index, "data");
	if (lua_isstring(L, -1)) {
		contents = lua_tolstring(L, -1, &content_length);
		ref = dmScript::Ref(L, LUA_REGISTRYINDEX);
	} else {
		lua_pop(L, 1);
	}
	bool is_file = false;
	if (contents == NULL) {
		lua_getfield(L, params_index, "filename");
		if (lua_isstring(L, -1)) {
			filename = lua_tostring(L, -1);
			ref = dmScript::Ref(L, LUA_REGISTRYINDEX);
		} else {
			lua_pop(L, 1);
			return DM_LUA_ERROR("Either data param or filename param must be set.");
		}
	}

	int desired_channels = 0;
	lua_getfield(L, params_index, "channels");
	if (lua_isnumber(L, -1)) {
		desired_channels = lua_tonumber(L, -1);
		if (desired_channels != 1 && desired_channels != 3 && desired_channels != 4) {
			desired_channels = 0;
		}
	}
	lua_pop(L, 1);

	bool info = false;
	lua_getfield(L, params_index, "info");
	if (lua_isboolean(L, -1)) {
		info = lua_toboolean(L, -1);
	}
	lua_pop(L, 1);

	bool no_vertical_flip = false;
	lua_getfield(L, params_index, "no_vertical_flip");
	if (lua_isboolean(L, -1)) {
		no_vertical_flip = lua_toboolean(L, -1);
	}
	lua_pop(L, 1);

	bool no_async = false;
	lua_getfield(L, params_index, "no_async");
	if (lua_isboolean(L, -1)) {
		no_async = lua_toboolean(L, -1);
	}
	lua_pop(L, 1);

	#ifdef DM_PLATFORM_HTML5
		no_async = true; // No threading on HTML5.
	#endif

	int listener = LUA_REFNIL;
	lua_getfield(L, params_index, "listener");
	if (lua_isfunction(L, -1)) {
		listener = dmScript::Ref(L, LUA_REGISTRYINDEX);
	} else {
		lua_pop(L, 1);
	}
	bool has_listener = listener != LUA_REFNIL && listener != LUA_NOREF;

	if (has_listener && !no_async) {
		dmScript::GetInstance(L);
		ThreadParams *params = new ThreadParams();
		params->script_instance = dmScript::Ref(L, LUA_REGISTRYINDEX);
		params->contents = contents;
		params->content_length = content_length;
		params->filename = filename;
		params->ref = ref;
		params->listener = listener;
		params->desired_channels = desired_channels;
		params->info = info;
		params->no_vertical_flip = no_vertical_flip;
		thread_create(loading_thread_proc, (void *)params, "imageloader_thread", THREAD_STACK_SIZE_DEFAULT);
		lua_pushnil(L);
	} else {
		printf("Sync\n");
		dmScript::Unref(L, LUA_REGISTRYINDEX, ref);
		int width = 0;
		int height = 0;
		int channels = 0;
		dmBuffer::HBuffer buffer = 0;
		load_image(contents, content_length, filename, &width, &height, &channels, desired_channels, info, no_vertical_flip, &buffer);

		if (has_listener) {
			lua_rawgeti(L, LUA_REGISTRYINDEX, listener);
			dmScript::Unref(L, LUA_REGISTRYINDEX, listener);

			dmScript::GetInstance(L);
		}
		push_image_resource(L, width, height, channels, desired_channels, buffer);
		if (has_listener) {
			lua_call(L, 2, 0);
			lua_pushnil(L);
		}
	}
	return 1;
}

static int extension_debug_set_vertical_flip(lua_State *L) {
	if (lua_isboolean(L, 1)) {
		stbi_set_flip_vertically_on_load(lua_toboolean(L, 1));
	}
	return 0;
}

dmExtension::Result APP_INITIALIZE(dmExtension::AppParams *params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result APP_FINALIZE(dmExtension::AppParams *params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result INITIALIZE(dmExtension::Params *params) {
	lua_State *L = params->m_L;
	const luaL_Reg lua_functions[] = {
		{"load", extension_load},
		{"debug_set_vertical_flip", extension_debug_set_vertical_flip},
		{NULL, NULL}
	};

	luaL_openlib(L, EXTENSION_NAME_STRING, lua_functions, 1);

	return dmExtension::RESULT_OK;
}

dmExtension::Result UPDATE(dmExtension::Params *params) {
	while (!tasks.empty()) {
			Task *task = tasks.front();
			tasks.pop();
			if (task->listener != LUA_REFNIL && task->listener != LUA_NOREF) {
				lua_State *L = params->m_L;
				dmScript::Unref(L, LUA_REGISTRYINDEX, task->ref); // Release contents or filename string.

				lua_rawgeti(L, LUA_REGISTRYINDEX, task->listener); // Push and release callback function.
				dmScript::Unref(L, LUA_REGISTRYINDEX, task->listener);

				lua_rawgeti(L, LUA_REGISTRYINDEX, task->script_instance); // Push and release `self` script instance.
				dmScript::Unref(L, LUA_REGISTRYINDEX, task->script_instance);
				lua_pushvalue(L, -1);
				dmScript::SetInstance(L);

				push_image_resource(L, task->width, task->height, task->channels, task->desired_channels, task->buffer);

				lua_call(L, 2, 0); // Make the call.
			}
			delete task;
		}
	return dmExtension::RESULT_OK;
}

dmExtension::Result FINALIZE(dmExtension::Params *params) {
	return dmExtension::RESULT_OK;
}

DECLARE_DEFOLD_EXTENSION

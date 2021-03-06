﻿/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 Richard Andrew Cattermole
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module skeleton.syntax.luasyn;
import skeleton.providers.defs;
import skeleton.syntax.defs;
import luad.all;
import std.string : toLower;

enum confirmLineForLuaSyn = "-- Lua skeleton descriptor";

private {
	bool success;
}

class LuaSyn : ISyntax {

	bool canHandle(string text){
		success = true;

		static void picnic(LuaState state, in char[] text) {
			success = false;
		}

		if (text.length <= confirmLineForLuaSyn.length || text[0 .. confirmLineForLuaSyn.length].toLower != confirmLineForLuaSyn.toLower)
			return false;

		auto lua = new LuaState;
		lua.openLibs();
		lua.configureLuaWithDependencies();

		lua.setPanicHandler(&picnic);

		lua.loadString(text);

		return success;
	}

	void handleMainFile(IProvider provider, string text, ProgramArgs args) {
		import ofile = std.file;

		static void picnic(LuaState state, in char[] text) {
			assert(0, text);
		}

		string resetToCWD = ofile.getcwd;
		if (args.projectdir !is null) {
			if (!ofile.exists(args.projectdir))
				ofile.mkdirRecurse(args.projectdir);
			ofile.chdir(args.projectdir);
		}
		scope(exit)ofile.chdir(resetToCWD);
		
		auto lua = new LuaState;
		lua.openLibs();
		lua.configureLuaWithDependencies();
		
		lua.setPanicHandler(&picnic);

		lua["programArguments"] = args;
		lua.doString(text);
	}
}

static this() {
	registerSyntax(new LuaSyn);
}

void configureLuaWithDependencies(LuaState state) {
	LuaObject loadRepoFile(string moduleName) {
		string got = cast(string)luaDownloadRepoFile(moduleName);

		if (got is null && moduleName.length > 4 && moduleName[0 .. 4] == "http")
			got = cast(string)downloadFile(moduleName, null);

		if (got !is null) {
			state["my_searcher_obj"] = got;
			state.doString("package.preload['" ~ moduleName ~ "'] = loadstring(my_searcher_obj)");
			state["my_searcher_obj"] = nil;
			return state.doString("return package.preload['" ~ moduleName ~ "']()")[0];
		}

		return state.wrap("Not able to load " ~ moduleName ~ ", apropriete repository file doesn't exist");
	}
	state["my_searcher"] = &loadRepoFile;
	state.doString("table.insert(package.loaders, 1, my_searcher)");

	LuaObject loadDownloadRepoFile(string repo) {
		ubyte[] got = luaDownloadRepoFile(repo);
		if (got !is null)
			return state.wrap(got);
		else
			return state.wrap("Not able to load " ~ repo ~ ", apropriete repository file doesn't exist");
	}
	state["downloadRepoFile"] = &loadDownloadRepoFile;

	LuaObject loadDownloadFile(string url) {
		ubyte[] got = downloadFile(url, null);
		if (got !is null)
			return state.wrap(got);
		else
			return state.wrap("Not able to download " ~ url);
	}
	state["downloadFile"] = &loadDownloadFile;

	LuaTable table;

	table = state.newTable();
	import stdio = std.stdio;
	foreach(symbol; __traits(allMembers, stdio)) {
		static if (symbol != "testFilename" && __traits(compiles, {state[symbol] = mixin("&stdio." ~ symbol);})) {
			table[symbol] = mixin("&stdio." ~ symbol);
		}
	}
	state["stdio"] = table;

	table = state.newTable();
	import stdfile = std.file;
	foreach(symbol; __traits(allMembers, stdfile)) {
		static if (symbol != "dirEntry" && symbol != "timeLastModified" && __traits(compiles, {state[symbol] = mixin("&stdfile." ~ symbol);})) {
			table[symbol] = mixin("&stdfile." ~ symbol);
		}
	}
	state["file"] = table;
}

ubyte[] luaDownloadRepoFile(string repo) {
	import devisualization.util.core.text : split;

	string[] spaces = repo.split(" ");
	if (spaces.length != 2)
		return null;

	IProvider provider = providerForRepo(spaces[0]);
	if (provider is null)
		return null;
	
	return provider.downloadRepoFile(spaces[0], spaces[1]);
}
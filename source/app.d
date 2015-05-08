/*
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
import std.stdio;
import vibe.core.args;
import vibe.core.log;
import skeleton.syntax.defs;
import skeleton.providers.defs;
import std.process : environment, execute;
import std.file : getcwd, chdir;

void main(string[] args) {
	version(Windows) {
		if (environment.get("PWD", "") != "") {
			// most likely e.g. cygwin *grumble*
			auto value = execute(["cygpath", "-w", environment.get("PWD", "")]);
			if (value.output[$-1] == '\n')
				value.output.length--;
			chdir(environment.get("CD", value.output));
		} else {
			chdir(environment.get("CD", getcwd()));
		}
	} else {
		chdir(environment.get("PWD", environment.get("CD", getcwd())));
	}

	ProgramArgs config;

	getOption("path", &config.projectdir, "Current working directory to use.");

	finalizeCommandLineOptions(&config.args);

	if (config.args.length == 1) {
		logError("Must include the skeleton identifier\n$ dub run skeleton -- <project>@<user>[#<branch>][/<path>] [<args>..]");
		return;
	} else if (config.args.length > 1) {
		config.repo = config.args[1];
		config.args = config.args[2 .. $];
	}


	auto provider = providerForRepo(config.repo);
	if (provider is null) {
		logError("Cannot find a provider for repo %s", config.repo);
		return;
	}

	string mainFile = provider.mainFile(config.repo);
	auto pSyntax = syntaxHandlerForRepo(provider, mainFile);

	if (pSyntax is null) {
		logError("Cannot find a syntax provider for the given input");
		return;
	}

	pSyntax.handleMainFile(provider, mainFile, config);
}
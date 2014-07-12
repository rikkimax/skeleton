import std.stdio;
import vibe.core.args;
import vibe.core.log;
import skeleton.syntax.defs;
import skeleton.providers.defs;

void main(string[] args) {
	ProgramArgs config;

	getOption("path", &config.projectdir, "Current working directory to use.");

	finalizeCommandLineOptions(&config.args);

	if (config.args.length == 1) {
		logError("Must include the skeleton identifier\n$ dub run skeleton <project>@<user>[#<branch>][/<path>] [<args>..]");
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
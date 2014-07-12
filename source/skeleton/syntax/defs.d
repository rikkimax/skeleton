module skeleton.syntax.defs;
import skeleton.providers.defs;

interface ISyntax {
	bool canHandle(string text);
	void handleMainFile(IProvider provider, string text, ProgramArgs args);
}

struct ProgramArgs {
	string[] args;
	string projectdir;
	string repo;
}

private {
	ISyntax[] sProviders;
}

void registerSyntax(ISyntax sProvider) {
	sProviders ~= sProvider;
}

ISyntax syntaxHandlerForRepo(IProvider provider, string text) {
	foreach(sp; sProviders) {
		if (sp.canHandle(text)) {
			return sp;
		}
	}

	return null;
}
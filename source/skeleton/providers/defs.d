module skeleton.providers.defs;

interface IProvider {
	bool canUse(string repo);
	string mainFile(string repo);

	ubyte[] downloadRepoFile(string repo, string file);
	bool hasFile(string repo, string file);
}

ubyte[] downloadFile(string url, string file) {
	import vibe.stream.operations;
	import vibe.inet.urltransfer;

	ubyte[] ret = null;
	try {
		if (file !is null) {
			if (url[$-1] == '/')
				url ~= file;
			else
				url ~= "/" ~ file;
		}

		if (url !is null) {
			download(url, (scope res){
				ret = res.readAll();
			});
		}
	} catch(Exception e) {
	}
	return ret;
}

private {
	IProvider[] providers;
}

void registerProvider(IProvider provider) {
	providers ~= provider;
}

IProvider providerForRepo(string repo) {
	foreach(provider; providers) {
		if (provider.canUse(repo))
			return provider;
	}

	return null;
}
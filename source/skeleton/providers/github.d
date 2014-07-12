module skeleton.providers.github;
import skeleton.providers.defs;

class GithubProvider : IProvider {
	bool canUse(string repo) {
		return mainFile(repo) !is null;
	}

	string mainFile(string repo) {
		string temp;

		temp = cast(string)downloadRepoFile(repo, "skeleton.txt");
		if (temp !is null)
			return temp;

		if (encodeGithubGistURL(repo, null) !is null) {
			temp = cast(string)downloadFile(encodeGithubGistURL(repo, null), null);
			if (temp !is null)
				return temp;
		}

		// other formats here

		return null;
	}

	ubyte[] downloadRepoFile(string repo, string file) {
		ubyte[] temp;

		if (encodeGithubURL(repo) !is null) {
			temp = downloadFile(encodeGithubURL(repo), file);
			if (temp !is null)
				return temp;
		}

		if (encodeGithubGistURL(repo, file) !is null) {
			temp = downloadFile(encodeGithubGistURL(repo, file), null);
			if (temp !is null)
				return temp;
		}

		// other formats here

		return null;
	}

	bool hasFile(string repo, string file) {
		return downloadFile(repo, file) !is null;
	}
}

protected {
	import skeleton.util : split;

	pure string encodeGithubURL(string text) {
		string[] temp;

		string repo;
		string user;
		string branch;

		temp = split(text, "@");
		if (temp.length != 2)
			return null;
		repo = temp[0];

		temp = split(temp[1], "#");
		if (temp.length == 2) {
			user = temp[0];
			string temp2 = temp[1];
			temp = temp[1].split("/");
			branch = temp[0];
			temp[0] = temp2[branch.length + 1 .. $];
		} else if (temp.length == 1) {
			string temp2 = temp[0];
			temp = temp[0].split("/");
			user = temp[0];

			if (temp2.length <= user.length)
				return null;

			temp[0] = temp2[user.length + 1 .. $];
		} else
			return null;

		return "https://raw.github.com/" ~ user ~ "/" ~ repo ~ "/" ~ (branch !is null ? branch ~ "/" : "") ~ temp[0];
	}

	unittest {
		assert(encodeGithubURL("skeleton@rikkimax#master/examples/basic") == "https://raw.github.com/rikkimax/skeleton/master/examples/basic");
		assert(encodeGithubURL("skeleton@rikkimax/examples/basic") == "https://raw.github.com/rikkimax/skeleton/examples/basic");
	}

	pure string encodeGithubGistURL(string text, string useFile) {
		string[] temp;
		
		string gist;
		string user;
		string file;
		
		temp = split(text, "@");
		if (temp.length != 2)
			return null;
		gist = temp[0];

		user = temp[1].split("/")[0];

		if (temp[1].length > user.length && useFile is null)
			file = temp[1][user.length + 1 .. $];
		else if (useFile !is null)
			file = useFile;

		return "https://gist.githubusercontent.com/" ~ user ~ "/" ~ gist ~ "/raw/" ~ file; 
	}
	
	unittest {
		assert(encodeGithubGistURL("zadm521@rikkimax/skeleton.txt", null) == "https://gist.githubusercontent.com/rikkimax/zadm521/raw/skeleton.txt");
		assert(encodeGithubGistURL("zadm521@rikkimax", null) == "https://gist.githubusercontent.com/rikkimax/zadm521/raw/");
		assert(encodeGithubGistURL("zadm521@rikkimax", "test.txt") == "https://gist.githubusercontent.com/rikkimax/zadm521/raw/test.txt");
	}
}

static this() {
	registerProvider(new GithubProvider);
}
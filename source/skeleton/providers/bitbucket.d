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
module skeleton.providers.bitbucket;
import skeleton.providers.defs;

class BitbucketProvider : IProvider {
	bool canUse(string repo) {
		return mainFile(repo) !is null;
	}

	string mainFile(string repo) {
		string temp;

		temp = cast(string)downloadRepoFile(repo, "skeleton.txt");
		if (temp !is null)
			return temp;

		// other formats here

		return null;
	}

	ubyte[] downloadRepoFile(string repo, string file) {
		ubyte[] temp;

		if (encodeBitbucketURL(repo, false) !is null) {
			temp = downloadFile(encodeBitbucketURL(repo), file);
			if (temp !is null)
				return temp;
		}

		if (encodeBitbucketURL(repo, true) !is null) {
			temp = downloadFile(encodeBitbucketURL(repo, true), file);
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

	pure string encodeBitbucketURL(string text, bool isGit=false) {
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

			if (isGit)
				branch = "master";
			else
				branch = "tip";
		} else
			return null;

		return "https://bitbucket.org/" ~ user ~ "/" ~ repo ~ "/raw/" ~ branch ~ "/" ~ temp[0];
	}

	unittest {
		assert(encodeBitbucketURL("skeleton@rikkimax#master/examples/basic") == "https://bitbucket.org/rikkimax/skeleton/raw/master/examples/basic");
		assert(encodeBitbucketURL("skeleton@rikkimax/examples/basic") == "https://bitbucket.org/rikkimax/skeleton/raw/tip/examples/basic");
		assert(encodeBitbucketURL("skeleton@rikkimax/examples/basic", true) == "https://bitbucket.org/rikkimax/skeleton/raw/master/examples/basic");
	}
}

static this() {
	registerProvider(new BitbucketProvider);
}
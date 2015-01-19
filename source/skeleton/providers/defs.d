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
module skeleton.providers.defs;

/**
 * Generic interface to a provider of files
 */
interface IProvider {

	/**
	 * Does this repository location specified can be used by this provider?
	 * 
	 * Params:
	 * 		repo	=	Repository location
	 * 
	 * Returns:
	 * 		Can this repository be used by this provider
	 */
	bool canUse(string repo);

	/**
	 * Get the text of the main file for a skeleton project
	 * 
	 * Params:
	 * 		repo	=	Repository location
	 * 
	 * Returns:
	 * 		The repository main file text
	 */
	string mainFile(string repo);

	/**
	 * Downloads a given file from a repository
	 * 
	 * Params:
	 * 		repo	=	Repository location
	 * 		file	=	File to download
	 * 
	 * Returns:
	 * 		The file contents if it exists
	 */
	ubyte[] downloadRepoFile(string repo, string file);

	/**
	 * Checks if a file exists in the given repository
	 * 
	 * Params:
	 * 		repo	=	Repository location
	 * 		file	=	File to download
	 * 
	 * Returns:
	 * 		If the file exists
	 */
	bool hasFile(string repo, string file);
}

/**
 * Downloads a file over http
 * 
 * Params:
 * 		url		=	The url directory to download from
 * 		file	=	The file to download
 * 
 * Returns:
 * 		The file that is downloaded contents, otherwise null
 */
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

private __gshared {
	IProvider[] providers;
}

/**
 * Registers a provider to query for file downloads
 * 
 * Params:
 * 		provider	=	The provider to be registered
 */
void registerProvider(IProvider provider) {
	providers ~= provider;
}


/**
 * Gets a provider based upon the repository name
 * 
 * Params:
 * 		repo	=	Repository location
 * 
 * Returns:
 * 		The provider for location or null
 */
IProvider providerForRepo(string repo) {
	foreach(provider; providers) {
		if (provider.canUse(repo))
			return provider;
	}

	return null;
}
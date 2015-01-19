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
module skeleton.syntax.defs;
import skeleton.providers.defs;

/**
 * Syntax handler of a main file for Skeleton generation
 */
interface ISyntax {

	/**
	 * Given a file content, deteremine if this syntax handler can handle it
	 * 
	 * Params:
	 * 		text	=	Text of the main file
	 * 
	 * Returns:
	 * 		Can this syntax handler handle the text
	 */
	bool canHandle(string text);

	/**
	 * Executes the syntax for a given file and argument
	 * 
	 * Params:
	 * 		provider	=	The provider to get files from if needed
	 * 		text		=	Text of the main file
	 * 		args		=	Arguments to configure the syntax handler
	 */
	void handleMainFile(IProvider provider, string text, ProgramArgs args);
}

/**
 * Arguments for the syntax handler during execution
 */
struct ProgramArgs {

	/**
	 * Arguments to pass into the syntax handling mechanism
	 */
	string[] args;

	/**
	 * Change to directory
	 */
	string projectdir;

	/**
	 * The repository url
	 */
	string repo;
}

private __gshared {
	ISyntax[] sProviders;
}

/**
 * Registers a syntax handler
 * 
 * Params:
 * 		sProvider	=	The provider to register
 */
void registerSyntax(ISyntax sProvider) {
	sProviders ~= sProvider;
}

/**
 * Gets a syntax handler given a provider and file text.
 * 
 * Params:
 * 		provider	=	The provider of files to get from
 * 		text		=	Text of the main file
 * 
 * Returns:
 * 		The syntax provider or null if the main file cannot be handled
 */
ISyntax syntaxHandlerForRepo(IProvider provider, string text) {
	foreach(sp; sProviders) {
		if (sp.canHandle(text)) {
			return sp;
		}
	}

	return null;
}
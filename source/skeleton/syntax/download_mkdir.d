module skeleton.syntax.download_mkdir;
import skeleton.providers.defs;
import skeleton.syntax.defs;
import std.functional : memoize;
import std.string : indexOf;

enum confirmLineForDownloadMkdir = "# Simple skeleton descriptor";

class DownloadMkDir : ISyntax {
	bool canHandle(string text) {
		bool ret;
		parseFileDownloadMkdir(text, ret);
		return ret;
	}

	void handleMainFile(IProvider provider, string text, ProgramArgs args) {
		import skeleton.util : replace;
		import vibe.d : logError, logDiagnostic;
		import std.conv : to;
		import ofile = std.file;

		if (args.projectdir !is null) {
			if (!ofile.exists(args.projectdir))
				ofile.mkdirRecurse(args.projectdir);
			ofile.chdir(args.projectdir);
		}

		foreach(i, string arg; args.args) {
			text = text.replace("$" ~ to!string(i), arg);
		}

		bool successful;
		CmdOpDownloadMkdir[] ops = parseFileDownloadMkdir(text, successful);

		assert(successful);

		foreach(op; ops) {
			if (op.dlfile !is null) {
				if (op.dlfile.length > 4 && op.dlfile[0 .. 4] == "http") {
					// download file via http
					import vibe.d : download;
					download(op.dlfile, op.path);
					logDiagnostic("Downloading file %s to %s.", op.dlfile, op.path);
				} else if (op.dlfile.indexOf("@")) {
					// its a repo, go searching for it in providers
					IProvider provider2 = providerForRepo(op.dlfile);
					if (provider2 !is null) {
						ofile.write(op.path, provider2.downloadRepoFile(op.dlfile, null));
						logDiagnostic("Downloading file %s to %s.", op.dlfile, op.path);
					} else {
						logError("Could not download file %s. No provider exists to download from.", op.dlfile);
					}
				} else {
					ofile.write(op.path, provider.downloadRepoFile(args.repo, op.dlfile));
					logDiagnostic("Downloading file %s from repository %s to %s.", op.dlfile, args.repo, op.path);
				}
			} else if (op.regex !is null) {
				import std.regex : regex, replaceAll;
				string fdata = cast(string)ofile.read(op.path);

				// regex search replace
				auto reg = regex(op.regex);

				fdata = replaceAll(fdata, reg, op.replaceRegex);
				ofile.write(op.path, fdata);
			} else {
				if (op.deleteNotCreateDir && ofile.exists(op.path)) {
					ofile.rmdirRecurse(op.path);
					logDiagnostic("Deleting directory %s.", op.path);
				} else {
					ofile.mkdirRecurse(op.path);
					logDiagnostic("Creating directory %s.", op.path);
				}
			}
		}
	}
}


class CmdOpDownloadMkdir {
	string path;

	string dlfile;
	string regex;
	string replaceRegex;

	bool deleteNotCreateDir;
}

CmdOpDownloadMkdir[] parseFileDownloadMkdir(string text, out bool successful) {
	import skeleton.util;
	import vibe.textfilter.urlencode;
	import std.string : toLower, strip, splitLines;

	bool isRegex;

	CmdOpDownloadMkdir current = new CmdOpDownloadMkdir;
	CmdOpDownloadMkdir[] ret;

	if (text.length <= confirmLineForDownloadMkdir.length || text[0 .. confirmLineForDownloadMkdir.length].toLower != confirmLineForDownloadMkdir.toLower) {
		successful = false;
		return null;
	}

	foreach(string line; text.splitLines) {
		line = line.strip();

		if (line.length > 1)
			if (line[0] == '#')
				continue;
		if (line.length == 0)
			continue;


		if (isRegex) {
			if (current.regex is null)
				current.regex = line;
			else {
				current.replaceRegex = urlDecode(line);
				ret ~= current;
				current = new CmdOpDownloadMkdir;
				isRegex = false;
			}

			continue;
		}

		string[] words = line.split(" ");

		if (words.length == 1) {
			current.path = urlDecode(words[0]);
			ret ~= current;
			current = new CmdOpDownloadMkdir;
		} else if (words.length == 2) {
			switch(words[0].toLower) {
				case "regex":
					current.path = urlDecode(words[1]);
					isRegex = true;
					break;
				case "mkdir":
					current.path = urlDecode(words[1]);
					ret ~= current;
					current = new CmdOpDownloadMkdir;
					break;
				case "rmdir":
					current.path = urlDecode(words[1]);
					current.deleteNotCreateDir = true;
					ret ~= current;
					current = new CmdOpDownloadMkdir;
					break;
				default:
					current.path = urlDecode(words[0]);
					current.dlfile = urlDecode(words[1]);
					ret ~= current;
					current = new CmdOpDownloadMkdir;
					break;
			}
		} else if (words.length == 3) {
			if (words[0].toLower == "dlfile") {
				current.path = urlDecode(words[1]);
				current.dlfile = urlDecode(words[2]);
				ret ~= current;
				current = new CmdOpDownloadMkdir;
			}
		} else {
			successful = false;
			return null;
		}
	}

	successful = true;
	return ret;
}

unittest {
	bool successful;
	CmdOpDownloadMkdir[] ops = parseFileDownloadMkdir("""# Simple skeleton descriptor
#comment
# comment 2
dir_here/
mkdir dir_here2
regex package.json
    $NAME
    $0
mkdir dir3%20/docs
mynewfile relpath
dlfile myfile repo@user/somedir/somefile.d
rmdir byebye
filo repo@user/somedir/filo2
""", successful);

	assert(successful);
	assert(ops.length == 8);
	assert(ops[0].path == "dir_here/");
	assert(!ops[0].deleteNotCreateDir);
												
	assert(ops[1].path == "dir_here2");
	assert(!ops[1].deleteNotCreateDir);
												
	assert(ops[2].path == "package.json");
	assert(ops[2].regex == "$NAME");
	assert(ops[2].replaceRegex == "$0");

	assert(ops[3].path == "dir3 /docs");

	assert(ops[4].path == "mynewfile");
	assert(ops[4].dlfile == "relpath");

	assert(ops[5].path == "myfile");
	assert(ops[5].dlfile == "repo@user/somedir/somefile.d");
		
	assert(ops[6].path == "byebye");
	assert(ops[6].deleteNotCreateDir);
		
	assert(ops[7].path == "filo");
	assert(ops[7].dlfile == "repo@user/somedir/filo2");
}

static this() {
	registerSyntax(new DownloadMkDir);
}
import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;

public function main(string path, string moduleName, string repoName, string moduleVersion, string balVersion = "2201.8.0") returns error? {

    log:printInfo("Generating connector with the following metadata:");
    log:printInfo("Module Name: " + moduleName);
    log:printInfo("Repository Name: " + repoName);
    log:printInfo("Module Version: " + moduleVersion);
    log:printInfo("Ballerina Version: " + balVersion);

    // Read placeholder values from a config file or environment variables
    map<string> placeholders = {
        "MODULE_NAME": moduleName[0].toUpperAscii() + moduleName.substring(1),
        "module_name": moduleName[0].toLowerAscii() + moduleName.substring(1),
        "REPO_NAME": regexp:split(re `/`, repoName)[1],
        "MODULE_VERSION": moduleVersion,
        "BAL_VERSION": balVersion
    };

    // Recursively process all files in the target directory
    check processDirectory(path, placeholders);
}

function processDirectory(string dir, map<string> placeholders) returns error? {
    file:MetaData[] files = check file:readDir(dir);

    foreach file:MetaData file in files {
        if (file.dir) {
            check processDirectory(file.absPath, placeholders);
        } else {
            check processFile(file.absPath, placeholders);
        }
    }
}

function processFile(string filePath, map<string> placeholders) returns error? {
    string content = check io:fileReadString(filePath);
    foreach var [placeholder, value] in placeholders.entries() {
        content = re `\{\{${placeholder}\}\}`.replaceAll(content, value);
    }

    check io:fileWriteString(filePath, content);
}

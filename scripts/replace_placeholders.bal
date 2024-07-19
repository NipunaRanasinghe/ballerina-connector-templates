import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;

public type TemplateFileExt ".bal"|".md"|".json"|".yaml"|".yml"|".toml"|".gradle"|".properties";

public function main(string path, string moduleName, string repoName, string moduleVersion, string balVersion) returns error? {

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
    string[] nameParts = regexp:split(re `\.`, filePath);
    string ext = nameParts[nameParts.length() - 1];
    if ext !is TemplateFileExt {
        log:printInfo("Skipping file: " + filePath);
        return;
    }

    string|error content = check io:fileReadString(filePath);
    if content is error {
        return error("Error reading file at " + filePath + ":" + content.message());
    }

    string strContent = content;
    foreach var [placeholder, value] in placeholders.entries() {
        strContent = re `\{\{${placeholder}\}\}`.replaceAll(strContent, value);
    }

    check io:fileWriteString(filePath, strContent);
}

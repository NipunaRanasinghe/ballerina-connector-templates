import ballerina/file;
import ballerina/io;
import ballerina/lang.regexp;
import ballerina/log;

// Define the file extensions that are considered as template files
public type TemplateFileExt "bal"|"md"|"json"|"yaml"|"yml"|"toml"|"gradle"|"properties";

public function main(string path, string moduleName, string repoName, string moduleVersion, string balVersion) returns error? {
    log:printInfo("Generating connector template with the following metadata:");
    log:printInfo("Module Name: " + moduleName);
    log:printInfo("Repository Name: " + repoName);
    log:printInfo("Module Version: " + moduleVersion);
    log:printInfo("Ballerina Version: " + balVersion);

    [regexp:RegExp, string][] placeholders = [
        [re `\{\{MODULE_NAME_PC\}\}`, moduleName[0].toUpperAscii() + moduleName.substring(1)],
        [re `\{\{MODULE_NAME_CC\}\}`, moduleName[0].toLowerAscii() + moduleName.substring(1)],
        [re `\{\{REPO_NAME\}\}`, regexp:split(re `/`, repoName)[1]],
        [re `\{\{MODULE_VERSION\}\}`, moduleVersion],
        [re `\{\{BAL_VERSION\}\}`, balVersion]
    ];

    // Recursively process all files in the target directory
    check processDirectory(path, placeholders);
}

function processDirectory(string dir, [regexp:RegExp, string][] placeholders) returns error? {
    file:MetaData[] files = check file:readDir(dir);
    foreach file:MetaData file in files {
        if file.dir {
            check processDirectory(file.absPath, placeholders);
        } else {
            check processFile(file.absPath, placeholders);
        }
    }
}

function processFile(string filePath, [regexp:RegExp, string][] placeholders) returns error? {
    string ext = getExtension(filePath);
    if ext !is TemplateFileExt {
        log:printInfo("Skipping file: " + filePath);
        return;
    }

    string|error readResult = check io:fileReadString(filePath);
    if readResult is error {
        return error("Error reading file at " + filePath + ":" + readResult.message());
    }

    string content = readResult;
    foreach [regexp:RegExp, string] [placeholder, value] in placeholders {
        content = placeholder.replaceAll(content, value);
    }

    check io:fileWriteString(filePath, content);
}

function getExtension(string filePath) returns string {
    string[] nameParts = regexp:split(re `\.`, filePath);
    return nameParts[nameParts.length() - 1];
}
